import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/services/friend_invite_message.dart';

/// Sends an invite via SMS when a phone is present, otherwise email, then
/// the system share sheet. Does not depend on a custom SMS gateway.
class FriendInviteSender {
  FriendInviteSender._();

  static Future<void> send({
    required String inviteUrl,
    String? phone,
    String? email,
  }) async {
    final message = FriendInviteMessage.build(inviteUrl: inviteUrl);
    final smsNumber = _smsNumber(phone);
    if (smsNumber != null) {
      final smsUri = Uri(
        scheme: 'sms',
        path: smsNumber,
        queryParameters: {'body': message},
      );
      final launched = await launchUrl(
        smsUri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return;
    }

    final mail = email?.trim() ?? '';
    if (mail.contains('@')) {
      final mailUri = Uri(
        scheme: 'mailto',
        path: mail,
        queryParameters: {
          'subject': 'Add me on Splitwise',
          'body': message,
        },
      );
      final launched = await launchUrl(
        mailUri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return;
    }

    await Share.share(message, subject: 'Add me on Splitwise');
  }

  static String? _smsNumber(String? phone) {
    final digits = (phone ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8) return null;
    if ((phone ?? '').trim().startsWith('+')) return '+$digits';
    if (digits.startsWith('91') && digits.length >= 12) return '+$digits';
    return digits;
  }
}
