import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/firestore_service.dart';
import '../models/expense_model.dart';

abstract class ExpenseRemoteDataSource {
  /// Creates/updates one entry under `Splitwise/expenses.{expenseId}`.
  Future<void> createExpense({
    required String groupId,
    required String expenseId,
    required Map<String, dynamic> data,
  });

  /// Reads every expense for [groupId], newest first.
  ///
  /// Primary source is `Splitwise/expenses`. Falls back to nested
  /// `Splitwise/groups.{groupId}.expenses` for older group data.
  Future<List<ExpenseModel>> getGroupExpenses(String groupId);

  /// Reads one expense by id from `Splitwise/expenses`.
  Future<ExpenseModel?> getExpenseById(String expenseId);

  /// Updates an expense atomically with audit fields.
  Future<void> updateExpense({
    required String expenseId,
    required Map<String, dynamic> data,
    required String actorUserId,
  });

  /// Soft-deletes a single expense atomically with audit fields.
  Future<void> deleteExpense({
    required String expenseId,
    required String actorUserId,
  });

  Future<void> restoreExpense({
    required String expenseId,
    required String actorUserId,
  });
}

@LazySingleton(as: ExpenseRemoteDataSource)
class ExpenseRemoteDataSourceImpl implements ExpenseRemoteDataSource {
  final FirestoreService _firestoreService;
  static const _uuid = Uuid();

  ExpenseRemoteDataSourceImpl(this._firestoreService);

  bool _isDeleted(Map<String, dynamic> map) {
    final deleted = map['isDeleted'] as bool? ?? false;
    return deleted || map['deletedAt'] != null;
  }

  List<String> _visibilityUserIds(Map<String, dynamic> expenseData) {
    if (expenseData['participantIds'] is List) {
      return List<String>.from(expenseData['participantIds'] as List)
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();
    }
    final ids = <String>{
      if (expenseData['paidBy'] is Map)
        ...((expenseData['paidBy'] as Map).keys.map((k) => k.toString())),
      if (expenseData['splits'] is Map)
        ...((expenseData['splits'] as Map).keys.map((k) => k.toString())),
    };
    return ids.map((id) => id.trim()).where((id) => id.isNotEmpty).toList();
  }

  Map<String, dynamic> _expenseMetadata(
    Map<String, dynamic> expenseData, {
    required String expenseId,
    required String actorUserId,
    required String? groupName,
  }) {
    final paidBy = expenseData['paidBy'] is Map
        ? Map<String, dynamic>.from(expenseData['paidBy'] as Map)
        : const <String, dynamic>{};
    final splits = expenseData['splits'] is Map
        ? Map<String, dynamic>.from(expenseData['splits'] as Map)
        : const <String, dynamic>{};
    final paidByActor = (paidBy[actorUserId] as num?)?.toDouble() ?? 0.0;
    final owesActor = (splits[actorUserId] as num?)?.toDouble() ?? 0.0;
    final net = paidByActor - owesActor;
    final netDirection = net > 0.01
        ? 'owed'
        : (net < -0.01 ? 'owe' : 'settled');
    return {
      'title': expenseData['title'],
      'amount': (expenseData['amount'] as num?)?.toDouble() ?? 0.0,
      'currencyCode': expenseData['currencyCode'],
      'currencySymbol': expenseData['currencySymbol'],
      'splitType': expenseData['splitType'],
      'category': expenseData['category'],
      'participants': _visibilityUserIds(expenseData),
      'groupName': groupName,
      'netAmount': net.abs(),
      'netDirection': netDirection,
      'expenseId': expenseId,
    };
  }

  List<String> _changedFields(Map<String, dynamic> before, Map<String, dynamic> after) {
    final changed = <String>[];
    final keys = <String>{...before.keys, ...after.keys};
    for (final key in keys) {
      final b = before[key];
      final a = after[key];
      if (b is Map && a is Map) {
        if (Map<String, dynamic>.from(b).toString() !=
            Map<String, dynamic>.from(a).toString()) {
          changed.add(key);
        }
      } else if (b is List && a is List) {
        if (b.toString() != a.toString()) changed.add(key);
      } else if (b != a) {
        changed.add(key);
      }
    }
    return changed;
  }

  String _groupNameFromDoc(Map<String, dynamic>? groupsData, String groupId) {
    final group = groupsData?[groupId];
    if (group is Map) {
      return (group['name'] as String?) ?? '';
    }
    return '';
  }

  Map<String, dynamic> _buildExpenseEventData({
    required String type,
    required String expenseId,
    required String groupId,
    required String actorUserId,
    required Map<String, dynamic> expenseData,
    required String? groupName,
    Map<String, dynamic>? snapshotBefore,
    required Map<String, dynamic> snapshotAfter,
    List<String>? changedFields,
  }) {
    return {
      'type': type,
      'entityType': 'expense',
      'entityId': expenseId,
      'groupId': groupId,
      'performedBy': actorUserId,
      'performedAt': FieldValue.serverTimestamp(),
      'metadata': _expenseMetadata(
        expenseData,
        expenseId: expenseId,
        actorUserId: actorUserId,
        groupName: groupName,
      ),
      if (snapshotBefore != null) 'snapshotBefore': snapshotBefore,
      'snapshotAfter': snapshotAfter,
      'changedFields': changedFields ?? const <String>[],
      'visibilityUserIds': _visibilityUserIds(expenseData),
    };
  }

  void _appendEvent(
    Transaction transaction,
    DocumentReference<Map<String, dynamic>> eventsRef,
    Map<String, dynamic> eventData,
  ) {
    final eventId = _uuid.v4();
    transaction.set(eventsRef, {eventId: eventData}, SetOptions(merge: true));
  }

  @override
  Future<void> createExpense({
    required String groupId,
    required String expenseId,
    required Map<String, dynamic> data,
  }) async {
    final firestore = _firestoreService.firestore;
    final splitwiseRef = firestore
        .collection(FirestorePaths.root)
        .doc(FirestorePaths.expenses);
    final groupsRef = firestore
        .collection(FirestorePaths.root)
        .doc(FirestorePaths.groups);
    final eventsRef = firestore
        .collection(FirestorePaths.root)
        .doc(FirestorePaths.events);

    await _firestoreService.runTransaction((transaction) async {
      final groupsSnap = await transaction.get(groupsRef);
      final groupsData = groupsSnap.data();
      final groupName = _groupNameFromDoc(groupsData, groupId);

      transaction.set(splitwiseRef, {expenseId: data}, SetOptions(merge: true));
      if (groupId.trim().isNotEmpty) {
        transaction.set(
          groupsRef,
          {'$groupId.expenseIds': FieldValue.arrayUnion([expenseId])},
          SetOptions(merge: true),
        );
      }

      final actorUserId = (data['createdBy'] as String?)?.trim() ?? '';
      _appendEvent(
        transaction,
        eventsRef,
        _buildExpenseEventData(
          type: 'expense_created',
          expenseId: expenseId,
          groupId: groupId,
          actorUserId: actorUserId,
          expenseData: data,
          groupName: groupName,
          snapshotAfter: data,
        ),
      );
    });
  }

  @override
  Future<List<ExpenseModel>> getGroupExpenses(String groupId) async {
    final splitwiseDoc = await _getSplitwiseDocumentGroupExpenses(groupId);
    final nested = await _getLegacyNestedGroupExpenses(groupId);

    if (splitwiseDoc.isEmpty) return nested;
    if (nested.isEmpty) return splitwiseDoc;

    // Splitwise/expenses wins when the same id exists in nested group data.
    final byId = <String, ExpenseModel>{
      for (final expense in nested) expense.id: expense,
      for (final expense in splitwiseDoc) expense.id: expense,
    };
    final merged = byId.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return merged;
  }

  Future<List<ExpenseModel>> _getSplitwiseDocumentGroupExpenses(
    String groupId,
  ) async {
    final doc = await _firestoreService.getDocument(
      FirestorePaths.root,
      FirestorePaths.expenses,
    );
    final raw = doc.data();
    if (raw == null) return [];

    final expenses = <ExpenseModel>[];
    raw.forEach((key, value) {
      if (value is! Map) return;
      final mapped = Map<String, dynamic>.from(value);
      if (_isDeleted(mapped)) return;
      final expenseGroupId = mapped['groupId'] as String?;
      if (expenseGroupId != groupId) return;
      expenses.add(ExpenseModel.fromMap(key, groupId, mapped));
    });
    expenses.sort((a, b) => b.date.compareTo(a.date));
    return expenses;
  }

  Future<List<ExpenseModel>> _getLegacyNestedGroupExpenses(String groupId) async {
    final groupsDoc = await _firestoreService.getDocument(
      FirestorePaths.root,
      FirestorePaths.groups,
    );
    final groupsData = groupsDoc.data();
    if (groupsData == null) return [];

    final groupMap = groupsData[groupId];
    if (groupMap is! Map) return [];

    final expensesMap = groupMap['expenses'];
    if (expensesMap is! Map) return [];

    final expenses = <ExpenseModel>[];
    expensesMap.forEach((key, value) {
      if (value is Map) {
        final mapped = Map<String, dynamic>.from(value);
        if (_isDeleted(mapped)) return;
        expenses.add(
          ExpenseModel.fromMap(
            key as String,
            groupId,
            mapped,
          ),
        );
      }
    });

    expenses.sort((a, b) => b.date.compareTo(a.date));
    return expenses;
  }

  @override
  Future<ExpenseModel?> getExpenseById(String expenseId) async {
    try {
      final splitwiseDoc = await _firestoreService.getDocument(
        FirestorePaths.root,
        FirestorePaths.expenses,
      );
      final splitwiseData = splitwiseDoc.data();
      if (splitwiseData != null) {
        final raw = splitwiseData[expenseId];
        if (raw is Map) {
          final mapped = Map<String, dynamic>.from(raw);
          if (!_isDeleted(mapped)) {
            final groupId = mapped['groupId'] as String? ?? '';
            return ExpenseModel.fromMap(expenseId, groupId, mapped);
          }
        }
      }
    } catch (_) {}

    return null;
  }

  @override
  Future<void> updateExpense({
    required String expenseId,
    required Map<String, dynamic> data,
    required String actorUserId,
  }) async {
    final firestore = _firestoreService.firestore;
    final splitwiseRef = firestore
        .collection(FirestorePaths.root)
        .doc(FirestorePaths.expenses);
    final groupsRef = firestore
        .collection(FirestorePaths.root)
        .doc(FirestorePaths.groups);
    final eventsRef = firestore
        .collection(FirestorePaths.root)
        .doc(FirestorePaths.events);

    await _firestoreService.runTransaction((transaction) async {
      final splitwiseSnap = await transaction.get(splitwiseRef);
      final splitwiseData = splitwiseSnap.data();
      final existingRaw = splitwiseData?[expenseId];

      if (existingRaw is! Map) {
        throw StateError('Expense not found.');
      }
      final existing = Map<String, dynamic>.from(existingRaw);

      if (_isDeleted(existing)) {
        throw StateError('Cannot edit a deleted expense.');
      }
      final createdBy = (existing['createdBy'] as String?)?.trim() ?? '';
      if (createdBy.isNotEmpty && createdBy != actorUserId.trim()) {
        throw StateError('You do not have permission to edit this expense.');
      }

      final merged = <String, dynamic>{
        ...existing,
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': actorUserId,
        'isDeleted': false,
        'deletedAt': FieldValue.delete(),
        'deletedBy': FieldValue.delete(),
      };
      final previousGroupId = (existing['groupId'] as String?)?.trim() ?? '';
      final nextGroupId =
          (merged['groupId'] as String?)?.trim() ?? previousGroupId;
      final groupsSnap = await transaction.get(groupsRef);
      final groupsData = groupsSnap.data();
      final groupName = _groupNameFromDoc(groupsData, nextGroupId);

      transaction.set(splitwiseRef, {expenseId: merged}, SetOptions(merge: true));
      if (previousGroupId.isNotEmpty && previousGroupId != nextGroupId) {
        transaction.set(
          groupsRef,
          {'$previousGroupId.expenseIds': FieldValue.arrayRemove([expenseId])},
          SetOptions(merge: true),
        );
      }
      if (nextGroupId.isNotEmpty) {
        transaction.set(
          groupsRef,
          {'$nextGroupId.expenseIds': FieldValue.arrayUnion([expenseId])},
          SetOptions(merge: true),
        );
      }
      _appendEvent(
        transaction,
        eventsRef,
        _buildExpenseEventData(
          type: 'expense_updated',
          expenseId: expenseId,
          groupId: nextGroupId,
          actorUserId: actorUserId,
          expenseData: merged,
          groupName: groupName,
          snapshotBefore: existing,
          snapshotAfter: merged,
          changedFields: _changedFields(existing, merged),
        ),
      );
    });
  }

  @override
  Future<void> deleteExpense({
    required String expenseId,
    required String actorUserId,
  }) async {
    final firestore = _firestoreService.firestore;
    final splitwiseRef = firestore
        .collection(FirestorePaths.root)
        .doc(FirestorePaths.expenses);
    final groupsRef = firestore
        .collection(FirestorePaths.root)
        .doc(FirestorePaths.groups);
    final eventsRef = firestore
        .collection(FirestorePaths.root)
        .doc(FirestorePaths.events);

    await _firestoreService.runTransaction((transaction) async {
      final splitwiseSnap = await transaction.get(splitwiseRef);
      final splitwiseData = splitwiseSnap.data();
      final existingRaw = splitwiseData?[expenseId];

      if (existingRaw is! Map) {
        throw StateError('Expense not found.');
      }
      final existing = Map<String, dynamic>.from(existingRaw);

      if (_isDeleted(existing)) {
        throw StateError('This expense is already deleted.');
      }
      final createdBy = (existing['createdBy'] as String?)?.trim() ?? '';
      if (createdBy.isNotEmpty && createdBy != actorUserId.trim()) {
        throw StateError('You do not have permission to delete this expense.');
      }

      final deleted = <String, dynamic>{
        ...existing,
        'isDeleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': actorUserId,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': actorUserId,
      };
      final groupId = (existing['groupId'] as String?)?.trim() ?? '';
      final groupsSnap = await transaction.get(groupsRef);
      final groupsData = groupsSnap.data();
      final groupName = _groupNameFromDoc(groupsData, groupId);

      transaction.set(splitwiseRef, {expenseId: deleted}, SetOptions(merge: true));
      if (groupId.isNotEmpty) {
        transaction.set(
          groupsRef,
          {'$groupId.expenseIds': FieldValue.arrayRemove([expenseId])},
          SetOptions(merge: true),
        );
      }
      _appendEvent(
        transaction,
        eventsRef,
        _buildExpenseEventData(
          type: 'expense_deleted',
          expenseId: expenseId,
          groupId: groupId,
          actorUserId: actorUserId,
          expenseData: existing,
          groupName: groupName,
          snapshotBefore: existing,
          snapshotAfter: deleted,
          changedFields: const ['isDeleted', 'deletedAt', 'deletedBy'],
        ),
      );
    });
  }

  @override
  Future<void> restoreExpense({
    required String expenseId,
    required String actorUserId,
  }) async {
    final firestore = _firestoreService.firestore;
    final splitwiseRef = firestore
        .collection(FirestorePaths.root)
        .doc(FirestorePaths.expenses);
    final groupsRef = firestore
        .collection(FirestorePaths.root)
        .doc(FirestorePaths.groups);
    final eventsRef = firestore
        .collection(FirestorePaths.root)
        .doc(FirestorePaths.events);

    await _firestoreService.runTransaction((transaction) async {
      final splitwiseSnap = await transaction.get(splitwiseRef);
      final splitwiseData = splitwiseSnap.data();
      final existingRaw = splitwiseData?[expenseId];

      if (existingRaw is! Map) {
        throw StateError('Expense not found.');
      }
      final existing = Map<String, dynamic>.from(existingRaw);

      if (!_isDeleted(existing)) {
        throw StateError('Expense is not deleted.');
      }
      final createdBy = (existing['createdBy'] as String?)?.trim() ?? '';
      if (createdBy.isNotEmpty && createdBy != actorUserId.trim()) {
        throw StateError('You do not have permission to restore this expense.');
      }

      final restored = <String, dynamic>{
        ...existing,
        'isDeleted': false,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': actorUserId,
        'deletedAt': FieldValue.delete(),
        'deletedBy': FieldValue.delete(),
      };
      final groupId = (restored['groupId'] as String?)?.trim() ?? '';
      final groupsSnap = await transaction.get(groupsRef);
      final groupsData = groupsSnap.data();
      final groupName = _groupNameFromDoc(groupsData, groupId);

      transaction.set(splitwiseRef, {expenseId: restored}, SetOptions(merge: true));
      if (groupId.isNotEmpty) {
        transaction.set(
          groupsRef,
          {'$groupId.expenseIds': FieldValue.arrayUnion([expenseId])},
          SetOptions(merge: true),
        );
      }
      _appendEvent(
        transaction,
        eventsRef,
        _buildExpenseEventData(
          type: 'expense_restored',
          expenseId: expenseId,
          groupId: groupId,
          actorUserId: actorUserId,
          expenseData: restored,
          groupName: groupName,
          snapshotBefore: existing,
          snapshotAfter: restored,
          changedFields: const ['isDeleted', 'deletedAt', 'deletedBy'],
        ),
      );
    });
  }
}

