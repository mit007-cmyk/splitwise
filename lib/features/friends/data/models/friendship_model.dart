import 'package:json_annotation/json_annotation.dart';

part 'friendship_model.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class FriendshipModel {
  final String id;
  final List<String> userIds;

  const FriendshipModel({
    required this.id,
    required this.userIds,
  });

  factory FriendshipModel.fromJson(Map<String, dynamic> json) =>
      _$FriendshipModelFromJson(json);

  Map<String, dynamic> toJson() => _$FriendshipModelToJson(this);
}
