import 'dart:math';

/// Generates human-readable friend codes in the format `SPLT-XXXXXX`.
class FriendCodeGenerator {
  FriendCodeGenerator._();

  static const String prefix = 'SPLT-';
  static const int suffixLength = 6;

  /// Charset excludes ambiguous characters: 0/O, 1/I/L.
  static const String _charset = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';

  static final Random _random = Random.secure();

  /// Returns a new code such as `SPLT-A3K9X2`.
  static String generate() {
    final buffer = StringBuffer(prefix);
    for (var i = 0; i < suffixLength; i++) {
      buffer.write(_charset[_random.nextInt(_charset.length)]);
    }
    return buffer.toString();
  }

  /// Builds the shareable invite URL for a friend code.
  static String buildInviteUrl(String code, {String? baseUrl}) {
    final resolvedBase = baseUrl ?? AppFriendLinks.defaultInviteBaseUrl;
    final normalizedBase =
        resolvedBase.endsWith('/') ? resolvedBase.substring(0, resolvedBase.length - 1) : resolvedBase;
    return '$normalizedBase/add-friend?code=$code';
  }
}

/// Deep-link base URL for friend invites (App Links / universal links).
class AppFriendLinks {
  AppFriendLinks._();

  static const String defaultInviteBaseUrl = 'https://www.splitwise.com';
}
