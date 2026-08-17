import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/currency_amount.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../expenses/domain/repositories/expense_repository.dart';
import '../../../expenses/domain/services/friend_ledger.dart';
import '../../../home/domain/entities/group_summary.dart';
import '../../../home/domain/repositories/home_repository.dart';
import '../../domain/entities/user_preview.dart';
import '../../domain/repositories/friends_repository.dart';

class FriendDetailState extends Equatable {
  final bool isLoading;
  final UserPreview? friend;
  final List<FriendExpenseEntry> entries;
  final List<FriendGroupBalance> groupBalances;
  final Map<String, String> groupNames;
  final String? soleSharedGroupId;
  final String? errorMessage;

  const FriendDetailState({
    required this.isLoading,
    this.friend,
    this.entries = const [],
    this.groupBalances = const [],
    this.groupNames = const {},
    this.soleSharedGroupId,
    this.errorMessage,
  });

  factory FriendDetailState.initial() => const FriendDetailState(isLoading: true);

  List<CurrencyAmount> get overallAmounts => MultiCurrency.netByCurrency(
        groupBalances.map(
          (row) => CurrencyAmount(
            amount: row.amount,
            currencyCode: row.currencyCode,
            currencySymbol: row.currencySymbol,
          ),
        ),
      );

  bool get isSettled => overallAmounts.isEmpty;

  FriendDetailState copyWith({
    bool? isLoading,
    UserPreview? friend,
    List<FriendExpenseEntry>? entries,
    List<FriendGroupBalance>? groupBalances,
    Map<String, String>? groupNames,
    String? soleSharedGroupId,
    bool clearSoleSharedGroupId = false,
    String? errorMessage,
  }) {
    return FriendDetailState(
      isLoading: isLoading ?? this.isLoading,
      friend: friend ?? this.friend,
      entries: entries ?? this.entries,
      groupBalances: groupBalances ?? this.groupBalances,
      groupNames: groupNames ?? this.groupNames,
      soleSharedGroupId: clearSoleSharedGroupId
          ? null
          : (soleSharedGroupId ?? this.soleSharedGroupId),
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        friend,
        entries,
        groupBalances,
        groupNames,
        soleSharedGroupId,
        errorMessage,
      ];
}

@injectable
class FriendDetailCubit extends Cubit<FriendDetailState> {
  final FriendsRepository _friendsRepository;
  final HomeRepository _homeRepository;
  final ExpenseRepository _expenseRepository;

  FriendDetailCubit(
    this._friendsRepository,
    this._homeRepository,
    this._expenseRepository,
  ) : super(FriendDetailState.initial());

  Future<void> load({required String currentUserId, required String friendId}) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    final friendResult = await _friendsRepository.getUserById(friendId);
    if (friendResult.isFailure || friendResult.dataOrThrow == null) {
      emit(state.copyWith(isLoading: false, errorMessage: 'Friend not found'));
      return;
    }
    final friend = friendResult.dataOrThrow!;

    final groupsResult = await _homeRepository.getGroups(userId: currentUserId);
    final sharedGroups = groupsResult.isSuccess
        ? groupsResult.dataOrThrow.where((g) => g.memberIds.contains(friendId)).toList()
        : const <GroupSummary>[];

    final groupNames = <String, String>{};
    final expensesByGroup = <String, List<Expense>>{};
    await Future.wait(sharedGroups.map((group) async {
      groupNames[group.groupId] = group.groupName;
      final result = await _expenseRepository.getGroupExpenses(group.groupId);
      expensesByGroup[group.groupId] =
          result.isSuccess ? result.dataOrThrow : const <Expense>[];
    }));

    final allExpenses = [
      for (final expenses in expensesByGroup.values) ...expenses,
    ];
    final entries = FriendLedger.build(
      expenses: allExpenses,
      currentUserId: currentUserId,
      friendId: friendId,
    );

    final groupBalances = <FriendGroupBalance>[];
    for (final group in sharedGroups) {
      groupBalances.addAll(
        FriendLedger.balancesInGroup(
          groupId: group.groupId,
          groupName: group.groupName,
          expenses: expensesByGroup[group.groupId] ?? const <Expense>[],
          memberIds: group.memberIds,
          simplifyDebts: group.simplifyDebts,
          currentUserId: currentUserId,
          friendId: friendId,
        ),
      );
    }
    groupBalances.sort((a, b) => b.amount.abs().compareTo(a.amount.abs()));

    emit(state.copyWith(
      isLoading: false,
      friend: friend,
      entries: entries,
      groupBalances: groupBalances,
      groupNames: groupNames,
      soleSharedGroupId:
          sharedGroups.length == 1 ? sharedGroups.first.groupId : null,
      clearSoleSharedGroupId: sharedGroups.length != 1,
    ));
  }
}
