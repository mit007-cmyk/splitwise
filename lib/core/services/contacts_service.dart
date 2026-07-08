import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:injectable/injectable.dart';
import 'package:splitwise/features/friends/domain/entities/phone_contact.dart';
import 'app_logger.dart';

@lazySingleton
class ContactsService {
  final AppLogger _logger;

  ContactsService(this._logger);

  Future<bool> requestPermission() async {
    return FlutterContacts.requestPermission(readonly: true);
  }

  Future<List<PhoneContact>> loadContacts() async {
    try {
      final granted = await requestPermission();
      if (!granted) return [];

      final rawContacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      final contacts = <PhoneContact>[];
      for (final contact in rawContacts) {
        final name = contact.displayName.trim();
        if (name.isEmpty) continue;

        final phone = contact.phones.isNotEmpty
            ? contact.phones.first.number.trim()
            : null;
        final email = contact.emails.isNotEmpty
            ? contact.emails.first.address.trim()
            : null;

        if ((phone == null || phone.isEmpty) && (email == null || email.isEmpty)) {
          continue;
        }

        contacts.add(
          PhoneContact(
            id: contact.id,
            displayName: name,
            phone: phone?.isNotEmpty == true ? phone : null,
            email: email?.isNotEmpty == true ? email : null,
          ),
        );
      }

      contacts.sort(
        (a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
      );
      return contacts;
    } catch (e, stackTrace) {
      _logger.e('Failed to load contacts', e, stackTrace);
      return [];
    }
  }
}
