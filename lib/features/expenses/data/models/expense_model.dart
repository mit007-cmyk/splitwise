import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/category_source.dart';
import '../../domain/entities/default_categories.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_comment.dart';
import '../../domain/entities/split_type.dart';

class ExpenseModel extends Expense {
  const ExpenseModel({
    required super.id,
    required super.groupId,
    required super.title,
    required super.category,
    super.categoryId,
    super.categorySource,
    super.categoryIcon,
    required super.amount,
    required super.currencyCode,
    required super.currencySymbol,
    required super.date,
    super.notes,
    required super.paidBy,
    required super.splits,
    required super.splitType,
    required super.participantIds,
    required super.createdBy,
    super.updatedBy,
    super.deletedAt,
    super.deletedBy,
    super.isDeleted,
    super.receiptUrl,
    super.comments,
  });

  factory ExpenseModel.fromEntity(Expense expense) {
    return ExpenseModel(
      id: expense.id,
      groupId: expense.groupId,
      title: expense.title,
      category: expense.category,
      categoryId: expense.categoryId,
      categorySource: expense.categorySource,
      categoryIcon: expense.categoryIcon,
      amount: expense.amount,
      currencyCode: expense.currencyCode,
      currencySymbol: expense.currencySymbol,
      date: expense.date,
      notes: expense.notes,
      paidBy: expense.paidBy,
      splits: expense.splits,
      splitType: expense.splitType,
      participantIds: expense.participantIds,
      createdBy: expense.createdBy,
      updatedBy: expense.updatedBy,
      deletedAt: expense.deletedAt,
      deletedBy: expense.deletedBy,
      isDeleted: expense.isDeleted,
      receiptUrl: expense.receiptUrl,
      comments: expense.comments,
    );
  }

  /// Rebuilds an [ExpenseModel] from a raw Firestore expense map.
  ///
  /// Supports `Splitwise/expenses.{id}` maps and nested
  /// `Splitwise/groups.{groupId}.expenses.{id}` maps. Tolerant of
  /// older documents that
  /// predate this module (single `paidById`, missing `title`/`category`/etc.)
  /// so old and new expenses can be read back side by side.
  factory ExpenseModel.fromMap(String id, String groupId, Map<String, dynamic> map) {
    final rawDate = map['date'];
    final date = rawDate is Timestamp ? rawDate.toDate() : DateTime.now();
    final rawDeletedAt = map['deletedAt'];
    final deletedAt = rawDeletedAt is Timestamp ? rawDeletedAt.toDate() : null;

    final amount = (map['amount'] as num?)?.toDouble() ?? 0.0;

    final paidBy = <String, double>{};
    if (map['paidBy'] is Map) {
      (map['paidBy'] as Map).forEach((key, value) {
        paidBy[key as String] = (value as num?)?.toDouble() ?? 0.0;
      });
    } else {
      final legacyPaidById = map['paidById'] as String?;
      if (legacyPaidById != null && legacyPaidById.isNotEmpty) {
        paidBy[legacyPaidById] = amount;
      }
    }

    final splits = <String, double>{};
    if (map['splits'] is Map) {
      (map['splits'] as Map).forEach((key, value) {
        splits[key as String] = (value as num?)?.toDouble() ?? 0.0;
      });
    }

    final participantIds = map['participantIds'] is List
        ? List<String>.from(map['participantIds'] as List)
        : splits.keys.toList();

    final splitType = SplitType.values.firstWhere(
      (type) => type.name == map['splitType'],
      orElse: () => SplitType.equally,
    );

    final title = (map['title'] as String?)?.trim();
    final categoryName = (map['category'] as String?) ?? 'General';
    final inferred = DefaultCategories.byName(categoryName);
    final rawCategoryId = (map['categoryId'] as String?)?.trim();
    final rawSource = map['categorySource'] as String?;
    final rawIcon = (map['categoryIcon'] as String?)?.trim();

    return ExpenseModel(
      id: id,
      groupId: groupId,
      title: title != null && title.isNotEmpty ? title : 'Expense',
      category: categoryName,
      categoryId: (rawCategoryId != null && rawCategoryId.isNotEmpty)
          ? rawCategoryId
          : inferred?.id,
      categorySource: rawSource != null
          ? CategorySource.fromValue(rawSource)
          : (inferred != null ? CategorySource.defaultSource : null),
      categoryIcon: (rawIcon != null && rawIcon.isNotEmpty)
          ? rawIcon
          : inferred?.iconKey,
      amount: amount,
      currencyCode: (map['currencyCode'] as String?) ?? 'INR',
      currencySymbol: (map['currencySymbol'] as String?) ?? '₹',
      date: date,
      notes: map['notes'] as String?,
      paidBy: paidBy,
      splits: splits,
      splitType: splitType,
      participantIds: participantIds,
      createdBy: (map['createdBy'] as String?) ?? (paidBy.isNotEmpty ? paidBy.keys.first : ''),
      updatedBy: map['updatedBy'] as String?,
      deletedAt: deletedAt,
      deletedBy: map['deletedBy'] as String?,
      isDeleted: (map['isDeleted'] as bool?) ?? (deletedAt != null),
      receiptUrl: map['receiptUrl'] as String?,
      comments: _commentsFromMap(map['comments']),
    );
  }

  static List<ExpenseComment> _commentsFromMap(Object? raw) {
    if (raw is! Map) return const [];
    final comments = <ExpenseComment>[];
    for (final entry in raw.entries) {
      final value = entry.value;
      if (value is! Map) continue;
      final nested = Map<String, dynamic>.from(value);
      comments.add(
        ExpenseComment(
          id: entry.key.toString(),
          createdBy:
              (nested['createdBy'] as String?) ??
              (nested['created_by'] as String?) ??
              '',
          text: nested['text'] as String? ?? '',
          createdAt: _dateFrom(nested['createdAt'] ?? nested['created_at']) ??
              DateTime.now(),
        ),
      );
    }
    comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return comments;
  }

  static DateTime? _dateFrom(Object? raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return null;
  }

  /// Firestore payload for `Splitwise/expenses.{id}` map entries.
  ///
  /// `groupId` is persisted so callers can filter expenses by group.
  /// `paidBy`/`splits` stay as maps so readers can keep handling legacy
  /// single-payer expenses (`paidById`) alongside these.
  Map<String, dynamic> toMap({bool includeCreateAudit = true, String? updatedBy}) {
    final sanitizedPaidBy = <String, double>{};
    paidBy.forEach((key, value) {
      final id = key.trim();
      if (id.isEmpty) return;
      sanitizedPaidBy[id] = value;
    });

    final sanitizedSplits = <String, double>{};
    splits.forEach((key, value) {
      final id = key.trim();
      if (id.isEmpty) return;
      sanitizedSplits[id] = value;
    });

    final sanitizedParticipants = participantIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList();

    return {
      'id': id,
      'groupId': groupId,
      'title': title.trim(),
      'category': category,
      if (categoryId != null && categoryId!.isNotEmpty) 'categoryId': categoryId,
      if (categorySource != null) 'categorySource': categorySource!.value,
      if (categoryIcon != null && categoryIcon!.isNotEmpty)
        'categoryIcon': categoryIcon,
      'amount': amount,
      'currencyCode': currencyCode,
      'currencySymbol': currencySymbol,
      'date': Timestamp.fromDate(date),
      if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
      if (receiptUrl != null && receiptUrl!.trim().isNotEmpty) 'receiptUrl': receiptUrl!.trim(),
      'paidBy': sanitizedPaidBy,
      'splits': sanitizedSplits,
      'splitType': splitType.name,
      'participantIds': sanitizedParticipants,
      'createdBy': createdBy,
      if (includeCreateAudit) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
      'isDeleted': false,
      // comments are written only via addComment so a merge update does not wipe them
    };
  }
}
