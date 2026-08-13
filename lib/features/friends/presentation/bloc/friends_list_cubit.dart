import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../expenses/domain/repositories/expense_repository.dart';
import '../../../expenses/domain/services/friend_ledger.dart';
import '../../../home/domain/repositories/home_repository.dart';
import '../../domain/entities/user_preview.dart';
import '../../domain/repositories/friends_repository.dart';

class FriendsListState extends Equatable {
  final bool isLoading;
  final List<UserPreview> friends;
  final Map<String, double> balances;
  final Map<String, List<FriendGroupBalance>> groupBreakdowns;
  final String selectedFilter;
  final String? errorMessage;

  const FriendsListState({
    required this.isLoading,
    required this.friends,
    this.balances = const {},
    this.groupBreakdowns = const {},
    this.selectedFilter = 'all',
    this.errorMessage,
  });

  factory FriendsListState.initial() {
    return const FriendsListState(
      isLoading: true,
      friends: [],
    );
  }

  double get overallBalance => balances.values.fold(0.0, (sum, value) => sum + value);

  FriendsListState copyWith({
    bool? isLoading,
    List<UserPreview>? friends,
    Map<String, double>? balances,
    Map<String, List<FriendGroupBalance>>? groupBreakdowns,
    String? selectedFilter,
    String? errorMessage,
  }) {
    return FriendsListState(
      isLoading: isLoading ?? this.isLoading,
      friends: friends ?? this.friends,
      balances: balances ?? this.balances,
      groupBreakdowns: groupBreakdowns ?? this.groupBreakdowns,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [isLoading, friends, balances, groupBreakdowns, selectedFilter, errorMessage];
}

@injectable
class FriendsListCubit extends Cubit<FriendsListState> {
  final FriendsRepository _friendsRepository;
  final HomeRepository _homeRepository;
  final ExpenseRepository _expenseRepository;

  FriendsListCubit(
    this._friendsRepository,
    this._homeRepository,
    this._expenseRepository,
  ) : super(FriendsListState.initial());

  void setIdle() {
    emit(state.copyWith(
      isLoading: false,
      friends: const [],
      balances: const {},
      groupBreakdowns: const {},
      selectedFilter: 'all',
      errorMessage: null,
    ));
  }

  void changeFilter(String filter) {
    emit(state.copyWith(selectedFilter: filter));
  }

  Future<void> load(String userId) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    final friendsResult = await _friendsRepository.getFriends(userId);
    final pendingResult = await _friendsRepository.getPendingContacts(userId);

    if (friendsResult.isFailure || pendingResult.isFailure) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Could not load friends.',
        ),
      );
      return;
    }

    final merged = <UserPreview>[
      ...friendsResult.dataOrThrow,
      ...pendingResult.dataOrThrow,
    ]..sort((a, b) => a.name.compareTo(b.name));

    final computed = await _computeBalances(userId, merged);

    emit(
      state.copyWith(
        isLoading: false,
        friends: merged,
        balances: computed.balances,
        groupBreakdowns: computed.groupBreakdowns,
      ),
    );
  }

  Future<
      ({
        Map<String, double> balances,
        Map<String, List<FriendGroupBalance>> groupBreakdowns,
      })> _computeBalances(
    String userId,
    List<UserPreview> friends,
  ) async {
    if (friends.isEmpty) return (balances: <String, double>{}, groupBreakdowns: <String, List<FriendGroupBalance>>{});

    final groupsResult = await _homeRepository.getGroups(userId: userId);
    if (groupsResult.isFailure) {
      return (balances: <String, double>{}, groupBreakdowns: <String, List<FriendGroupBalance>>{});
    }
    final groups = groupsResult.dataOrThrow;
    if (groups.isEmpty) {
      return (balances: <String, double>{}, groupBreakdowns: <String, List<FriendGroupBalance>>{});
    }

    final groupNames = <String, String>{
      for (final group in groups) group.groupId: group.groupName,
    };

    final expensesByGroup = <String, List<Expense>>{};
    await Future.wait(groups.map((group) async {
      final result = await _expenseRepository.getGroupExpenses(group.groupId);
      expensesByGroup[group.groupId] = result.isSuccess ? result.dataOrThrow : const [];
    }));

    final balances = <String, double>{};
    final groupBreakdowns = <String, List<FriendGroupBalance>>{};
    for (final friend in friends) {
      final sharedExpenses = <Expense>[
        for (final group in groups)
          if (group.memberIds.contains(friend.id)) ...?expensesByGroup[group.groupId],
      ];
      if (sharedExpenses.isEmpty) continue;

      final entries = FriendLedger.build(
        expenses: sharedExpenses,
        currentUserId: userId,
        friendId: friend.id,
      );
      final total = FriendLedger.totalBalance(entries);
      if (total.abs() > 0.01) {
        balances[friend.id] = total;
        final breakdown = FriendLedger.groupBalances(entries: entries, groupNames: groupNames)
          ..sort((a, b) => b.amount.abs().compareTo(a.amount.abs()));
        groupBreakdowns[friend.id] = breakdown;
      }
    }
    return (balances: balances, groupBreakdowns: groupBreakdowns);
  }
}
