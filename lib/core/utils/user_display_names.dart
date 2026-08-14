import '../constants/app_constants.dart';
import '../services/firestore_service.dart';

/// Builds a `userId -> display name` map from Firestore sources.
/// Never returns truncated Firebase / UUID ids as names.
class UserDisplayNames {
  UserDisplayNames._();

  static bool looksLikeRawId(String? value, String userId) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return true;
    if (name == userId) return true;
    if (name.toLowerCase() == 'unknown') return true;
    // Truncated-id fallbacks like "e09a4" from substring(0, 5).
    if (userId.startsWith(name) && name.length <= 8 && !name.contains(' ')) {
      return true;
    }
    return false;
  }

  static String sanitize(String userId, String? rawName) {
    if (!looksLikeRawId(rawName, userId)) return rawName!.trim();
    return 'Splitwise user';
  }

  /// Loads names from `Splitwise/users` and pending contact display names.
  static Future<Map<String, String>> load(FirestoreService firestore) async {
    final names = <String, String>{};

    try {
      final usersDoc = await firestore.getDocument(
        FirestorePaths.root,
        FirestorePaths.users,
      );
      final usersData = usersDoc.data();
      if (usersData != null) {
        for (final entry in usersData.entries) {
          if (entry.value is! Map) continue;
          final map = Map<String, dynamic>.from(entry.value as Map);
          final userId = entry.key;
          final rawName = map['name'] as String?;
          final email = map['email'] as String?;
          if (!looksLikeRawId(rawName, userId)) {
            names[userId] = rawName!.trim();
          } else if (email != null && email.contains('@')) {
            names[userId] = email.split('@').first;
          } else {
            names[userId] = 'Splitwise user';
          }
        }
      }
    } catch (_) {}

    try {
      final pendingDoc = await firestore.getDocument(
        FirestorePaths.root,
        FirestorePaths.pendingContacts,
      );
      final pendingData = pendingDoc.data();
      if (pendingData != null) {
        for (final entry in pendingData.entries) {
          if (entry.value is! Map) continue;
          final map = Map<String, dynamic>.from(entry.value as Map);
          final id = (map['id'] as String?) ?? entry.key;
          final displayName = (map['displayName'] as String?)?.trim();
          if (displayName == null || displayName.isEmpty) continue;
          // Pending display names fill gaps and can upgrade raw placeholders.
          if (!names.containsKey(id) || looksLikeRawId(names[id], id)) {
            names[id] = displayName;
          }
        }
      }
    } catch (_) {}

    return names;
  }

  static String resolve(Map<String, String> names, String userId) {
    return sanitize(userId, names[userId]);
  }
}
