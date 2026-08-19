import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/result.dart';
import '../../../../shared/repositories/base_repository.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expense_remote_datasource.dart';
import '../models/expense_model.dart';

@LazySingleton(as: ExpenseRepository)
class ExpenseRepositoryImpl extends BaseRepository implements ExpenseRepository {
  final ExpenseRemoteDataSource _remoteDataSource;
  static const _uuid = Uuid();

  ExpenseRepositoryImpl(this._remoteDataSource);

  @override
  Future<Result<void>> createExpense(Expense expense) {
    final model = ExpenseModel.fromEntity(expense);
    final expenseId = expense.id.isNotEmpty ? expense.id : _uuid.v4();

    return safeCall(
      () => _remoteDataSource.createExpense(
        groupId: expense.groupId,
        expenseId: expenseId,
        data: model.toMap(updatedBy: expense.createdBy),
      ),
    );
  }

  @override
  Future<Result<void>> updateExpense({
    required Expense expense,
    required String actorUserId,
  }) {
    final model = ExpenseModel.fromEntity(expense);
    return safeCall(
      () => _remoteDataSource.updateExpense(
        expenseId: expense.id,
        data: model.toMap(includeCreateAudit: false, updatedBy: actorUserId),
        actorUserId: actorUserId,
      ),
    );
  }

  @override
  Future<Result<List<Expense>>> getGroupExpenses(String groupId) {
    return safeCall(() => _remoteDataSource.getGroupExpenses(groupId));
  }

  @override
  Future<Result<Expense?>> getExpenseById(String expenseId) {
    return safeCall(() => _remoteDataSource.getExpenseById(expenseId));
  }

  @override
  Future<Result<void>> deleteExpense({
    required String expenseId,
    required String actorUserId,
  }) {
    return safeCall(
      () => _remoteDataSource.deleteExpense(
        expenseId: expenseId,
        actorUserId: actorUserId,
      ),
    );
  }

  @override
  Future<Result<void>> restoreExpense({
    required String expenseId,
    required String actorUserId,
  }) {
    return safeCall(
      () => _remoteDataSource.restoreExpense(
        expenseId: expenseId,
        actorUserId: actorUserId,
      ),
    );
  }

  @override
  Future<Result<void>> addExpenseComment({
    required String expenseId,
    required String actorUserId,
    required String text,
  }) {
    return safeCall(
      () => _remoteDataSource.addComment(
        expenseId: expenseId,
        actorUserId: actorUserId,
        text: text,
      ),
    );
  }
}
