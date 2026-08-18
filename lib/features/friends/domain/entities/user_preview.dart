import 'package:equatable/equatable.dart';

class UserPreview extends Equatable {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? photoUrl;
  final String friendCode;
  final bool isPending;

  const UserPreview({
    required this.id,
    required this.name,
    required this.friendCode,
    this.email,
    this.phone,
    this.photoUrl,
    this.isPending = false,
  });

  @override
  List<Object?> get props => [id, name, email, phone, photoUrl, friendCode, isPending];

  /// Email when present, otherwise phone. Null when neither is set.
  String? get contactLine {
    final mail = email?.trim() ?? '';
    if (mail.isNotEmpty) return mail;
    final tel = phone?.trim() ?? '';
    if (tel.isNotEmpty) return tel;
    return null;
  }
}
