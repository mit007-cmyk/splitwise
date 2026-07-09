import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/result.dart';
import '../../../friends/domain/repositories/friends_repository.dart';
import '../../../home/domain/entities/group_summary.dart';
import '../../../home/domain/repositories/home_repository.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_participant.dart';
import '../../domain/entities/split_type.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../domain/services/direct_group.dart';
import 'add_expense_event.dart';
import 'add_expense_state.dart';

class AddExpenseBloc extends Bloc<AddExpenseEvent, AddExpenseState> {
  final ExpenseRepository _expenseRepository;
  final HomeRepository _homeRepository;
  final FriendsRepository _friendsRepository;
  static const _uuid = Uuid();

  /// The full app user directory (fetched once in [_onInit]), keyed by user
  /// id. Kept on the bloc rather than in [AddExpenseState] since it's just a
  /// lookup cache, not something the UI renders directly.
  ///
  /// Every group switch must resolve member names from this *complete*
  /// directory — not from whichever group happened to be loaded previously
  /// — otherwise anyone who wasn't already in the old group's roster falls
  /// back to the generic "Splitwise user" placeholder even though their
  /// real name is known.
  final Map<String, String> _userNames = {};
  final Map<String, String?> _userPhotos = {};

  AddExpenseBloc({
    required ExpenseRepository expenseRepository,
    required HomeRepository homeRepository,
    required FriendsRepository friendsRepository,
    required String currentUserId,
    required String currentUserName,
  })  : _expenseRepository = expenseRepository,
        _homeRepository = homeRepository,
        _friendsRepository = friendsRepository,
        super(AddExpenseState.initial(
          currentUserId: currentUserId,
          currentUserName: currentUserName,
        )) {
    on<InitAddExpense>(_onInit);
    on<GroupSelected>(_onGroupSelected);
    on<TitleChanged>((event, emit) => emit(state.copyWith(title: event.title)));
    on<AmountChanged>((event, emit) => emit(state.copyWith(amountText: event.amountText)));
    on<CategoryChanged>((event, emit) => emit(state.copyWith(category: event.category)));
    on<NotesChanged>((event, emit) => emit(state.copyWith(notes: event.notes)));
    on<DateChanged>((event, emit) => emit(state.copyWith(date: event.date)));
    on<CurrencySearchChanged>(
      (event, emit) => emit(state.copyWith(currencyQuery: event.query)),
    );
    on<CurrencySelected>(
      (event, emit) => emit(state.copyWith(currency: event.currency, currencyQuery: '')),
    );
    on<ParticipantToggled>(_onParticipantToggled);
    on<AllParticipantsToggled>(_onAllParticipantsToggled);
    on<SplitTypeChanged>((event, emit) => emit(state.copyWith(splitType: event.splitType)));
    on<SplitValueChanged>(_onSplitValueChanged);
    on<MultiplePayersToggled>(_onMultiplePayersToggled);
    on<SinglePayerSelected>(
      (event, emit) => emit(state.copyWith(singlePayerId: event.userId)),
    );
    on<PayerAmountChanged>(_onPayerAmountChanged);
    on<SaveExpenseRequested>(_onSaveRequested);
    on<DeleteExpenseRequested>(_onDeleteRequested);
    on<QuickSplitPresetApplied>(_onQuickSplitPresetApplied);
  }

  Future<void> _onInit(InitAddExpense event, Emitter<AddExpenseState> emit) async {
    emit(state.copyWith(status: AddExpenseStatus.loading));

    final groupsResult = await _homeRepository.getGroups(userId: state.currentUserId);
    final usersResult = await _homeRepository.getAllUsers();

    if (groupsResult.isFailure) {
      emit(state.copyWith(
        status: AddExpenseStatus.failure,
        errorMessage: 'Could not load your groups.',
      ));
      return;
    }

    // "Direct" groups are a synthetic bookkeeping bucket, not something the
    // user should be able to pick from a group list.
    final groups = groupsResult.dataOrThrow
        .where((g) => g.groupType != DirectGroup.type)
        .toList();
    if (usersResult.isSuccess) {
      for (final user in usersResult.dataOrThrow) {
        _userNames[user.id] = user.name;
        _userPhotos[user.id] = user.photoUrl;
      }
    }

    emit(state.copyWith(
      status: AddExpenseStatus.ready,
      availableGroups: groups,
    ));

    if (event.existingExpense != null) {
      _applyExistingExpense(event.existingExpense!, groups, emit);
      return;
    }

    if (event.friendId != null) {
      await _applyFriendMode(event.friendId!, emit);
      return;
    }

    GroupSummary? initialGroup;
    if (event.groupId != null) {
      for (final group in groups) {
        if (group.groupId == event.groupId) {
          initialGroup = group;
          break;
        }
      }
    }

    if (initialGroup != null) {
      _applyGroup(initialGroup, emit);
    }
  }

  Future<void> _applyFriendMode(String friendId, Emitter<AddExpenseState> emit) async {
    var friendName = _userNames[friendId] ?? 'Splitwise user';
    var friendPhotoUrl = _userPhotos[friendId];

    if (!_userNames.containsKey(friendId)) {
      final friendResult = await _friendsRepository.getUserById(friendId);
      if (friendResult.isSuccess) {
        final friend = friendResult.dataOrThrow;
        if (friend != null) {
          friendName = friend.name;
          friendPhotoUrl = friend.photoUrl;
          _userNames[friendId] = friendName;
          _userPhotos[friendId] = friendPhotoUrl;
        }
      }
    }

    final members = [
      ExpenseParticipant(id: state.currentUserId, name: 'You'),
      ExpenseParticipant(id: friendId, name: friendName, photoUrl: friendPhotoUrl),
    ];

    emit(state.copyWith(
      isDirectExpense: true,
      friendId: friendId,
      groupId: DirectGroup.idFor(state.currentUserId, friendId),
      groupName: DirectGroup.defaultName,
      members: members,
      selectedParticipantIds: members.map((m) => m.id).toSet(),
      singlePayerId: state.currentUserId,
      splitType: SplitType.equally,
      splitValueTexts: const {},
      payerAmountTexts: const {},
    ));
  }

  void _onGroupSelected(GroupSelected event, Emitter<AddExpenseState> emit) {
    GroupSummary? group;
    for (final g in state.availableGroups) {
      if (g.groupId == event.groupId) {
        group = g;
        break;
      }
    }
    if (group == null) return;

    _applyGroup(group, emit);
  }

  void _applyGroup(GroupSummary group, Emitter<AddExpenseState> emit) {
    final members = group.memberIds
        .map((id) => ExpenseParticipant(
              id: id,
              name: id == state.currentUserId
                  ? 'You'
                  : (_userNames[id] ?? 'Splitwise user'),
              photoUrl: id == state.currentUserId ? null : _userPhotos[id],
            ))
        .toList();

    final payerId = members.any((m) => m.id == state.currentUserId)
        ? state.currentUserId
        : (members.isNotEmpty ? members.first.id : null);

    emit(state.copyWith(
      isDirectExpense: false,
      groupId: group.groupId,
      groupName: group.groupName,
      members: members,
      selectedParticipantIds: members.map((m) => m.id).toSet(),
      singlePayerId: payerId,
      payerAmountTexts: const {},
    ));
  }

  void _applyExistingExpense(
    Expense expense,
    List<GroupSummary> groups,
    Emitter<AddExpenseState> emit,
  ) {
    final matchingGroup = groups.where((g) => g.groupId == expense.groupId).toList();

    List<ExpenseParticipant> members;
    String groupName;
    if (matchingGroup.isNotEmpty) {
      final g = matchingGroup.first;
      groupName = g.groupName;
      members = g.memberIds
          .map((id) => ExpenseParticipant(
                id: id,
                name: id == state.currentUserId ? 'You' : (_userNames[id] ?? 'Splitwise user'),
                photoUrl: id == state.currentUserId ? null : _userPhotos[id],
              ))
          .toList();
    } else {
      groupName = 'Group';
      members = expense.participantIds
          .map((id) => ExpenseParticipant(
                id: id,
                name: id == state.currentUserId ? 'You' : (_userNames[id] ?? 'Splitwise user'),
                photoUrl: id == state.currentUserId ? null : _userPhotos[id],
              ))
          .toList();
    }

    final amountText = expense.amount.toStringAsFixed(2);
    final splitValueTexts = _splitTextsFromExpense(expense);
    final isMultiplePayers = expense.paidBy.length > 1;
    final payerAmountTexts = isMultiplePayers
        ? {
            for (final entry in expense.paidBy.entries)
              entry.key: entry.value.toStringAsFixed(2),
          }
        : <String, String>{};
    final singlePayerId = isMultiplePayers
        ? null
        : (expense.paidBy.isNotEmpty ? expense.paidBy.keys.first : state.currentUserId);

    emit(state.copyWith(
      status: AddExpenseStatus.ready,
      errorMessage: null,
      groupId: expense.groupId,
      groupName: groupName,
      isDirectExpense: false,
      friendId: null,
      members: members,
      selectedParticipantIds: expense.participantIds.toSet(),
      title: expense.title,
      amountText: amountText,
      category: expense.category,
      notes: expense.notes ?? '',
      date: expense.date,
      currency: state.filteredCurrencies.firstWhere(
        (c) => c.code == expense.currencyCode,
        orElse: () => state.currency,
      ),
      isMultiplePayers: isMultiplePayers,
      singlePayerId: singlePayerId,
      payerAmountTexts: payerAmountTexts,
      splitType: expense.splitType,
      splitValueTexts: splitValueTexts,
      editingExpenseId: expense.id,
      expenseCreatedBy: expense.createdBy,
      lastAction: AddExpenseAction.none,
    ));
  }

  Map<String, String> _splitTextsFromExpense(Expense expense) {
    switch (expense.splitType) {
      case SplitType.equally:
        return const {};
      case SplitType.unequally:
      case SplitType.adjustment:
        return {
          for (final entry in expense.splits.entries)
            entry.key: entry.value.toStringAsFixed(2),
        };
      case SplitType.percentage:
        if (expense.amount <= 0) return const {};
        return {
          for (final entry in expense.splits.entries)
            entry.key: ((entry.value / expense.amount) * 100).toStringAsFixed(2),
        };
      case SplitType.shares:
        return {
          for (final entry in expense.splits.entries)
            entry.key: entry.value.round().toString(),
        };
    }
  }

  void _onQuickSplitPresetApplied(
    QuickSplitPresetApplied event,
    Emitter<AddExpenseState> emit,
  ) {
    emit(state.copyWith(
      isMultiplePayers: false,
      singlePayerId: event.payerId,
      splitType: event.splitType,
      splitValueTexts: event.splitValueTexts,
      payerAmountTexts: const {},
    ));
  }

  void _onParticipantToggled(ParticipantToggled event, Emitter<AddExpenseState> emit) {
    final updated = Set<String>.from(state.selectedParticipantIds);
    if (updated.contains(event.userId)) {
      updated.remove(event.userId);
    } else {
      updated.add(event.userId);
    }
    emit(state.copyWith(selectedParticipantIds: updated));
  }

  void _onAllParticipantsToggled(AllParticipantsToggled event, Emitter<AddExpenseState> emit) {
    emit(state.copyWith(
      selectedParticipantIds:
          event.select ? state.members.map((m) => m.id).toSet() : <String>{},
    ));
  }

  void _onSplitValueChanged(SplitValueChanged event, Emitter<AddExpenseState> emit) {
    final updated = Map<String, String>.from(state.splitValueTexts);
    updated[event.userId] = event.valueText;
    emit(state.copyWith(splitValueTexts: updated));
  }

  void _onMultiplePayersToggled(MultiplePayersToggled event, Emitter<AddExpenseState> emit) {
    if (event.enabled) {
      final texts = Map<String, String>.from(state.payerAmountTexts);
      if (state.singlePayerId != null && !texts.containsKey(state.singlePayerId)) {
        texts[state.singlePayerId!] = state.amount > 0 ? state.amount.toStringAsFixed(2) : '';
      }
      emit(state.copyWith(isMultiplePayers: true, payerAmountTexts: texts));
    } else {
      emit(state.copyWith(isMultiplePayers: false));
    }
  }

  void _onPayerAmountChanged(PayerAmountChanged event, Emitter<AddExpenseState> emit) {
    final updated = Map<String, String>.from(state.payerAmountTexts);
    updated[event.userId] = event.amountText;
    emit(state.copyWith(payerAmountTexts: updated));
  }

  Future<void> _onSaveRequested(
    SaveExpenseRequested event,
    Emitter<AddExpenseState> emit,
  ) async {
    if (!state.canSave) {
      emit(state.copyWith(errorMessage: 'Please fix the highlighted fields.'));
      return;
    }

    emit(state.copyWith(status: AddExpenseStatus.saving, errorMessage: null));

    if (state.isDirectExpense) {
      final ensureResult = await _homeRepository.ensureGroupExists(
        groupId: state.groupId!,
        name: DirectGroup.defaultName,
        type: DirectGroup.type,
        memberIds: [state.currentUserId, state.friendId!],
      );
      if (ensureResult.isFailure) {
        emit(state.copyWith(
          status: AddExpenseStatus.ready,
          errorMessage: 'Could not save the expense. Please try again.',
        ));
        return;
      }
    }

    final expense = Expense(
      id: state.editingExpenseId ?? _uuid.v4(),
      groupId: state.groupId!,
      title: state.title.trim(),
      category: state.category,
      amount: state.amount,
      currencyCode: state.currency.code,
      currencySymbol: state.currency.symbol,
      date: state.date,
      notes: state.notes.trim().isEmpty ? null : state.notes.trim(),
      paidBy: state.computedPaidBy,
      splits: state.computedSplits,
      splitType: state.splitType,
      participantIds: state.selectedParticipantIds.toList(),
      createdBy: state.expenseCreatedBy ?? state.currentUserId,
    );

    final Result<void> result = state.isEditMode
        ? await _expenseRepository.updateExpense(
            expense: expense,
            actorUserId: state.currentUserId,
          )
        : await _expenseRepository.createExpense(expense);

    if (result.isSuccess) {
      emit(state.copyWith(
        status: AddExpenseStatus.success,
        lastAction: AddExpenseAction.save,
      ));
    } else {
      emit(state.copyWith(
        status: AddExpenseStatus.ready,
        errorMessage: state.isEditMode
            ? 'Could not update the expense. Please try again.'
            : 'Could not save the expense. Please try again.',
      ));
    }
  }

  Future<void> _onDeleteRequested(
    DeleteExpenseRequested event,
    Emitter<AddExpenseState> emit,
  ) async {
    if (!state.isEditMode || !state.canModifyExpense) {
      emit(state.copyWith(errorMessage: 'You do not have permission to delete this expense.'));
      return;
    }
    emit(state.copyWith(status: AddExpenseStatus.saving, errorMessage: null));
    final result = await _expenseRepository.deleteExpense(
      expenseId: state.editingExpenseId!,
      actorUserId: state.currentUserId,
    );
    if (result.isSuccess) {
      emit(state.copyWith(
        status: AddExpenseStatus.success,
        lastAction: AddExpenseAction.delete,
      ));
    } else {
      emit(state.copyWith(
        status: AddExpenseStatus.ready,
        errorMessage: 'Could not delete the expense. Please try again.',
      ));
    }
  }
}
