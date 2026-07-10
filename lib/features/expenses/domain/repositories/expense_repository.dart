import '../../../../core/errors/result.dart';
import '../entities/expense.dart';

abstract class ExpenseRepository {
  Future<Result<void>> createExpense(Expense expense);

  Future<Result<void>> updateExpense({
    required Expense expense,
    required String actorUserId,
  });

  /// All expenses recorded under a single group, newest first.
  Future<Result<List<Expense>>> getGroupExpenses(String groupId);

  Future<Result<Expense?>> getExpenseById(String expenseId);

  /// Permanently deletes a single expense by [expenseId].
  Future<Result<void>> deleteExpense({
    required String expenseId,
    required String actorUserId,
  });

  Future<Result<void>> restoreExpense({
    required String expenseId,
    required String actorUserId,
  });
}
