import 'package:injectable/injectable.dart';
import 'package:local_auth/local_auth.dart';
import '../constants/app_constants.dart';
import 'app_logger.dart';
import 'hive_service.dart';

@lazySingleton
class BiometricLockService {
  static const String enabledKey = 'biometrics_enabled';
  static const String timeoutKey = 'biometrics_timeout';
  static const String lastUnlockKey = 'biometrics_last_unlock_at';

  final HiveService _hiveService;
  final AppLogger _logger;
  final LocalAuthentication _localAuth;

  BiometricLockService(this._hiveService, this._logger)
      : _localAuth = LocalAuthentication();

  bool isEnabled() =>
      _hiveService.get<bool>(AppConstants.hiveSettingsBox, enabledKey) ?? false;

  int getTimeoutSeconds() {
    final label =
        _hiveService.get<String>(AppConstants.hiveSettingsBox, timeoutKey) ?? '5 seconds';
    return timeoutLabelToSeconds(label);
  }

  bool shouldRequireAuth() {
    if (!isEnabled()) return false;

    final lastUnlockMs = _hiveService.get<int>(AppConstants.hiveSettingsBox, lastUnlockKey);
    if (lastUnlockMs == null) return true;

    final elapsedSeconds = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(lastUnlockMs))
        .inSeconds;
    return elapsedSeconds >= getTimeoutSeconds();
  }

  Future<void> recordUnlock() async {
    await _hiveService.put(
      AppConstants.hiveSettingsBox,
      lastUnlockKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<bool> authenticate() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final canAuthenticate = canCheckBiometrics || await _localAuth.isDeviceSupported();
      if (!canAuthenticate) {
        _logger.w('BiometricLockService: device does not support biometrics');
        return false;
      }

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Authenticate to open Splitwise',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );

      if (didAuthenticate) {
        await recordUnlock();
      }
      return didAuthenticate;
    } catch (e, stack) {
      _logger.e('BiometricLockService: authentication failed', e, stack);
      return false;
    }
  }

  static int timeoutLabelToSeconds(String timeout) {
    switch (timeout) {
      case '2 minutes':
        return 120;
      case '5 minutes':
        return 300;
      case '5 seconds':
      default:
        return 5;
    }
  }

  static String secondsToTimeoutLabel(int seconds) {
    switch (seconds) {
      case 120:
        return '2 minutes';
      case 300:
        return '5 minutes';
      default:
        return '5 seconds';
    }
  }
}
