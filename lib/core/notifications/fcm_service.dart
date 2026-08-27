import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:injectable/injectable.dart';

import '../errors/result.dart';
import '../helpers/permission_helper.dart';
import '../services/app_logger.dart';
import 'current_user_id_provider.dart';
import 'device_identity_store.dart';
import 'domain/entities/device_token.dart';
import 'domain/repositories/device_token_repository.dart';
import 'fcm_token_client.dart';
import 'auth_user_id_changes.dart';

@lazySingleton
class FcmService {
  FcmService(
    this._repository,
    this._identityStore,
    this._tokenClient,
    this._userIdProvider,
    this._authUserIdChanges,
    this._permissionHelper,
    this._logger,
  );

  final DeviceTokenRepository _repository;
  final DeviceIdentityStore _identityStore;
  final FcmTokenClient _tokenClient;
  final CurrentUserIdProvider _userIdProvider;
  final AuthUserIdChanges _authUserIdChanges;
  final PermissionHelper _permissionHelper;
  final AppLogger _logger;

  bool _initialized = false;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<String?>? _authSubscription;
  Future<void>? _inFlightRegister;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      _tokenRefreshSubscription ??= _tokenClient.onTokenRefresh.listen(
        (token) {
          unawaited(updateToken(token));
        },
        onError: (Object error, StackTrace stackTrace) {
          _logger.e('FCM token refresh stream failed', error, stackTrace);
        },
      );

      _authSubscription ??= _authUserIdChanges.userIds.listen(
        (userId) {
          if (userId != null) {
            unawaited(registerToken());
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          _logger.e('Auth user id stream failed', error, stackTrace);
        },
      );
    } catch (e, stackTrace) {
      _initialized = false;
      _logUnexpected('FcmService.initialize failed', e, stackTrace);
    }
  }

  Future<void> registerToken() {
    return _inFlightRegister ??= _registerToken().whenComplete(() {
      _inFlightRegister = null;
    });
  }

  Future<void> _registerToken() async {
    try {
      final userId = _userIdProvider.userId;
      if (userId == null) {
        _logger.d('Skipping FCM registration: no authenticated user.');
        return;
      }

      final permitted = await _permissionHelper.ensureNotificationPermission();
      if (!permitted) {
        _logger.i('Skipping FCM registration: notification permission not granted.');
        return;
      }

      final token = await _readTokenWithRetry();
      if (token == null) {
        _logger.w('FCM token was null; device document was not written.');
        return;
      }

      await updateToken(token);
    } catch (e, stackTrace) {
      _logUnexpected('FCM token registration failed', e, stackTrace);
    }
  }

  Future<void> updateToken(String token) async {
    try {
      if (token.isEmpty) {
        _logger.w('Ignoring empty FCM token update.');
        return;
      }

      final userId = _userIdProvider.userId;
      if (userId == null) {
        _logger.d('Skipping FCM token update: no authenticated user.');
        return;
      }

      final deviceId = await _identityStore.getOrCreateDeviceId();
      final deviceToken = DeviceToken(
        deviceId: deviceId,
        fcmToken: token,
        platform: _identityStore.currentPlatform(),
        appVersion: await _identityStore.appVersion(),
        isActive: true,
      );

      final result = await _repository.upsertDevice(
        userId: userId,
        token: deviceToken,
      );
      if (result is FailureResult<void>) {
        _logger.e(
          'Failed to upsert FCM device token: ${result.failure.message}',
        );
        return;
      }

      _logger.i('FCM device token saved for device $deviceId.');
    } catch (e, stackTrace) {
      _logUnexpected('FCM token update failed', e, stackTrace);
    }
  }

  Future<void> deactivateCurrentDevice() async {
    try {
      final userId = _userIdProvider.userId;
      if (userId == null) {
        _logger.d('Skipping FCM deactivation: no authenticated user.');
        return;
      }

      final deviceId = await _identityStore.getOrCreateDeviceId();
      final result = await _repository.deactivateDevice(
        userId: userId,
        deviceId: deviceId,
      );
      if (result is FailureResult<void>) {
        _logger.e(
          'Failed to deactivate FCM device token: ${result.failure.message}',
        );
        return;
      }

      _logger.i('FCM device $deviceId marked inactive.');
    } catch (e, stackTrace) {
      _logUnexpected('FCM device deactivation failed', e, stackTrace);
    }
  }

  Future<String?> _readTokenWithRetry() async {
    for (var attempt = 0; attempt < 3; attempt++) {
      final token = await _tokenClient.getToken();
      if (token != null && token.isNotEmpty) return token;
      if (attempt < 2) {
        await Future<void>.delayed(Duration(milliseconds: 20 * (attempt + 1)));
      }
    }
    return null;
  }

  void _logUnexpected(String message, Object error, StackTrace stackTrace) {
    _logger.e(message, error, stackTrace);
    try {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: message,
        fatal: false,
      );
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    await _authSubscription?.cancel();
    _authSubscription = null;
    _initialized = false;
  }
}
