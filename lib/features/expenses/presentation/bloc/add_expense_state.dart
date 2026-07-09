import 'package:equatable/equatable.dart';
import '../../../home/domain/entities/group_summary.dart';
import '../../domain/entities/currency.dart';
import '../../domain/entities/expense_participant.dart';
import '../../domain/entities/split_type.dart';
import '../../domain/services/split_calculator.dart';
import '../../data/datasources/currency_catalog.dart';

enum AddExpenseStatus { loading, ready, saving, success, failure }
enum AddExpenseAction { none, save, delete }

/// Sentinel used to distinguish "leave [errorMessage] unchanged" from
/// "explicitly clear [errorMessage]" inside [AddExpenseState.copyWith].
class _Unset {
  const _Unset();
}

const _unset = _Unset();

class AddExpenseState extends Equatable {
  final AddExpenseStatus status;
  final String? errorMessage;

  final String currentUserId;
  final String currentUserName;
  final String? editingExpenseId;
  final String? expenseCreatedBy;
  final AddExpenseAction lastAction;

  final List<GroupSummary> availableGroups;
  final String? groupId;
  final String groupName;

  /// True when this expense was started from a friend's page: [members] is
  /// pinned to just the current user + this friend and the UI shows a
  /// simplified "with {friend}" header instead of a group picker.
  final bool isDirectExpense;
  final String? friendId;

  final List<ExpenseParticipant> members;
  final Set<String> selectedParticipantIds;

  final String title;
  final String amountText;
  final Currency currency;
  final String currencyQuery;
  final String category;
  final String notes;
  final DateTime date;

  final bool isMultiplePayers;
  final String? singlePayerId;
  final Map<String, String> payerAmountTexts;

  final SplitType splitType;
  final Map<String, String> splitValueTexts;

  const AddExpenseState({
    required this.status,
    this.errorMessage,
    required this.currentUserId,
    required this.currentUserName,
    this.editingExpenseId,
    this.expenseCreatedBy,
    this.lastAction = AddExpenseAction.none,
    this.availableGroups = const [],
    this.groupId,
    this.groupName = '',
    this.isDirectExpense = false,
    this.friendId,
    this.members = const [],
    this.selectedParticipantIds = const {},
    this.title = '',
    this.amountText = '',
    this.currency = CurrencyCatalog.defaultCurrency,
    this.currencyQuery = '',
    this.category = 'General',
    this.notes = '',
    required this.date,
    this.isMultiplePayers = false,
    this.singlePayerId,
    this.payerAmountTexts = const {},
    this.splitType = SplitType.equally,
    this.splitValueTexts = const {},
  });

  factory AddExpenseState.initial({
    required String currentUserId,
    required String currentUserName,
  }) {
    return AddExpenseState(
      status: AddExpenseStatus.loading,
      currentUserId: currentUserId,
      currentUserName: currentUserName,
      lastAction: AddExpenseAction.none,
      date: DateTime.now(),
      singlePayerId: currentUserId,
    );
  }

  bool get isEditMode => editingExpenseId != null && editingExpenseId!.isNotEmpty;

  bool get canModifyExpense => !isEditMode || expenseCreatedBy == currentUserId;

  double get amount => double.tryParse(amountText.trim().replaceAll(',', '')) ?? 0.0;

  List<ExpenseParticipant> get selectedParticipants =>
      members.where((m) => selectedParticipantIds.contains(m.id)).toList();

  /// The other person in a 2-person expense (friend-mode, or any group that
  /// happens to have exactly the current user + one other member). Null
  /// otherwise.
  ExpenseParticipant? get otherParticipant {
    if (members.length != 2) return null;
    for (final member in members) {
      if (member.id != currentUserId) return member;
    }
    return null;
  }

  List<Currency> get filteredCurrencies => CurrencyCatalog.search(currencyQuery);

  Map<String, double> get computedSplits {
    final ids = selectedParticipantIds.toList();
    switch (splitType) {
      case SplitType.equally:
        return SplitCalculator.equally(amount, ids);
      case SplitType.unequally:
        return {
          for (final id in ids)
            id: double.tryParse((splitValueTexts[id] ?? '').trim().replaceAll(',', '')) ?? 0.0,
        };
      case SplitType.percentage:
        final percentages = {
          for (final id in ids) id: double.tryParse((splitValueTexts[id] ?? '').trim()) ?? 0.0,
        };
        return SplitCalculator.byPercentage(amount, percentages);
      case SplitType.shares:
        final shares = {
          for (final id in ids) id: int.tryParse((splitValueTexts[id] ?? '').trim()) ?? 0,
        };
        return SplitCalculator.byShares(amount, shares);
      case SplitType.adjustment:
        final adjustments = {
          for (final id in ids) id: double.tryParse((splitValueTexts[id] ?? '').trim()) ?? 0.0,
        };
        return SplitCalculator.byAdjustment(amount, ids, adjustments);
    }
  }

  bool get isSplitValid {
    final ids = selectedParticipantIds.toList();
    if (ids.isEmpty || amount <= 0) return false;
    switch (splitType) {
      case SplitType.equally:
        return true;
      case SplitType.unequally:
        final entered = {
          for (final id in ids)
            id: double.tryParse((splitValueTexts[id] ?? '').trim().replaceAll(',', '')) ?? 0.0,
        };
        return SplitCalculator.isValidUnequally(amount, entered);
      case SplitType.percentage:
        final percentages = {
          for (final id in ids) id: double.tryParse((splitValueTexts[id] ?? '').trim()) ?? 0.0,
        };
        return SplitCalculator.isValidPercentage(percentages);
      case SplitType.shares:
        final shares = {
          for (final id in ids) id: int.tryParse((splitValueTexts[id] ?? '').trim()) ?? 0,
        };
        return SplitCalculator.isValidShares(shares);
      case SplitType.adjustment:
        final adjustments = {
          for (final id in ids) id: double.tryParse((splitValueTexts[id] ?? '').trim()) ?? 0.0,
        };
        return SplitCalculator.isValidAdjustment(amount, ids, adjustments);
    }
  }

  Map<String, double> get computedPaidBy {
    if (!isMultiplePayers) {
      if (singlePayerId == null) return {};
      return {singlePayerId!: amount};
    }
    final result = <String, double>{};
    payerAmountTexts.forEach((id, text) {
      final value = double.tryParse(text.trim().replaceAll(',', '')) ?? 0.0;
      if (value > 0) result[id] = value;
    });
    return result;
  }

  bool get isPaidValid {
    if (!isMultiplePayers) return singlePayerId != null && amount > 0;
    final paid = computedPaidBy;
    if (paid.isEmpty) return false;
    return SplitCalculator.isCloseTo(SplitCalculator.sumOf(paid), amount);
  }

  String? get titleError => title.trim().isEmpty ? 'Please enter a description' : null;

  String? get amountError => amount <= 0 ? 'Enter an amount greater than 0' : null;

  String? get groupError => groupId == null ? 'Choose who this expense is with' : null;

  String? get participantsError =>
      selectedParticipantIds.isEmpty ? 'Select at least one person to split with' : null;

  String? get payersError {
    if (amountError != null) return null;
    if (!isPaidValid) {
      return isMultiplePayers
          ? 'The amounts paid must add up to the total'
          : 'Select who paid';
    }
    return null;
  }

  String? get splitError {
    if (amountError != null || participantsError != null) return null;
    if (isSplitValid) return null;
    switch (splitType) {
      case SplitType.equally:
        return null;
      case SplitType.unequally:
        return 'The split amounts must add up to the total';
      case SplitType.percentage:
        return 'The percentages must add up to 100%';
      case SplitType.shares:
        return 'Enter at least one share';
      case SplitType.adjustment:
        return 'The adjustments exceed the total amount';
    }
  }

  bool get canSave =>
      status != AddExpenseStatus.saving &&
      canModifyExpense &&
      titleError == null &&
      amountError == null &&
      groupError == null &&
      participantsError == null &&
      payersError == null &&
      splitError == null;

  AddExpenseState copyWith({
    AddExpenseStatus? status,
    Object? errorMessage = _unset,
    List<GroupSummary>? availableGroups,
    Object? groupId = _unset,
    String? groupName,
    bool? isDirectExpense,
    Object? friendId = _unset,
    List<ExpenseParticipant>? members,
    Set<String>? selectedParticipantIds,
    String? title,
    String? amountText,
    String? currentUserName,
    Currency? currency,
    String? currencyQuery,
    String? category,
    String? notes,
    DateTime? date,
    bool? isMultiplePayers,
    Object? singlePayerId = _unset,
    Map<String, String>? payerAmountTexts,
    SplitType? splitType,
    Map<String, String>? splitValueTexts,
    String? editingExpenseId,
    String? expenseCreatedBy,
    AddExpenseAction? lastAction,
  }) {
    return AddExpenseState(
      status: status ?? this.status,
      errorMessage: identical(errorMessage, _unset) ? this.errorMessage : errorMessage as String?,
      currentUserId: currentUserId,
      currentUserName: currentUserName ?? this.currentUserName,
      editingExpenseId: editingExpenseId ?? this.editingExpenseId,
      expenseCreatedBy: expenseCreatedBy ?? this.expenseCreatedBy,
      lastAction: lastAction ?? this.lastAction,
      availableGroups: availableGroups ?? this.availableGroups,
      groupId: identical(groupId, _unset) ? this.groupId : groupId as String?,
      groupName: groupName ?? this.groupName,
      isDirectExpense: isDirectExpense ?? this.isDirectExpense,
      friendId: identical(friendId, _unset) ? this.friendId : friendId as String?,
      members: members ?? this.members,
      selectedParticipantIds: selectedParticipantIds ?? this.selectedParticipantIds,
      title: title ?? this.title,
      amountText: amountText ?? this.amountText,
      currency: currency ?? this.currency,
      currencyQuery: currencyQuery ?? this.currencyQuery,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      date: date ?? this.date,
      isMultiplePayers: isMultiplePayers ?? this.isMultiplePayers,
      singlePayerId:
          identical(singlePayerId, _unset) ? this.singlePayerId : singlePayerId as String?,
      payerAmountTexts: payerAmountTexts ?? this.payerAmountTexts,
      splitType: splitType ?? this.splitType,
      splitValueTexts: splitValueTexts ?? this.splitValueTexts,
    );
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        currentUserId,
        currentUserName,
        editingExpenseId,
        expenseCreatedBy,
        lastAction,
        availableGroups,
        groupId,
        groupName,
        isDirectExpense,
        friendId,
        members,
        selectedParticipantIds,
        title,
        amountText,
        currency,
        currencyQuery,
        category,
        notes,
        date,
        isMultiplePayers,
        singlePayerId,
        payerAmountTexts,
        splitType,
        splitValueTexts,
      ];
}
