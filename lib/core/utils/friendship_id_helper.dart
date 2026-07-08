/// Builds deterministic friendship IDs from two user IDs (sorted alphabetically).
class FriendshipIdHelper {
  FriendshipIdHelper._();

  static String forUsers(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  static List<String> sortedUserIds(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return ids;
  }

  static String? otherUserId(List<String> userIds, String currentUserId) {
    if (userIds.length != 2) return null;
    if (userIds[0] == currentUserId) return userIds[1];
    if (userIds[1] == currentUserId) return userIds[0];
    return null;
  }
}
