import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../expenses/domain/repositories/expense_repository.dart';
import '../../../home/domain/repositories/home_repository.dart';

class GroupDetailState extends Equatable {
  final bool isLoadingExpenses;
  final List<Expense> expenses;
  final String? expenseError;
  final Map<String, String> memberNames;

  const GroupDetailState({
    required this.isLoadingExpenses,
    this.expenses = const [],
    this.expenseError,
    this.memberNames = const {},
  });

  factory GroupDetailState.initial() {
    return const GroupDetailState(isLoadingExpenses: true);
  }

  GroupDetailState copyWith({
    bool? isLoadingExpenses,
    List<Expense>? expenses,
    String? expenseError,
    Map<String, String>? memberNames,
  }) {
    return GroupDetailState(
      isLoadingExpenses: isLoadingExpenses ?? this.isLoadingExpenses,
      expenses: expenses ?? this.expenses,
      expenseError: expenseError,
      memberNames: memberNames ?? this.memberNames,
    );
  }

  @override
  List<Object?> get props => [isLoadingExpenses, expenses, expenseError, memberNames];
}

class GroupDetailCubit extends Cubit<GroupDetailState> {
  final ExpenseRepository _expenseRepository;
  final HomeRepository _homeRepository;

  GroupDetailCubit(this._expenseRepository, this._homeRepository) : super(GroupDetailState.initial());

  Future<void> loadExpenses(String groupId) async {
    emit(state.copyWith(isLoadingExpenses: true, expenseError: null));
    
    // Fetch users for resolving names
    final usersResult = await _homeRepository.getAllUsers();
    final names = <String, String>{};
    if (usersResult.isSuccess) {
      for (final u in usersResult.dataOrThrow) {
        names[u.id] = u.name;
      }
    }

    final result = await _expenseRepository.getGroupExpenses(groupId);
    if (result.isSuccess) {
      final expenses = [...result.dataOrThrow]
        ..sort((a, b) => b.date.compareTo(a.date));
      emit(state.copyWith(
        isLoadingExpenses: false,
        expenses: expenses,
        expenseError: null,
        memberNames: names,
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

