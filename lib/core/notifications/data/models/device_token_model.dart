import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/device_token.dart';

part 'device_token_model.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class DeviceTokenModel extends DeviceToken {
  const DeviceTokenModel({
    required super.deviceId,
    required super.fcmToken,
    required super.platform,
    required super.appVersion,
    required super.isActive,
  });

  factory DeviceTokenModel.fromJson(Map<String, dynamic> json) =>
      _$DeviceTokenModelFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceTokenModelToJson(this);

  factory DeviceTokenModel.fromEntity(DeviceToken entity) {
    return DeviceTokenModel(
      deviceId: entity.deviceId,
      fcmToken: entity.fcmToken,
      platform: entity.platform,
      appVersion: entity.appVersion,
      isActive: entity.isActive,
    );
  }
}
