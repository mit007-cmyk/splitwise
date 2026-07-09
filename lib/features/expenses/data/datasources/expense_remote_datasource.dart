import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
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
  /// Primary source is `Splitwise/expenses` (same table style as groups/users).
  /// Falls back to prior storage variants so existing users keep seeing old
  /// data during migration.
  Future<List<ExpenseModel>> getGroupExpenses(String groupId);

  /// Reads one expense by id from supported storage variants.
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
}

@LazySingleton(as: ExpenseRemoteDataSource)
class ExpenseRemoteDataSourceImpl implements ExpenseRemoteDataSource {
  final FirestoreService _firestoreService;

  ExpenseRemoteDataSourceImpl(this._firestoreService);

  bool _isDeleted(Map<String, dynamic> map) {
    final deleted = map['isDeleted'] as bool? ?? false;
    return deleted || map['deletedAt'] != null;
  }

  @override
  Future<void> createExpense({
    required String groupId,
    required String expenseId,
    required Map<String, dynamic> data,
  }) {
    return _firestoreService.setDocument(
      FirestorePaths.root,
      FirestorePaths.expenses,
      {expenseId: data},
      merge: true,
    );
  }

  @override
  Future<List<ExpenseModel>> getGroupExpenses(String groupId) async {
    final splitwiseDoc = await _getSplitwiseDocumentGroupExpenses(groupId);
    final topLevel = await _getTopLevelCollectionGroupExpenses(groupId);
    final legacy = await _getLegacyNestedGroupExpenses(groupId);

    if (splitwiseDoc.isEmpty && topLevel.isEmpty) return legacy;
    if (splitwiseDoc.isEmpty && legacy.isEmpty) return topLevel;
    if (topLevel.isEmpty && legacy.isEmpty) return splitwiseDoc;

    // Merge sources by expense id (newest schema wins on duplicate ids):
    // splitwise doc > top-level collection > legacy nested.
    final byId = <String, ExpenseModel>{
      for (final expense in legacy) expense.id: expense,
      for (final expense in topLevel) expense.id: expense,
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

  Future<List<ExpenseModel>> _getTopLevelCollectionGroupExpenses(
    String groupId,
  ) async {
    final snapshot = await _firestoreService.getCollection(
      FirestorePaths.expenses,
      queryBuilder: (query) => query.where('groupId', isEqualTo: groupId),
    );

    final expenses = <ExpenseModel>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (_isDeleted(data)) continue;
      expenses.add(ExpenseModel.fromMap(doc.id, groupId, data));
    }

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

    try {
      final legacyDoc = await _firestoreService.getDocument(
        FirestorePaths.expenses,
        expenseId,
      );
      final data = legacyDoc.data();
      if (data != null && !_isDeleted(data)) {
        final groupId = data['groupId'] as String? ?? '';
        return ExpenseModel.fromMap(expenseId, groupId, data);
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
    final legacyRef = firestore
        .collection(FirestorePaths.expenses)
        .doc(expenseId);

    await _firestoreService.runTransaction((transaction) async {
      final splitwiseSnap = await transaction.get(splitwiseRef);
      final splitwiseData = splitwiseSnap.data();
      final existingRaw = splitwiseData?[expenseId];

      Map<String, dynamic>? existing;
      if (existingRaw is Map) {
        existing = Map<String, dynamic>.from(existingRaw);
      } else {
        final legacySnap = await transaction.get(legacyRef);
        if (legacySnap.exists && legacySnap.data() != null) {
          existing = Map<String, dynamic>.from(legacySnap.data()!);
        }
      }

      if (existing == null) {
        throw StateError('Expense not found.');
      }
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

      transaction.set(splitwiseRef, {expenseId: merged}, SetOptions(merge: true));
      transaction.set(legacyRef, merged, SetOptions(merge: true));
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
    final legacyRef = firestore
        .collection(FirestorePaths.expenses)
        .doc(expenseId);

    await _firestoreService.runTransaction((transaction) async {
      final splitwiseSnap = await transaction.get(splitwiseRef);
      final splitwiseData = splitwiseSnap.data();
      final existingRaw = splitwiseData?[expenseId];

      Map<String, dynamic>? existing;
      if (existingRaw is Map) {
        existing = Map<String, dynamic>.from(existingRaw);
      } else {
        final legacySnap = await transaction.get(legacyRef);
        if (legacySnap.exists && legacySnap.data() != null) {
          existing = Map<String, dynamic>.from(legacySnap.data()!);
        }
      }

      if (existing == null) {
        throw StateError('Expense not found.');
      }
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

      transaction.set(splitwiseRef, {expenseId: deleted}, SetOptions(merge: true));
      transaction.set(legacyRef, deleted, SetOptions(merge: true));
    });
  }
}

