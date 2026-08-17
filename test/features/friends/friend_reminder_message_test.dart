import 'package:flutter_test/flutter_test.dart';
import 'package:splitwise/features/friends/domain/services/friend_reminder_message.dart';

void main() {
  const inviteUrl = 'https://www.splitwise.com/add-friend?code=SPLT-A3K9X2';

  group('FriendReminderMessage', () {
    test('uses the friend first name and pluralises the balance count', () {
      expect(
        FriendReminderMessage.build(
          friendName: 'Nupul Kukadiya',
          outstandingBalanceCount: 2,
          inviteUrl: inviteUrl,
        ),
        'Hello Nupul! This is a reminder that we have 2 outstanding balances '
        'for expenses on Splitwise. Please follow this link to review our '
        'activity and settle up: $inviteUrl',
      );
    });

    test('uses the singular noun for a single balance', () {
      expect(
        FriendReminderMessage.build(
          friendName: 'Nupul',
          outstandingBalanceCount: 1,
          inviteUrl: inviteUrl,
        ),
        contains('we have 1 outstanding balance for expenses'),
      );
    });

    test('falls back to a generic greeting when the name is blank', () {
      expect(
        FriendReminderMessage.build(
          friendName: '   ',
          outstandingBalanceCount: 3,
          inviteUrl: inviteUrl,
        ),
        startsWith('Hello there!'),
      );
    });
  });
}
