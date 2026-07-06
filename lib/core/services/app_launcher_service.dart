import 'package:url_launcher/url_launcher.dart';

/// Opens external URLs and store listings. UI should call these helpers
/// instead of constructing launch URIs directly.
class AppLauncherService {
  AppLauncherService._();

  /// Play Store package used for rate-app testing.
  /// Replace with `com.example.splitwise` once the app is published.
  static const String packageName = 'com.whatsapp';

  static Uri get _marketUri => Uri.parse('market://details?id=$packageName');

  static Uri get _playStoreWebUri => Uri.parse(
        'https://play.google.com/store/apps/details?id=$packageName',
      );

  /// Opens the Play Store listing for [packageName].
  ///
  /// Tries `market://` first, then falls back to the HTTPS Play Store URL.
  /// Never throws — failures are swallowed so the UI cannot crash.
  static Future<void> rateApp() async {
    try {
      final marketOpened = await launchUrl(
        _marketUri,
        mode: LaunchMode.externalApplication,
      );
      if (marketOpened) return;
    } catch (_) {
      // Play Store app unavailable — fall through to web URL.
    }

    try {
      await launchUrl(
        _playStoreWebUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      // Play Store could not be opened; fail silently.
    }
  }
}
