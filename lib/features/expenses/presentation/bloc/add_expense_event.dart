import 'package:equatable/equatable.dart';
import '../../domain/entities/app_category.dart';
import '../../domain/entities/currency.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/split_type.dart';

abstract class AddExpenseEvent extends Equatable {
  const AddExpenseEvent();

  @override
  List<Object?> get props => [];
}

class InitAddExpense extends AddExpenseEvent {
  final String? groupId;

  /// When set (and [groupId] isn't), the expense starts in "friend mode":
  /// this friend is pre-selected as the only other participant/payer option
  /// and no real group needs to be chosen up front.
  final String? friendId;
  final Expense? existingExpense;

  const InitAddExpense({this.groupId, this.friendId, this.existingExpense});

  @override
  List<Object?> get props => [groupId, friendId, existingExpense];
}

class GroupSelected extends AddExpenseEvent {
  final String groupId;

  const GroupSelected(this.groupId);

  @override
  List<Object?> get props => [groupId];
}

class TitleChanged extends AddExpenseEvent {
  final String title;

  const TitleChanged(this.title);

  @override
  List<Object?> get props => [title];
}

class AmountChanged extends AddExpenseEvent {
  final String amountText;

  const AmountChanged(this.amountText);

  @override
  List<Object?> get props => [amountText];
}

class CategoryChanged extends AddExpenseEvent {
  final AppCategory category;

  const CategoryChanged(this.category);

  @override
  List<Object?> get props => [category];
}

class CreateCustomCategoryRequested extends AddExpenseEvent {
  final String name;
  final String iconKey;

  const CreateCustomCategoryRequested({
    required this.name,
    required this.iconKey,
  });

  @override
  List<Object?> get props => [name, iconKey];
}

class NotesChanged extends AddExpenseEvent {
  final String notes;

  const NotesChanged(this.notes);

  @override
  List<Object?> get props => [notes];
}

class DateChanged extends AddExpenseEvent {
  final DateTime date;

  const DateChanged(this.date);

  @override
  List<Object?> get props => [date];
}

class CurrencySearchChanged extends AddExpenseEvent {
  final String query;

  const CurrencySearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class CurrencySelected extends AddExpenseEvent {
  final Currency currency;

  const CurrencySelected(this.currency);

  @override
  List<Object?> get props => [currency];
}

class ParticipantToggled extends AddExpenseEvent {
  final String userId;

  const ParticipantToggled(this.userId);

  @override
  List<Object?> get props => [userId];
}

class AllParticipantsToggled extends AddExpenseEvent {
  final bool select;

  const AllParticipantsToggled(this.select);

  @override
  List<Object?> get props => [select];
}

class SplitTypeChanged extends AddExpenseEvent {
  final SplitType splitType;

  const SplitTypeChanged(this.splitType);

  @override
  List<Object?> get props => [splitType];
}

class SplitValueChanged extends AddExpenseEvent {
  final String userId;
  final String valueText;

  const SplitValueChanged({required this.userId, required this.valueText});

  @override
  List<Object?> get props => [userId, valueText];
}

class MultiplePayersToggled extends AddExpenseEvent {
  final bool enabled;

  const MultiplePayersToggled(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class SinglePayerSelected extends AddExpenseEvent {
  final String userId;

  const SinglePayerSelected(this.userId);

  @override
  List<Object?> get props => [userId];
}

class PayerAmountChanged extends AddExpenseEvent {
  final String userId;
  final String amountText;

  const PayerAmountChanged({required this.userId, required this.amountText});

  @override
  List<Object?> get props => [userId, amountText];
}

class SaveExpenseRequested extends AddExpenseEvent {
  const SaveExpenseRequested();
}

class DeleteExpenseRequested extends AddExpenseEvent {
  const DeleteExpenseRequested();
}

/// Applies one of the "How was this expense split?" quick presets in a
/// single atomic update (who paid + how it's split), used by the simplified
/// friend-mode flow before falling back to "More options" for full control.
class QuickSplitPresetApplied extends AddExpenseEvent {
  final String payerId;
  final SplitType splitType;
  final Map<String, String> splitValueTexts;

  const QuickSplitPresetApplied({
    required this.payerId,
    required this.splitType,
    this.splitValueTexts = const {},
  });

  @override
  List<Object?> get props => [payerId, splitType, splitValueTexts];
}

/// Applies a saved default-split template to the Add Expense / settings editor.
class DefaultSplitApplied extends AddExpenseEvent {
  final String paidByUserId;
  final SplitType splitType;
  final Set<String> selectedParticipantIds;
  final Map<String, String> splitValueTexts;

  const DefaultSplitApplied({
    required this.paidByUserId,
    required this.splitType,
    required this.selectedParticipantIds,
    this.splitValueTexts = const {},
  });

  @override
  List<Object?> get props => [paidByUserId, splitType, selectedParticipantIds, splitValueTexts];
}
