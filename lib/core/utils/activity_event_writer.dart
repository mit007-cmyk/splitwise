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
    transaction.set(
      eventsRef,
      {eventId: _withReadFlags(eventData)},
      SetOptions(merge: true),
    );
  }

  /// Per-user unread flags. The actor is already "seen"; everyone else in
  /// [visibilityUserIds] starts unread so their Activity row stays highlighted.
  static Map<String, dynamic> _withReadFlags(Map<String, dynamic> eventData) {
    if (eventData['isRead'] is Map) return eventData;
    final visibility = eventData['visibilityUserIds'] is List
        ? List<String>.from(eventData['visibilityUserIds'] as List)
            .map((id) => id.toString().trim())
            .where((id) => id.isNotEmpty)
            .toList()
        : const <String>[];
    final actor = (eventData['performedBy'] as String?)?.trim() ?? '';
    return {
      ...eventData,
      'isRead': <String, bool>{
        for (final id in visibility) id: id == actor,
      },
    };
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

  /// Private to the blocker — the blocked user never sees this.
  static Map<String, dynamic> userBlocked({
    required String actorUserId,
    required String blockedUserId,
    required String blockedUserName,
  }) {
    return {
      'type': 'user_blocked',
      'entityType': 'user',
      'entityId': blockedUserId,
      'groupId': null,
      'performedBy': actorUserId,
      'performedAt': FieldValue.serverTimestamp(),
      'metadata': {
        'blockedUserId': blockedUserId,
        'blockedUserName': blockedUserName,
      },
      'changedFields': const <String>[],
      'visibilityUserIds': [actorUserId],
    };
  }

  /// Private to the actor — the unblocked user is not notified.
  static Map<String, dynamic> userUnblocked({
    required String actorUserId,
    required String unblockedUserId,
    required String unblockedUserName,
  }) {
    return {
      'type': 'user_unblocked',
      'entityType': 'user',
      'entityId': unblockedUserId,
      'groupId': null,
      'performedBy': actorUserId,
      'performedAt': FieldValue.serverTimestamp(),
      'metadata': {
        'unblockedUserId': unblockedUserId,
        'unblockedUserName': unblockedUserName,
      },
      'changedFields': const <String>[],
      'visibilityUserIds': [actorUserId],
    };
  }

  /// One event per added member: "You added Nupul K. to the group Test."
  static Map<String, dynamic> memberAddedToGroup({
    required String groupId,
    required String groupName,
    required String actorUserId,
    required String memberUserId,
    required String memberName,
    required List<String> visibilityUserIds,
    bool invited = false,
  }) {
    final joinKind = memberUserId == actorUserId
        ? 'joined'
        : (invited ? 'invited' : 'added');
    return {
      'type': 'member_joined_group',
      'entityType': 'group',
      'entityId': groupId,
      'groupId': groupId,
      'performedBy': actorUserId,
      'performedAt': FieldValue.serverTimestamp(),
      'metadata': {
        'groupName': groupName,
        'memberUserId': memberUserId,
        'memberName': memberName,
        'joinKind': joinKind,
      },
      'changedFields': const <String>[],
      'visibilityUserIds': visibilityUserIds,
    };
  }

  /// [removed] is true when someone else was taken out of the group.
  static Map<String, dynamic> memberLeftGroup({
    required String groupId,
    required String groupName,
    required String actorUserId,
    required String memberUserId,
    required String memberName,
    required List<String> visibilityUserIds,
    required bool removed,
  }) {
    return {
      'type': 'member_left_group',
      'entityType': 'group',
      'entityId': groupId,
      'groupId': groupId,
      'performedBy': actorUserId,
      'performedAt': FieldValue.serverTimestamp(),
      'metadata': {
        'groupName': groupName,
        'memberUserId': memberUserId,
        'memberName': memberName,
        'joinKind': removed ? 'removed' : 'left',
      },
      'changedFields': const <String>[],
      'visibilityUserIds': visibilityUserIds,
    };
  }

  static Map<String, dynamic> groupUpdated({
    required String groupId,
    required String actorUserId,
    required String groupName,
    required List<String> visibilityUserIds,
    String? previousGroupName,
    List<String> changedFields = const [],
    Map<String, dynamic> extraMetadata = const {},
  }) {
    return {
      'type': 'group_updated',
      'entityType': 'group',
      'entityId': groupId,
      'groupId': groupId,
      'performedBy': actorUserId,
      'performedAt': FieldValue.serverTimestamp(),
      'metadata': {
        'groupName': groupName,
        if (previousGroupName != null) 'previousGroupName': previousGroupName,
        ...extraMetadata,
      },
      'changedFields': changedFields,
      'visibilityUserIds': visibilityUserIds,
    };
  }

  static Map<String, dynamic> friendAdded({
    required String actorUserId,
    required String friendUserId,
    required String friendName,
  }) {
    return {
      'type': 'friend_added',
      'entityType': 'friend',
      'entityId': friendUserId,
      'groupId': null,
      'performedBy': actorUserId,
      'performedAt': FieldValue.serverTimestamp(),
      'metadata': {
        'friendUserId': friendUserId,
        'friendName': friendName,
      },
      'changedFields': const <String>[],
      'visibilityUserIds': [actorUserId, friendUserId],
    };
  }

  static Map<String, dynamic> friendRemoved({
    required String actorUserId,
    required String friendUserId,
    required String friendName,
  }) {
    return {
      'type': 'friend_removed',
      'entityType': 'friend',
      'entityId': friendUserId,
      'groupId': null,
      'performedBy': actorUserId,
      'performedAt': FieldValue.serverTimestamp(),
      'metadata': {
        'friendUserId': friendUserId,
        'friendName': friendName,
      },
      'changedFields': const <String>[],
      'visibilityUserIds': [actorUserId, friendUserId],
    };
  }

  static Map<String, dynamic> friendRequestSent({
    required String actorUserId,
    required String friendUserId,
    required String friendName,
  }) {
    return {
      'type': 'friend_request_sent',
      'entityType': 'friend',
      'entityId': friendUserId,
      'groupId': null,
      'performedBy': actorUserId,
      'performedAt': FieldValue.serverTimestamp(),
      'metadata': {
        'friendUserId': friendUserId,
        'friendName': friendName,
      },
      'changedFields': const <String>[],
      'visibilityUserIds': [actorUserId, friendUserId],
    };
  }

  static Map<String, dynamic> friendRequestAccepted({
    required String actorUserId,
    required String friendUserId,
    required String friendName,
  }) {
    return {
      'type': 'friend_request_accepted',
      'entityType': 'friend',
      'entityId': friendUserId,
      'groupId': null,
      'performedBy': actorUserId,
      'performedAt': FieldValue.serverTimestamp(),
      'metadata': {
        'friendUserId': friendUserId,
        'friendName': friendName,
      },
      'changedFields': const <String>[],
      'visibilityUserIds': [actorUserId, friendUserId],
    };
  }

  static Future<void> appendDirect(
    FirebaseFirestore firestore,
    Map<String, dynamic> eventData,
  ) async {
    final eventId = _uuid.v4();
    await eventsRef(firestore).set(
      {eventId: _withReadFlags(eventData)},
      SetOptions(merge: true),
    );
  }
}
