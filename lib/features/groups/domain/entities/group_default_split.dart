import 'package:equatable/equatable.dart';
import '../../../expenses/domain/entities/split_type.dart';
import '../../../expenses/domain/services/split_calculator.dart';

/// Personal default split template for one user inside one group.
/// Applied when that user creates a new expense — never retroactively.
class GroupDefaultSplit extends Equatable {
  final String groupId;
  final String userId;
  final String paidByUserId;
  final SplitType splitType;
  final Set<String> selectedParticipantIds;
  final Map<String, String> splitValueTexts;

  const GroupDefaultSplit({
    required this.groupId,
    required this.userId,
    required this.paidByUserId,
    required this.splitType,
    required this.selectedParticipantIds,
    this.splitValueTexts = const {},
  });

  /// Reference amount used when configuring exact-amount defaults.
  static const double templateAmount = 100.0;

  bool isValidForMembers(Set<String> memberIds) {
    if (selectedParticipantIds.isEmpty) return false;
    if (!memberIds.contains(paidByUserId)) return false;
    if (!selectedParticipantIds.every(memberIds.contains)) return false;

    final ids = selectedParticipantIds.toList();
    switch (splitType) {
      case SplitType.equally:
        return true;
      case SplitType.unequally:
        final entered = {
          for (final id in ids)
            id: double.tryParse((splitValueTexts[id] ?? '').trim()) ?? 0.0,
        };
        return SplitCalculator.isValidUnequally(templateAmount, entered);
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
        return SplitCalculator.isValidAdjustment(templateAmount, ids, adjustments);
    }
  }

  /// Scales unequally/adjustment template values when prefilling a real expense.
  Map<String, String> splitValueTextsForAmount(double amount) {
    if (splitType != SplitType.unequally || amount <= 0) {
      return splitValueTexts;
    }

    final ids = selectedParticipantIds.toList();
    final templateAmounts = {
      for (final id in ids) id: double.tryParse((splitValueTexts[id] ?? '').trim()) ?? 0.0,
    };
    final templateTotal = SplitCalculator.sumOf(templateAmounts);
    if (templateTotal <= 0) return splitValueTexts;

    return {
      for (final id in ids)
        id: (templateAmounts[id]! / templateTotal * amount).toStringAsFixed(2),
    };
  }

  String summaryLabel(String payerName) {
    final splitLabel = switch (splitType) {
      SplitType.equally => 'equally',
      SplitType.unequally => 'by exact amounts',
      SplitType.percentage => 'by percentage',
      SplitType.shares => 'by shares',
      SplitType.adjustment => 'by adjustment',
    };
    return 'Paid by $payerName and split $splitLabel';
  }

  @override
  List<Object?> get props => [
        groupId,
        userId,
        paidByUserId,
        splitType,
        selectedParticipantIds,
        splitValueTexts,
      ];
}
