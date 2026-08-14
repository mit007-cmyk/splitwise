import 'package:equatable/equatable.dart';

enum ActivityEventType {
  expenseCreated('expense_created'),
  expenseUpdated('expense_updated'),
  expenseDeleted('expense_deleted'),
  expenseRestored('expense_restored'),
  groupCreated('group_created'),
  groupUpdated('group_updated'),
  groupDeleted('group_deleted'),
  groupRestored('group_restored'),
  friendAdded('friend_added'),
  friendRemoved('friend_removed'),
  memberJoinedGroup('member_joined_group'),
  memberLeftGroup('member_left_group'),
  settlementAdded('settlement_added'),
  settlementDeleted('settlement_deleted'),
  commentAdded('comment_added'),
  commentEdited('comment_edited'),
  commentDeleted('comment_deleted'),
  userBlocked('user_blocked'),
  userUnblocked('user_unblocked');

  final String value;
  const ActivityEventType(this.value);

  static ActivityEventType fromValue(String raw) {
    for (final type in ActivityEventType.values) {
      if (type.value == raw) return type;
    }
    return ActivityEventType.expenseUpdated;
  }
}

class ActivityEvent extends Equatable {
  final String id;
  final ActivityEventType type;
  final String entityType;
  final String entityId;
  final String? groupId;
  final String performedBy;
  final DateTime performedAt;
  final Map<String, dynamic> metadata;
  final Map<String, dynamic>? snapshotBefore;
  final Map<String, dynamic>? snapshotAfter;
  final List<String> changedFields;
  final List<String> visibilityUserIds;

  const ActivityEvent({
    required this.id,
    required this.type,
    required this.entityType,
    required this.entityId,
    this.groupId,
    required this.performedBy,
    required this.performedAt,
    this.metadata = const {},
    this.snapshotBefore,
    this.snapshotAfter,
    this.changedFields = const [],
    this.visibilityUserIds = const [],
  });

  @override
  List<Object?> get props => [
        id,
        type,
        entityType,
        entityId,
        groupId,
        performedBy,
        performedAt,
        metadata,
        snapshotBefore,
        snapshotAfter,
        changedFields,
        visibilityUserIds,
      ];
}

