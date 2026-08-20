import 'package:equatable/equatable.dart';
import 'category_source.dart';
import 'expense_comment.dart';
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
  /// Display-name snapshot. Kept so historical lists and charts still work
  /// if a custom category is later renamed or soft-deleted.
  final String category;
  final String? categoryId;
  final CategorySource? categorySource;
  final String? categoryIcon;
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
  final List<ExpenseComment> comments;

  const Expense({
    required this.id,
    required this.groupId,
    required this.title,
    required this.category,
    this.categoryId,
    this.categorySource,
    this.categoryIcon,
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
    this.comments = const [],
  });

  Expense copyWith({
    String? id,
    String? groupId,
    String? title,
    String? category,
    String? categoryId,
    CategorySource? categorySource,
    String? categoryIcon,
    double? amount,
    String? currencyCode,
    String? currencySymbol,
    DateTime? date,
    String? notes,
    Map<String, double>? paidBy,
    Map<String, double>? splits,
    SplitType? splitType,
    List<String>? participantIds,
    String? createdBy,
    String? updatedBy,
    DateTime? deletedAt,
    String? deletedBy,
    bool? isDeleted,
    String? receiptUrl,
    List<ExpenseComment>? comments,
  }) {
    return Expense(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      title: title ?? this.title,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      categorySource: categorySource ?? this.categorySource,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      paidBy: paidBy ?? this.paidBy,
      splits: splits ?? this.splits,
      splitType: splitType ?? this.splitType,
      participantIds: participantIds ?? this.participantIds,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
      isDeleted: isDeleted ?? this.isDeleted,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      comments: comments ?? this.comments,
    );
  }

  bool matchesCategory({required String name, String? categoryId}) {
    final id = categoryId?.trim();
    if (id != null && id.isNotEmpty) {
      if (this.categoryId == id) return true;
      if (this.categoryId == null || this.categoryId!.isEmpty) {
        return category.toLowerCase() == name.toLowerCase();
      }
      return false;
    }
    return category.toLowerCase() == name.toLowerCase();
  }

  @override
  List<Object?> get props => [
        id,
        groupId,
        title,
        category,
        categoryId,
        categorySource,
        categoryIcon,
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
        comments,
      ];
}
