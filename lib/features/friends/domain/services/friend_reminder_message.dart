/// Builds the text Splitwise shares when nudging a friend about the balances
/// that are still outstanding between the two of them.
class FriendReminderMessage {
  FriendReminderMessage._();

  static String build({
    required String friendName,
    required int outstandingBalanceCount,
    required String inviteUrl,
  }) {
    final count = outstandingBalanceCount < 1 ? 1 : outstandingBalanceCount;
    final noun = count == 1 ? 'balance' : 'balances';
    return 'Hello ${firstNameOf(friendName)}! This is a reminder that we have '
        '$count outstanding $noun for expenses on Splitwise. Please follow '
        'this link to review our activity and settle up: $inviteUrl';
  }

  static String firstNameOf(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'there';
    return trimmed.split(RegExp(r'\s+')).first;
  }
}
