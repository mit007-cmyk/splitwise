import '../../../../core/errors/result.dart';
import '../entities/expense.dart';

abstract class ExpenseRepository {
  Future<Result<void>> createExpense(Expense expense);

  /// All expenses recorded under a single group, newest first.
  Future<Result<List<Expense>>> getGroupExpenses(String groupId);
}
