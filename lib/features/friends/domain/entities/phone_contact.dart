import 'package:equatable/equatable.dart';

class PhoneContact extends Equatable {
  final String id;
  final String displayName;
  final String? phone;
  final String? email;

  const PhoneContact({
    required this.id,
    required this.displayName,
    this.phone,
    this.email,
  });

  String get subtitle => phone ?? email ?? '';

  @override
  List<Object?> get props => [id, displayName, phone, email];
}
