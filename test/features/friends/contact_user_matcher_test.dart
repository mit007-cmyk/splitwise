import 'package:flutter_test/flutter_test.dart';
import 'package:splitwise/features/friends/domain/entities/phone_contact.dart';
import 'package:splitwise/features/friends/domain/entities/user_preview.dart';
import 'package:splitwise/features/friends/domain/services/contact_user_matcher.dart';

void main() {
  const rahul = UserPreview(
    id: 'u1',
    name: 'Rahul Sharma',
    friendCode: 'SPLT-AAAAAA',
    email: 'rahul@gmail.com',
    phone: '+919876543210',
  );

  const pendingAmit = UserPreview(
    id: 'p1',
    name: 'Amit',
    friendCode: '',
    email: 'amit@gmail.com',
    isPending: true,
  );

  test('matches a registered user by +91 and local phone', () {
    const contact = PhoneContact(
      id: 'c1',
      displayName: 'Rahul',
      phone: '9876543210',
    );

    expect(
      ContactUserMatcher.registeredUserFor(
        contact: contact,
        registeredUsers: const [rahul],
      )?.id,
      'u1',
    );
  });

  test('matches by email and skips pending accounts by default', () {
    const contact = PhoneContact(
      id: 'c2',
      displayName: 'Amit',
      email: 'amit@gmail.com',
    );

    expect(
      ContactUserMatcher.registeredUserFor(
        contact: contact,
        registeredUsers: const [pendingAmit],
      ),
      isNull,
    );
    expect(
      ContactUserMatcher.registeredUserFor(
        contact: contact,
        registeredUsers: const [pendingAmit],
        skipPending: false,
      )?.id,
      'p1',
    );
  });

  test('formats Indian numbers with a plus prefix', () {
    expect(
      ContactUserMatcher.formatPhoneForDisplay('916355517262'),
      '+916355517262',
    );
  });
}
