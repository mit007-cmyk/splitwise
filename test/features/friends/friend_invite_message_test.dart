import 'package:flutter_test/flutter_test.dart';
import 'package:splitwise/features/friends/domain/services/friend_invite_message.dart';

void main() {
  test('uses the existing friend-code share format', () {
    expect(
      FriendInviteMessage.build(
        inviteUrl: 'https://www.splitwise.com/add-friend?code=SPLT-A3K9X2',
      ),
      'Add me on Splitwise: https://www.splitwise.com/add-friend?code=SPLT-A3K9X2',
    );
  });
}
