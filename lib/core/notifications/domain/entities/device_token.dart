import 'package:equatable/equatable.dart';

class DeviceToken extends Equatable {
  final String deviceId;
  final String fcmToken;
  final String platform;
  final String appVersion;
  final bool isActive;

  const DeviceToken({
    required this.deviceId,
    required this.fcmToken,
    required this.platform,
    required this.appVersion,
    required this.isActive,
  });

  @override
  List<Object?> get props => [
        deviceId,
        fcmToken,
        platform,
        appVersion,
        isActive,
      ];
}
