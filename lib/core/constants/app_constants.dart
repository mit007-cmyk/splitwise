class AppConstants {
  AppConstants._();

  static const String appName = 'Splitwise';
  static const String appVersion = '1.0.0';
  
  // Hive box names
  static const String hiveUserBox = 'user_box';
  static const String hiveSettingsBox = 'settings_box';
  static const String hiveCacheBox = 'cache_box';
  static const String hiveThemeBox = 'theme_box';
  static const String hivePendingSyncBox = 'pending_sync_box';

  // Remote Config Keys
  static const String rcMaintenanceMode = 'maintenance_mode';
  static const String rcForceUpdate = 'force_update';
  static const String rcMinVersion = 'min_version';
  static const String rcFeatureFlags = 'feature_flags';
  static const String rcBannerText = 'banner_text';
}

class FirestorePaths {
  FirestorePaths._();
  static const String root = 'Splitwise';
  static const String app = 'app';
  static const String emailConfiguration = 'email_configuration';
  static const String securityDetails = 'security_details';
}

class AppDimensions {
  AppDimensions._();

  // Spacings
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;

  // Border Radii
  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;
  static const double radiusCircular = 999.0;

  // Viewport/Widget Dimensions
  static const double buttonHeight = 48.0;
  static const double inputHeight = 56.0;
  static const double avatarSizeSm = 32.0;
  static const double avatarSizeMd = 48.0;
  static const double avatarSizeLg = 64.0;
  static const double cardElevation = 2.0;
}

class AppDurations {
  AppDurations._();

  static const Duration splashDelay = Duration(seconds: 2);
  static const Duration animQuick = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 500);
}
