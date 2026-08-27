import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:injectable/injectable.dart';
import '../services/app_logger.dart';

@singleton
class PermissionHelper {
  final AppLogger _logger;

  PermissionHelper(this._logger);

  /// Returns true when notifications are authorized or provisional.
  ///
  /// Requests the system prompt only when status is still undetermined so
  /// denied / permanently denied users are not prompted again.
  Future<bool> ensureNotificationPermission() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final current = await messaging.getNotificationSettings();
      switch (current.authorizationStatus) {
        case AuthorizationStatus.authorized:
        case AuthorizationStatus.provisional:
          return true;
        case AuthorizationStatus.denied:
          _logger.w(
            'Notification permission denied; skipping FCM token registration.',
          );
          return false;
        case AuthorizationStatus.notDetermined:
          return requestNotificationPermission();
      }
    } catch (e, stackTrace) {
      _logger.e('Failed to resolve notification permission', e, stackTrace);
      return false;
    }
  }

  /// Requests notification permission specifically
  Future<bool> requestNotificationPermission() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: true,
        sound: true,
      );

      _logger.d('Notification permission settings status: ${settings.authorizationStatus}');
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e, stackTrace) {
      _logger.e('Failed to request notification permission', e, stackTrace);
      return false;
    }
  }

  /// Request camera permissions (can be integrated with permission_handler package in future)
  Future<bool> requestCameraPermission() async {
    _logger.d('Requesting camera permission (mock implementation)');
    return true;
  }

  /// Request photo library permissions (can be integrated with permission_handler package in future)
  Future<bool> requestPhotosPermission() async {
    _logger.d('Requesting photo library permission (mock implementation)');
    return true;
  }
}
