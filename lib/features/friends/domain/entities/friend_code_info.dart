import 'package:equatable/equatable.dart';

class FriendCodeInfo extends Equatable {
  final String code;
  final int version;
  final String inviteUrl;
  final String userName;
  final String? photoUrl;

  const FriendCodeInfo({
    required this.code,
    required this.version,
    required this.inviteUrl,
    required this.userName,
    this.photoUrl,
  });

  @override
  List<Object?> get props => [code, version, inviteUrl, userName, photoUrl];
}
