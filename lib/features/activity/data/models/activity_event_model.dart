import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/activity_event.dart';

class ActivityEventModel extends ActivityEvent {
  const ActivityEventModel({
    required super.id,
    required super.type,
    required super.entityType,
    required super.entityId,
    super.groupId,
    required super.performedBy,
    required super.performedAt,
    super.metadata,
    super.snapshotBefore,
    super.snapshotAfter,
    super.changedFields,
    super.visibilityUserIds,
  });

  factory ActivityEventModel.fromFirestore(
    String id,
    Map<String, dynamic> map,
  ) {
    final ts = map['performedAt'];
    return ActivityEventModel(
      id: id,
      type: ActivityEventType.fromValue((map['type'] as String?) ?? ''),
      entityType: (map['entityType'] as String?) ?? '',
      entityId: (map['entityId'] as String?) ?? '',
      groupId: map['groupId'] as String?,
      performedBy: (map['performedBy'] as String?) ?? '',
      performedAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      metadata: map['metadata'] is Map
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : const {},
      snapshotBefore: map['snapshotBefore'] is Map
          ? Map<String, dynamic>.from(map['snapshotBefore'] as Map)
          : null,
      snapshotAfter: map['snapshotAfter'] is Map
          ? Map<String, dynamic>.from(map['snapshotAfter'] as Map)
          : null,
      changedFields: map['changedFields'] is List
          ? List<String>.from(map['changedFields'] as List)
          : const [],
      visibilityUserIds: map['visibilityUserIds'] is List
          ? List<String>.from(map['visibilityUserIds'] as List)
          : const [],
    );
  }
}

