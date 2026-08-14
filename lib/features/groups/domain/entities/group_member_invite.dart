import 'package:equatable/equatable.dart';
import 'package:splitwise/features/auth/data/models/user_model.dart';
import 'package:splitwise/features/friends/domain/entities/phone_contact.dart';

class GroupMemberInvite extends Equatable {
  final String key;
  final String displayName;
  final String? email;
  final String? phone;
  final String? photoUrl;
  final String? userId;

  const GroupMemberInvite({
    required this.key,
    required this.displayName,
    this.email,
    this.phone,
    this.photoUrl,
    this.userId,
  });

  factory GroupMemberInvite.fromUser(UserModel user) {
    return GroupMemberInvite(
      key: user.id,
      displayName: user.name,
      email: user.email.contains('@') ? user.email : null,
      phone: user.email.contains('@') ? null : user.email,
      photoUrl: user.photoUrl,
      userId: user.id,
    );
  }

  factory GroupMemberInvite.fromContact(PhoneContact contact) {
    return GroupMemberInvite(
      key: 'contact:${contact.id}',
      displayName: contact.displayName,
      email: contact.email,
      phone: contact.phone,
    );
  }

  factory GroupMemberInvite.manual({
    required String displayName,
    String? email,
    String? phone,
  }) {
    return GroupMemberInvite(
      key: 'manual:${DateTime.now().microsecondsSinceEpoch}',
      displayName: displayName,
      email: email,
      phone: phone,
    );
  }

  bool get isRegistered => userId != null && userId!.isNotEmpty;

  String get shortLabel {
    final name = displayName.trim();
    if (name.startsWith('+')) {
      return name.split(RegExp(r'\s+')).first;
    }
    if (name.isNotEmpty) return name.split(' ').first;
    final number = (phone ?? '').trim();
    if (number.startsWith('+')) {
      return number.split(RegExp(r'\s+')).first;
    }
    return name.isNotEmpty ? name : 'Invite';
  }

  String get subtitle {
    if (phone != null && phone!.trim().isNotEmpty) return phone!.trim();
    if (email != null && email!.trim().isNotEmpty) return email!.trim();
    return '';
  }

  String get reviewSubtitle {
    final number = phone?.trim() ?? '';
    if (number.isEmpty) return email?.trim() ?? '';
    final flag = countryFlagForPhone(number);
    final compact = number.replaceAll(' ', '');
    return flag == null ? compact : '$flag $compact';
  }

  GroupMemberInvite copyWith({
    String? displayName,
    String? email,
    String? phone,
    String? photoUrl,
    String? userId,
  }) {
    return GroupMemberInvite(
      key: key,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      userId: userId ?? this.userId,
    );
  }

  @override
  List<Object?> get props => [key, displayName, email, phone, photoUrl, userId];
}

String? countryFlagForPhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('91')) return '🇮🇳';
  if (digits.startsWith('1')) return '🇺🇸';
  if (digits.startsWith('44')) return '🇬🇧';
  if (digits.startsWith('61')) return '🇦🇺';
  if (digits.startsWith('971')) return '🇦🇪';
  return null;
}
