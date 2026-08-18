import 'package:flutter_test/flutter_test.dart';
import 'package:splitwise/features/friends/domain/entities/user_preview.dart';

void main() {
  group('UserPreview.contactLine', () {
    test('prefers email when both are present', () {
      const friend = UserPreview(
        id: '1',
        name: 'Dhamo',
        friendCode: 'SPLT-AAAAAA',
        email: 'lakhanidharm39@gmail.com',
        phone: '+91 99999 00000',
      );
      expect(friend.contactLine, 'lakhanidharm39@gmail.com');
    });

    test('falls back to phone when email is missing', () {
      const friend = UserPreview(
        id: '1',
        name: 'Dhamo',
        friendCode: 'SPLT-AAAAAA',
        phone: '+91 99999 00000',
      );
      expect(friend.contactLine, '+91 99999 00000');
    });

    test('is null when neither email nor phone is set', () {
      const friend = UserPreview(
        id: '1',
        name: 'Dhamo',
        friendCode: 'SPLT-AAAAAA',
      );
      expect(friend.contactLine, isNull);
    });
  });
}
