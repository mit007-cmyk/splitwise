import 'package:equatable/equatable.dart';

enum FriendRequestStatus {
  pending,
  accepted,
  declined,
  cancelled;

  static FriendRequestStatus fromString(String value) {
    return FriendRequestStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => FriendRequestStatus.pending,
    );
  }
}

class FriendRequest extends Equatable {
  final String id;
  final String fromUserId;
  final String toUserId;
  final FriendRequestStatus status;
  final String? fromUserName;
  final String? fromUserPhotoUrl;

  const FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.status,
    this.fromUserName,
    this.fromUserPhotoUrl,
  });

  bool get isPending => status == FriendRequestStatus.pending;

  @override
  List<Object?> get props =>
      [id, fromUserId, toUserId, status, fromUserName, fromUserPhotoUrl];
}
