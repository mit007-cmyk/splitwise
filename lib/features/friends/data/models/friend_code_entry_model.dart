import 'package:json_annotation/json_annotation.dart';

part 'friend_code_entry_model.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class FriendCodeEntryModel {
  final String userId;
  final bool isActive;
  final int version;

  const FriendCodeEntryModel({
    required this.userId,
    required this.isActive,
    required this.version,
  });

  factory FriendCodeEntryModel.fromJson(Map<String, dynamic> json) =>
      _$FriendCodeEntryModelFromJson(json);

  Map<String, dynamic> toJson() => _$FriendCodeEntryModelToJson(this);
}
