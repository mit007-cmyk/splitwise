import 'package:equatable/equatable.dart';
import 'split_type.dart';

/// A single expense recorded against a group.
///
/// [paidBy] maps `userId -> amount paid` and supports one or many payers.
/// [splits] maps `userId -> amount owed` for every participant and always
/// sums to [amount] (validated before save).
class Expense extends Equatable {
  final String id;
  final String groupId;
  final String title;
  final String category;
  final double amount;
  final String currencyCode;
  final String currencySymbol;
  final DateTime date;
  final String? notes;
  final Map<String, double> paidBy;
  final Map<String, double> splits;
  final SplitType splitType;
  final List<String> participantIds;
  final String createdBy;
  final String? updatedBy;
  final DateTime? deletedAt;
  final String? deletedBy;
  final bool isDeleted;
  final String? receiptUrl;

  const Expense({
    required this.id,
    required this.groupId,
    required this.title,
    required this.category,
    required this.amount,
    required this.currencyCode,
    required this.currencySymbol,
    required this.date,
    this.notes,
    required this.paidBy,
    required this.splits,
    required this.splitType,
    required this.participantIds,
    required this.createdBy,
    this.updatedBy,
    this.deletedAt,
    this.deletedBy,
    this.isDeleted = false,
    this.receiptUrl,
  });

  @override
  List<Object?> get props => [
        id,
        groupId,
        title,
        category,
        amount,
        currencyCode,
        currencySymbol,
        date,
        notes,
        paidBy,
        splits,
        splitType,
        participantIds,
        createdBy,
        updatedBy,
        deletedAt,
        deletedBy,
        isDeleted,
        receiptUrl,
      ];
}
