import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/user_entity.dart';

part 'user_model.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class UserModel extends UserEntity {
  const UserModel({
    required String id,
    required String email,
    required String name,
    String? photoUrl,
  }) : super(
          id: id,
          email: email,
          name: name,
          photoUrl: photoUrl,
        );

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  @override
  String toString() => jsonEncode(toJson());

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      name: entity.name,
      photoUrl: entity.photoUrl,
    );
  }
}
