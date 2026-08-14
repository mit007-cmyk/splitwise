import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
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
  final Map<String, String> groupNames;
  final String? soleSharedGroupId;
  final String? errorMessage;

  const FriendDetailState({
    required this.isLoading,
    this.friend,
    this.entries = const [],
    this.groupNames = const {},
    this.soleSharedGroupId,
    this.errorMessage,
  });

  factory FriendDetailState.initial() => const FriendDetailState(isLoading: true);

  double get totalBalance => FriendLedger.totalBalance(entries);

  /// Per-group breakdown of [totalBalance], sorted by size — powers the
  /// "{friend} owes you ₹x in "{group}"" lines under the header balance.
  List<FriendGroupBalance> get groupBalances {
    final balances = FriendLedger.groupBalances(entries: entries, groupNames: groupNames)
      ..sort((a, b) => b.amount.abs().compareTo(a.amount.abs()));
    return balances;
  }

  FriendDetailState copyWith({
    bool? isLoading,
    UserPreview? friend,
    List<FriendExpenseEntry>? entries,
    Map<String, String>? groupNames,
    String? soleSharedGroupId,
    bool clearSoleSharedGroupId = false,
    String? errorMessage,
  }) {
    return FriendDetailState(
      isLoading: isLoading ?? this.isLoading,
      friend: friend ?? this.friend,
      entries: entries ?? this.entries,
      groupNames: groupNames ?? this.groupNames,
      soleSharedGroupId: clearSoleSharedGroupId
          ? null
          : (soleSharedGroupId ?? this.soleSharedGroupId),
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [isLoading, friend, entries, groupNames, soleSharedGroupId, errorMessage];
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
    final allExpenses = <Expense>[];
    await Future.wait(sharedGroups.map((group) async {
      groupNames[group.groupId] = group.groupName;
      final result = await _expenseRepository.getGroupExpenses(group.groupId);
      if (result.isSuccess) allExpenses.addAll(result.dataOrThrow);
    }));

    final entries = FriendLedger.build(
      expenses: allExpenses,
      currentUserId: currentUserId,
      friendId: friendId,
    );

    emit(state.copyWith(
      isLoading: false,
      friend: friend,
      entries: entries,
      groupNames: groupNames,
      soleSharedGroupId:
          sharedGroups.length == 1 ? sharedGroups.first.groupId : null,
      clearSoleSharedGroupId: sharedGroups.length != 1,
    ));
  }
}
