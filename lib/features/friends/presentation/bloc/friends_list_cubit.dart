import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../expenses/domain/services/friend_ledger.dart';
import '../../../home/domain/entities/balance_summary.dart';
import '../../../home/domain/repositories/home_repository.dart';
import '../../domain/entities/user_preview.dart';
import '../../domain/repositories/friends_repository.dart';
import '../../domain/services/friend_list_deduper.dart';

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

@lazySingleton
class FriendsListCubit extends Cubit<FriendsListState> {
  final FriendsRepository _friendsRepository;
  final HomeRepository _homeRepository;
  int _requestId = 0;

  FriendsListCubit(
    this._friendsRepository,
    this._homeRepository,
  ) : super(FriendsListState.initial());

  void setIdle() {
    _requestId++;
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
    final requestId = ++_requestId;
    final showFullScreenLoader = state.friends.isEmpty;
    if (showFullScreenLoader) {
      emit(state.copyWith(isLoading: true, errorMessage: null));
    }

    try {
      final friendsResult = await _friendsRepository.getFriends(userId);
      final pendingResult = await _friendsRepository.getPendingContacts(userId);
      final blockedResult = await _friendsRepository.getBlockedUsers(userId);

      if (isClosed || requestId != _requestId) return;

      if (friendsResult.isFailure || pendingResult.isFailure) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: 'Could not load friends.',
          ),
        );
        return;
      }

      final blockedIds = blockedResult.isSuccess
          ? blockedResult.dataOrThrow.map((user) => user.id).toSet()
          : <String>{};

      final merged = FriendListDeduper.merge(
        friends: friendsResult.dataOrThrow,
        pending: pendingResult.dataOrThrow,
      ).where((user) => !blockedIds.contains(user.id)).toList();

      final computed = await _computeBalances(userId, merged, blockedIds);
      if (isClosed || requestId != _requestId) return;

      emit(
        state.copyWith(
          isLoading: false,
          friends: merged,
          balances: computed.balances,
          groupBreakdowns: computed.groupBreakdowns,
        ),
      );
    } catch (_) {
      if (isClosed || requestId != _requestId) return;
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Could not load friends.',
        ),
      );
    }
  }

  Future<
      ({
        Map<String, double> balances,
        Map<String, List<FriendGroupBalance>> groupBreakdowns,
      })> _computeBalances(
    String userId,
    List<UserPreview> friends,
    Set<String> blockedIds,
  ) async {
    if (friends.isEmpty) {
      return (
        balances: <String, double>{},
        groupBreakdowns: <String, List<FriendGroupBalance>>{},
      );
    }

    final groupsResult = await _homeRepository.getGroups(userId: userId);
    if (groupsResult.isFailure) {
      return (
        balances: <String, double>{},
        groupBreakdowns: <String, List<FriendGroupBalance>>{},
      );
    }

    final groups = groupsResult.dataOrThrow
        .where((group) => !group.memberIds.any(blockedIds.contains))
        .toList();
    if (groups.isEmpty) {
      return (
        balances: <String, double>{},
        groupBreakdowns: <String, List<FriendGroupBalance>>{},
      );
    }

    final friendIds = {for (final friend in friends) friend.id};
    final balances = <String, double>{};
    final groupBreakdowns = <String, List<FriendGroupBalance>>{};

    for (final group in groups) {
      for (final memberBalance in group.memberBalances) {
        final friendId = memberBalance.userId;
        if (!friendIds.contains(friendId) || blockedIds.contains(friendId)) {
          continue;
        }
        if (memberBalance.amount.abs() <= 0.01) continue;

        final signed = memberBalance.type == BalanceType.owed
            ? memberBalance.amount
            : -memberBalance.amount;

        groupBreakdowns.putIfAbsent(friendId, () => []).add(
              FriendGroupBalance(
                groupId: group.groupId,
                groupName: group.groupName,
                amount: signed,
                currencySymbol: '₹',
                lastActivityDate: group.lastExpenseDate ?? DateTime.now(),
                expenseCount: 1,
              ),
            );
        balances[friendId] = (balances[friendId] ?? 0.0) + signed;
      }
    }

    balances.removeWhere((_, amount) => amount.abs() <= 0.01);
    groupBreakdowns.removeWhere((friendId, _) => !balances.containsKey(friendId));
    for (final breakdown in groupBreakdowns.values) {
      breakdown.sort((a, b) => b.amount.abs().compareTo(a.amount.abs()));
    }

    return (balances: balances, groupBreakdowns: groupBreakdowns);
  }
}
