import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:injectable/injectable.dart';
import '../services/app_logger.dart';

@singleton
class PermissionHelper {
  final AppLogger _logger;

  PermissionHelper(this._logger);

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
        provisional: false,
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
