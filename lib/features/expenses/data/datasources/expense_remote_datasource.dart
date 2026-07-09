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
}

@LazySingleton(as: ExpenseRemoteDataSource)
class ExpenseRemoteDataSourceImpl implements ExpenseRemoteDataSource {
  final FirestoreService _firestoreService;

  ExpenseRemoteDataSourceImpl(this._firestoreService);

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
        expenses.add(
          ExpenseModel.fromMap(
            key as String,
            groupId,
            Map<String, dynamic>.from(value),
          ),
        );
      }
    });

    expenses.sort((a, b) => b.date.compareTo(a.date));
    return expenses;
  }
}
