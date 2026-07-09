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
        data: model.toMap(),
      ),
    );
  }

  @override
  Future<Result<List<Expense>>> getGroupExpenses(String groupId) {
    return safeCall(() => _remoteDataSource.getGroupExpenses(groupId));
  }
}
