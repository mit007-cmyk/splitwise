import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_constants.dart';
import '../services/app_logger.dart';
import '../services/hive_service.dart';

abstract class DeviceIdentityStore {
  Future<String> getOrCreateDeviceId();
  String currentPlatform();
  Future<String> appVersion();
}

@LazySingleton(as: DeviceIdentityStore)
class DeviceIdentityStoreImpl implements DeviceIdentityStore {
  DeviceIdentityStoreImpl(this._hiveService, this._logger);

  final HiveService _hiveService;
  final AppLogger _logger;
  final Uuid _uuid = const Uuid();

  @override
  Future<String> getOrCreateDeviceId() async {
    try {
      final existing = _hiveService.get<String>(
        AppConstants.hiveSettingsBox,
        AppConstants.hiveDeviceIdKey,
      );
      if (existing != null && existing.isNotEmpty) {
        return existing;
      }

      final deviceId = _uuid.v4();
      await _hiveService.put(
        AppConstants.hiveSettingsBox,
        AppConstants.hiveDeviceIdKey,
        deviceId,
      );
      return deviceId;
    } catch (e, stackTrace) {
      _logger.e('Failed to persist installation device id', e, stackTrace);
      return _uuid.v4();
    }
  }

  @override
  String currentPlatform() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  @override
  Future<String> appVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (info.version.isNotEmpty) return info.version;
    } catch (e, stackTrace) {
      _logger.e('Failed to read app version', e, stackTrace);
    }
    return AppConstants.appVersion;
  }
}
