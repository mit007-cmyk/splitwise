/// Share text used when inviting someone who is not on the app yet.
///
/// Matches the friend-code share line already used on the My code screen.
class FriendInviteMessage {
  FriendInviteMessage._();

  static String build({required String inviteUrl}) {
    return 'Add me on Splitwise: $inviteUrl';
  }
}
