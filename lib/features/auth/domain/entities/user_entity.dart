import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
  });

  @override
  List<Object?> get props => [id, email, name, photoUrl];

  /// Empty user placeholder (useful for unauthenticated state)
  static const empty = UserEntity(id: '', email: '', name: '');

  bool get isEmpty => this == UserEntity.empty;
  bool get isNotEmpty => this != UserEntity.empty;
}
