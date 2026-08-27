import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:injectable/injectable.dart';

import '../services/app_logger.dart';

abstract class FcmTokenClient {
  Future<String?> getToken();
  Stream<String> get onTokenRefresh;
}

@LazySingleton(as: FcmTokenClient)
class FirebaseFcmTokenClient implements FcmTokenClient {
  FirebaseFcmTokenClient(this._logger);

  final AppLogger _logger;

  @override
  Future<String?> getToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return null;
      return token;
    } catch (e, stackTrace) {
      _logger.e('Failed to retrieve FCM token', e, stackTrace);
      return null;
    }
  }

  @override
  Stream<String> get onTokenRefresh => FirebaseMessaging.instance.onTokenRefresh;
}
