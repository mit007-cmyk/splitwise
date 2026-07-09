import 'package:injectable/injectable.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/firestore_service.dart';
import '../models/expense_model.dart';

abstract class ExpenseRemoteDataSource {
  /// Merges a new expense into `Splitwise/groups.{groupId}.expenses.{expenseId}`
  /// using a dotted field path so sibling group/expense data is untouched.
  Future<void> createExpense({
    required String groupId,
    required String expenseId,
    required Map<String, dynamic> data,
  });

  /// Reads every expense recorded under `Splitwise/groups.{groupId}.expenses`,
  /// newest first.
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
    return _firestoreService.updateDocument(
      FirestorePaths.root,
      FirestorePaths.groups,
      {
        '$groupId.expenses.$expenseId': data,
      },
    );
  }

  @override
  Future<List<ExpenseModel>> getGroupExpenses(String groupId) async {
    final groupsDoc = await _firestoreService.getDocument(FirestorePaths.root, FirestorePaths.groups);
    final groupsData = groupsDoc.data();
    if (groupsData == null) return [];

    final groupMap = groupsData[groupId];
    if (groupMap is! Map) return [];

    final expensesMap = groupMap['expenses'];
    if (expensesMap is! Map) return [];

    final expenses = <ExpenseModel>[];
    expensesMap.forEach((key, value) {
      if (value is Map) {
        expenses.add(ExpenseModel.fromMap(
          key as String,
          groupId,
          Map<String, dynamic>.from(value),
        ));
      }
    });

    expenses.sort((a, b) => b.date.compareTo(a.date));
    return expenses;
  }
}
