import '../entities/phone_contact.dart';
import '../entities/user_preview.dart';

/// Matches on-device contacts to registered app users without uploading
/// the address book. Email is compared case-insensitively; phones use the
/// last 10 digits so `+91` and local numbers still match.
class ContactUserMatcher {
  ContactUserMatcher._();

  static String? phoneKey(String? raw) {
    final digits = (raw ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8) return null;
    return digits.length > 10 ? digits.substring(digits.length - 10) : digits;
  }

  static String? emailKey(String? raw) {
    final email = raw?.trim().toLowerCase() ?? '';
    return email.contains('@') ? email : null;
  }

  static String formatPhoneForDisplay(String? raw) {
    final trimmed = raw?.trim() ?? '';
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return trimmed;
    if (trimmed.startsWith('+')) {
      return '+$digits';
    }
    if (digits.startsWith('91') && digits.length >= 12) {
      return '+$digits';
    }
    return '+$digits';
  }

  static UserPreview? registeredUserFor({
    required PhoneContact contact,
    required List<UserPreview> registeredUsers,
    bool skipPending = true,
  }) {
    return registeredUserForEmailPhone(
      email: contact.email,
      phone: contact.phone,
      registeredUsers: registeredUsers,
      skipPending: skipPending,
    );
  }

  static UserPreview? registeredUserForEmailPhone({
    String? email,
    String? phone,
    required List<UserPreview> registeredUsers,
    bool skipPending = true,
  }) {
    final emailKey = ContactUserMatcher.emailKey(email);
    final phoneKey = ContactUserMatcher.phoneKey(phone);
    for (final user in registeredUsers) {
      if (skipPending && user.isPending) continue;
      final userEmail = ContactUserMatcher.emailKey(user.email);
      if (emailKey != null && userEmail == emailKey) return user;
      final userPhone =
          ContactUserMatcher.phoneKey(user.phone) ??
          ContactUserMatcher.phoneKey(user.email);
      if (phoneKey != null && userPhone == phoneKey) return user;
    }
    return null;
  }
}
