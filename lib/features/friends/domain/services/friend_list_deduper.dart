import '../entities/user_preview.dart';

/// Deduplicates friend + pending rows so the same person never appears twice.
///
/// Prefer real friends over pending contacts. Matching is by user id first,
/// then by normalized email / phone when ids differ (e.g. pending shadow id
/// vs real account id after they signed up).
class FriendListDeduper {
  FriendListDeduper._();

  static String? _emailKey(UserPreview user) {
    final email = user.email?.trim().toLowerCase() ?? '';
    return email.isEmpty ? null : email;
  }

  static String? _phoneKey(UserPreview user) {
    final digits = (user.phone ?? '').replaceAll(RegExp(r'\D'), '');
    // Require enough digits to avoid collapsing unrelated short values.
    return digits.length >= 8 ? digits : null;
  }

  static List<UserPreview> merge({
    required List<UserPreview> friends,
    required List<UserPreview> pending,
  }) {
    final byId = <String, UserPreview>{};
    final emailToId = <String, String>{};
    final phoneToId = <String, String>{};

    void index(UserPreview user) {
      final email = _emailKey(user);
      if (email != null) emailToId[email] = user.id;
      final phone = _phoneKey(user);
      if (phone != null) phoneToId[phone] = user.id;
    }

    bool alreadyPresent(UserPreview user) {
      if (byId.containsKey(user.id)) return true;
      final email = _emailKey(user);
      if (email != null && emailToId.containsKey(email)) return true;
      final phone = _phoneKey(user);
      if (phone != null && phoneToId.containsKey(phone)) return true;
      return false;
    }

    // Real friendships win over pending invites.
    for (final friend in friends) {
      if (alreadyPresent(friend)) {
        // Same person under another id: keep the existing (already preferred) row.
        continue;
      }
      byId[friend.id] = friend;
      index(friend);
    }

    for (final contact in pending) {
      if (alreadyPresent(contact)) continue;
      byId[contact.id] = contact;
      index(contact);
    }

    return byId.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }
}
