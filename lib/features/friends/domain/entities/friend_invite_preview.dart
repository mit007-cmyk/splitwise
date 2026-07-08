import 'package:equatable/equatable.dart';
import 'friend_invite_resolution.dart';
import 'user_preview.dart';

class FriendInvitePreview extends Equatable {
  final UserPreview? user;
  final FriendInviteResolution resolution;
  final String? requestId;

  const FriendInvitePreview({
    required this.resolution,
    this.user,
    this.requestId,
  });

  @override
  List<Object?> get props => [user, resolution, requestId];
}
