import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:injectable/injectable.dart';
import 'app_logger.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Top-level function for background FCM handling
  // Do not execute UI logic here. Log or update local caches.
}

@singleton
class NotificationService {
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  final AppLogger _logger;
  
  NotificationService(this._logger);

  /// Initializes messaging configurations and sets listeners
  Future<void> init() async {
    try {
      // Set background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle foreground notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _logger.d('FCM Foreground Notification Received:');
        _logger.d('Title: ${message.notification?.title}');
        _logger.d('Body: ${message.notification?.body}');
        _logger.d('Data: ${message.data}');
      });

      // Handle notification clicks when the app is in background but still open
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _logger.d('FCM Notification Clicked (App Background):');
        _handleNotificationNavigation(message.data);
      });

      // Check if opened from terminated state
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _logger.d('FCM Notification Clicked (App Terminated):');
        _handleNotificationNavigation(initialMessage.data);
      }

      _logger.i('FCM Notification Service initialized.');
    } catch (e, stackTrace) {
      _logger.e('Failed to initialize NotificationService', e, stackTrace);
    }
  }

  /// Get the device's FCM Token for target notifications
  Future<String?> getFcmToken() async {
    try {
      final token = await _messaging.getToken();
      _logger.d('FCM Registration Token: $token');
      return token;
    } catch (e, stackTrace) {
      _logger.e('Failed to get FCM Token', e, stackTrace);
      return null;
    }
  }

  /// Monitor token updates
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  /// Deletes standard token (useful during logout flows)
  Future<void> deleteFcmToken() async {
    try {
      await _messaging.deleteToken();
      _logger.d('FCM token deleted successfully.');
    } catch (e, stackTrace) {
      _logger.e('Failed to delete FCM token', e, stackTrace);
    }
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    _logger.d('FCM Notification Navigation triggered: $data');
    // Future module/router integration goes here.
    // e.g. Navigate using AppRouter.go('/expense/123')
  }
}
