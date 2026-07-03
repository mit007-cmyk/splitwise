import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:injectable/injectable.dart';
import '../constants/app_constants.dart';
import 'app_logger.dart';

@singleton
class RemoteConfigService {
  FirebaseRemoteConfig get _remoteConfig => FirebaseRemoteConfig.instance;
  final AppLogger _logger;

  RemoteConfigService(this._logger);

  /// Initializes Remote Config and triggers fetch operations
  Future<void> init() async {
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );

      // Set fallback defaults
      await _remoteConfig.setDefaults({
        AppConstants.rcMaintenanceMode: false,
        AppConstants.rcForceUpdate: false,
        AppConstants.rcMinVersion: '1.0.0',
        AppConstants.rcFeatureFlags: '{}',
        AppConstants.rcBannerText: '',
      });

      final activated = await _remoteConfig.fetchAndActivate();
      _logger.i('Firebase Remote Config initialized. Fetch activated: $activated');
    } catch (e, stackTrace) {
      _logger.e('Failed to initialize RemoteConfigService', e, stackTrace);
    }
  }

  /// Check if the application is locked down for server maintenance
  bool get isMaintenanceMode => _remoteConfig.getBool(AppConstants.rcMaintenanceMode);

  /// Check if the application requires a critical update
  bool get requiresForceUpdate => _remoteConfig.getBool(AppConstants.rcForceUpdate);

  /// Get the minimum supported version string (e.g. '1.1.0')
  String get minimumAppVersion => _remoteConfig.getString(AppConstants.rcMinVersion);

  /// Retrieve general feature flags or keys as dynamic strings
  String getFeatureFlagString(String flagKey) {
    return _remoteConfig.getString(flagKey);
  }

  /// General flag checker
  bool getBool(String key) => _remoteConfig.getBool(key);

  /// General string value
  String getString(String key) => _remoteConfig.getString(key);

  /// General int value
  int getInt(String key) => _remoteConfig.getInt(key);
}
