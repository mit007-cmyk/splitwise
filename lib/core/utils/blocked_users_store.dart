import '../constants/app_constants.dart';
import '../services/firestore_service.dart';

/// One-way blocks stored on `Splitwise/blocked_users.{ownerId}_{blockedUserId}`.
class BlockedUsersStore {
  BlockedUsersStore._();

  static String blockId(String ownerId, String blockedUserId) =>
      '${ownerId}_$blockedUserId';

  static Future<Set<String>> idsBlockedBy(
    FirestoreService firestore,
    String ownerId,
  ) async {
    final names = await namesBlockedBy(firestore, ownerId);
    return names.keys.toSet();
  }

  /// Returns `blockedUserId -> display name` for everyone [ownerId] has blocked.
  /// Names come from the block record when present, otherwise a placeholder.
  static Future<Map<String, String>> namesBlockedBy(
    FirestoreService firestore,
    String ownerId,
  ) async {
    final doc = await firestore.getDocument(
      FirestorePaths.root,
      FirestorePaths.blockedUsers,
    );
    final data = doc.data();
    if (data == null) return {};

    final names = <String, String>{};
    for (final entry in data.entries) {
      if (entry.value is! Map) continue;
      final map = Map<String, dynamic>.from(entry.value as Map);
      if ((map['ownerId'] as String?) != ownerId) continue;
      final blockedId = map['blockedUserId'] as String?;
      if (blockedId == null || blockedId.isEmpty) continue;
      final storedName = (map['blockedUserName'] as String?)?.trim();
      names[blockedId] =
          (storedName != null && storedName.isNotEmpty) ? storedName : 'Blocked user';
    }
    return names;
  }
}
