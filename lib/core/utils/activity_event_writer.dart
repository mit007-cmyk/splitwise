import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_constants.dart';

/// Writes immutable audit events to `Splitwise/events`.
class ActivityEventWriter {
  ActivityEventWriter._();

  static const _uuid = Uuid();

  static DocumentReference<Map<String, dynamic>> eventsRef(
    FirebaseFirestore firestore,
  ) {
    return firestore.collection(FirestorePaths.root).doc(FirestorePaths.events);
  }

  static void append(
    Transaction transaction,
    DocumentReference<Map<String, dynamic>> eventsRef,
    Map<String, dynamic> eventData,
  ) {
    final eventId = _uuid.v4();
    transaction.set(eventsRef, {eventId: eventData}, SetOptions(merge: true));
  }

  static List<String> memberIdsFromGroup(Map<String, dynamic> groupData) {
    if (groupData['members'] is! List) return const [];
    return List<String>.from(groupData['members'] as List)
        .map((id) => id.toString().trim())
        .where((id) => id.isNotEmpty)
        .toList();
  }

  static Map<String, dynamic> groupCreated({
    required String groupId,
    required Map<String, dynamic> groupData,
  }) {
    final memberIds = memberIdsFromGroup(groupData);
    final actorUserId = (groupData['createdBy'] as String?)?.trim() ??
        (memberIds.isNotEmpty ? memberIds.first : '');
    final groupName = (groupData['name'] as String?) ?? 'Unnamed Group';

    return {
      'type': 'group_created',
      'entityType': 'group',
      'entityId': groupId,
      'groupId': groupId,
      'performedBy': actorUserId,
      'performedAt': FieldValue.serverTimestamp(),
      'metadata': {
        'groupName': groupName,
        'groupType': groupData['type'],
        'memberCount': memberIds.length,
      },
      'snapshotAfter': groupData,
      'changedFields': const <String>[],
      'visibilityUserIds': memberIds,
    };
  }

  static Map<String, dynamic> groupDeleted({
    required String groupId,
    required Map<String, dynamic> groupData,
    required String actorUserId,
  }) {
    final memberIds = memberIdsFromGroup(groupData);
    final groupName = (groupData['name'] as String?) ?? 'Unnamed Group';

    return {
      'type': 'group_deleted',
      'entityType': 'group',
      'entityId': groupId,
      'groupId': groupId,
      'performedBy': actorUserId,
      'performedAt': FieldValue.serverTimestamp(),
      'metadata': {
        'groupName': groupName,
        'groupType': groupData['type'],
        'memberCount': memberIds.length,
      },
      'snapshotBefore': groupData,
      'changedFields': const <String>[],
      'visibilityUserIds': memberIds,
    };
  }
}
