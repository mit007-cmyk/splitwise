import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../expenses/domain/repositories/expense_repository.dart';

class GroupDetailState extends Equatable {
  final bool isLoadingExpenses;
  final List<Expense> expenses;
  final String? expenseError;

  const GroupDetailState({
    required this.isLoadingExpenses,
    this.expenses = const [],
    this.expenseError,
  });

  factory GroupDetailState.initial() {
    return const GroupDetailState(isLoadingExpenses: true);
  }

  GroupDetailState copyWith({
    bool? isLoadingExpenses,
    List<Expense>? expenses,
    String? expenseError,
  }) {
    return GroupDetailState(
      isLoadingExpenses: isLoadingExpenses ?? this.isLoadingExpenses,
      expenses: expenses ?? this.expenses,
      expenseError: expenseError,
    );
  }

  @override
  List<Object?> get props => [isLoadingExpenses, expenses, expenseError];
}

class GroupDetailCubit extends Cubit<GroupDetailState> {
  final ExpenseRepository _expenseRepository;

  GroupDetailCubit(this._expenseRepository) : super(GroupDetailState.initial());

  Future<void> loadExpenses(String groupId) async {
    emit(state.copyWith(isLoadingExpenses: true, expenseError: null));
    final result = await _expenseRepository.getGroupExpenses(groupId);
    if (result.isSuccess) {
      final expenses = [...result.dataOrThrow]
        ..sort((a, b) => b.date.compareTo(a.date));
      emit(state.copyWith(
        isLoadingExpenses: false,
        expenses: expenses,
        expenseError: null,
      ));
      return;
    }

    emit(state.copyWith(
      isLoadingExpenses: false,
      expenseError: 'Could not load expenses.',
      expenses: const [],
    ));
  }
}

