import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/friend_request.dart';

part 'friend_request_model.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class FriendRequestModel {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String status;

  const FriendRequestModel({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.status,
  });

  factory FriendRequestModel.fromJson(Map<String, dynamic> json) =>
      _$FriendRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$FriendRequestModelToJson(this);

  FriendRequest toEntity({
    String? fromUserName,
    String? fromUserPhotoUrl,
  }) {
    return FriendRequest(
      id: id,
      fromUserId: fromUserId,
      toUserId: toUserId,
      status: FriendRequestStatus.fromString(status),
      fromUserName: fromUserName,
      fromUserPhotoUrl: fromUserPhotoUrl,
    );
  }
}
