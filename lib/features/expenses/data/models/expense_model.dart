import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/split_type.dart';

class ExpenseModel extends Expense {
  const ExpenseModel({
    required super.id,
    required super.groupId,
    required super.title,
    required super.category,
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
  });

  factory ExpenseModel.fromEntity(Expense expense) {
    return ExpenseModel(
      id: expense.id,
      groupId: expense.groupId,
      title: expense.title,
      category: expense.category,
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
    );
  }

  /// Rebuilds an [ExpenseModel] from a raw Firestore expense map.
  ///
  /// Supports both top-level `/expenses/{id}` docs and legacy
  /// `Splitwise/groups.{groupId}.expenses.{id}` nested maps. Tolerant of
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

    return ExpenseModel(
      id: id,
      groupId: groupId,
      title: title != null && title.isNotEmpty ? title : 'Expense',
      category: (map['category'] as String?) ?? 'General',
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
    );
  }

  /// Firestore payload for top-level `/expenses/{id}` documents.
  ///
  /// `groupId` is persisted so callers can query expenses by group.
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
      'deletedAt': FieldValue.delete(),
      'deletedBy': FieldValue.delete(),
    };
  }
}
