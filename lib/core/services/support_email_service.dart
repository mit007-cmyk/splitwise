import 'dart:io';

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';
import 'app_logger.dart';
import 'hive_service.dart';

@lazySingleton
class SupportEmailService {
  SupportEmailService(this._hiveService, this._logger);

  static const _platform = MethodChannel('com.example.splitwise/settings');

  final HiveService _hiveService;
  final AppLogger _logger;

  Future<void> composeSupportEmail({
    required String userEmail,
    required String userId,
  }) async {
    final supportCode = await _resolveSupportCode(userId);
    final deviceInfo = await _readDeviceInfo();
    final appVersion = await _appVersionLabel();
    final subject =
        Platform.isIOS ? 'Splitwise for iOS' : 'Splitwise for Android';

    final body = [
      'Email: $userEmail',
      'Support code: $supportCode',
      'Device: ${deviceInfo.device}',
      'Operating System: ${deviceInfo.operatingSystem}',
      'App Version: $appVersion',
    ].join('\n');

    final uri = Uri(
      scheme: 'mailto',
      path: AppConstants.supportEmail,
      query: _encodeQuery({
        'subject': subject,
        'body': body,
      }),
    );

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      throw Exception('No email app available');
    }
  }

  Future<String> _resolveSupportCode(String userId) async {
    final cached = _hiveService.get<String>(
      AppConstants.hiveSettingsBox,
      AppConstants.hiveSupportCodeKey,
    );
    if (cached != null && cached.isNotEmpty) return cached;

    final code = _generateSupportCode(userId);
    await _hiveService.put(
      AppConstants.hiveSettingsBox,
      AppConstants.hiveSupportCodeKey,
      code,
    );
    return code;
  }

  String _generateSupportCode(String userId) {
    if (userId.isEmpty) return 'S-UNKNOWN0';
    final hash = userId.hashCode.toUnsigned(32).toRadixString(16).toUpperCase();
    final suffix = hash.padLeft(8, '0');
    return 'S-${suffix.substring(suffix.length - 8)}';
  }

  Future<({String device, String operatingSystem})> _readDeviceInfo() async {
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        final result =
            await _platform.invokeMethod<Map<Object?, Object?>>(
          'getSupportDeviceInfo',
        );
        if (result != null) {
          return (
            device: result['device'] as String? ?? 'Unknown device',
            operatingSystem: result['operatingSystem'] as String? ??
                Platform.operatingSystemVersion,
          );
        }
      } on PlatformException catch (e) {
        _logger.w('Native device info unavailable: ${e.message}');
      } catch (e) {
        _logger.w('Native device info unavailable: $e');
      }
    }

    return (
      device: 'Unknown device',
      operatingSystem: Platform.operatingSystemVersion,
    );
  }

  Future<String> _appVersionLabel() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return '${packageInfo.version} ${packageInfo.buildNumber}';
    } catch (e) {
      _logger.w('Package info unavailable, using fallback version: $e');
      return '${AppConstants.appVersion} 1';
    }
  }

  String _encodeQuery(Map<String, String> parameters) {
    return parameters.entries
        .map(
          (entry) =>
              '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value)}',
        )
        .join('&');
  }
}
