import 'friend_code_generator.dart';

/// Extracts a `SPLT-XXXXXX` friend code from raw text or invite URLs.
class FriendCodeParser {
  FriendCodeParser._();

  static final RegExp _codePattern = RegExp(
    r'SPLT-[23456789ABCDEFGHJKMNPQRSTUVWXYZ]{6}',
    caseSensitive: false,
  );

  /// Returns a normalized friend code, or `null` if none found.
  static String? parse(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    final uri = Uri.tryParse(trimmed);
    final queryCode = uri?.queryParameters['code'];
    if (queryCode != null && queryCode.isNotEmpty) {
      final fromQuery = _normalize(queryCode);
      if (fromQuery != null) return fromQuery;
    }

    final match = _codePattern.firstMatch(trimmed.toUpperCase());
    return match?.group(0);
  }

  static String? _normalize(String value) {
    final upper = value.trim().toUpperCase();
    if (_codePattern.hasMatch(upper)) {
      return _codePattern.firstMatch(upper)?.group(0);
    }
    if (upper.startsWith(FriendCodeGenerator.prefix)) {
      final match = _codePattern.firstMatch(upper);
      return match?.group(0);
    }
    return null;
  }
}
