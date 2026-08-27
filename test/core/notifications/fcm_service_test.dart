import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:splitwise/core/helpers/permission_helper.dart';
import 'package:splitwise/core/notifications/auth_user_id_changes.dart';
import 'package:splitwise/core/notifications/current_user_id_provider.dart';
import 'package:splitwise/core/notifications/device_identity_store.dart';
import 'package:splitwise/core/notifications/domain/entities/device_token.dart';
import 'package:splitwise/core/notifications/domain/repositories/device_token_repository.dart';
import 'package:splitwise/core/notifications/fcm_service.dart';
import 'package:splitwise/core/notifications/fcm_token_client.dart';
import 'package:splitwise/core/errors/result.dart';
import 'package:splitwise/core/services/app_logger.dart';

class FakeCurrentUserIdProvider implements CurrentUserIdProvider {
  FakeCurrentUserIdProvider(this.userId);
  @override
  String? userId;
}

class FakeAuthUserIdChanges implements AuthUserIdChanges {
  final _controller = StreamController<String?>.broadcast();

  void emit(String? userId) => _controller.add(userId);

  @override
  Stream<String?> get userIds => _controller.stream;

  Future<void> close() => _controller.close();
}

class FakeFcmTokenClient implements FcmTokenClient {
  FakeFcmTokenClient({this.token, Stream<String>? refresh})
      : onTokenRefresh = refresh ?? const Stream.empty();

  String? token;

  @override
  Future<String?> getToken() async => token;

  @override
  final Stream<String> onTokenRefresh;
}

class FakeDeviceIdentityStore implements DeviceIdentityStore {
  FakeDeviceIdentityStore({
    this.deviceId = 'install-1',
    this.platform = 'android',
    this.version = '1.2.3',
  });

  String deviceId;
  String platform;
  String version;
  int deviceIdReads = 0;

  @override
  Future<String> getOrCreateDeviceId() async {
    deviceIdReads += 1;
    return deviceId;
  }

  @override
  String currentPlatform() => platform;

  @override
  Future<String> appVersion() async => version;
}

class FakeDeviceTokenRepository implements DeviceTokenRepository {
  final List<({String userId, DeviceToken token})> upserts = [];
  final List<({String userId, String deviceId})> deactivations = [];

  @override
  Future<Result<void>> upsertDevice({
    required String userId,
    required DeviceToken token,
  }) async {
    upserts.add((userId: userId, token: token));
    return Result.success(null);
  }

  @override
  Future<Result<void>> deactivateDevice({
    required String userId,
    required String deviceId,
  }) async {
    deactivations.add((userId: userId, deviceId: deviceId));
    return Result.success(null);
  }
}

class FakePermissionHelper extends PermissionHelper {
  FakePermissionHelper({this.granted = true}) : super(AppLogger());

  bool granted;
  int ensureCalls = 0;

  @override
  Future<bool> ensureNotificationPermission() async {
    ensureCalls += 1;
    return granted;
  }
}

void main() {
  late FakeCurrentUserIdProvider userIds;
  late FakeAuthUserIdChanges authChanges;
  late FakeFcmTokenClient tokenClient;
  late FakeDeviceIdentityStore identity;
  late FakeDeviceTokenRepository repository;
  late FakePermissionHelper permissions;
  late FcmService service;

  FcmService buildService({Stream<String>? refresh}) {
    tokenClient = FakeFcmTokenClient(token: 'token-1', refresh: refresh);
    return FcmService(
      repository,
      identity,
      tokenClient,
      userIds,
      authChanges,
      permissions,
      AppLogger(),
    );
  }

  setUp(() {
    userIds = FakeCurrentUserIdProvider('user-a');
    authChanges = FakeAuthUserIdChanges();
    identity = FakeDeviceIdentityStore();
    repository = FakeDeviceTokenRepository();
    permissions = FakePermissionHelper();
    service = buildService();
  });

  tearDown(() async {
    await service.dispose();
    await authChanges.close();
  });

  test('does not save a token when the user is unauthenticated', () async {
    userIds.userId = null;

    await service.registerToken();

    expect(repository.upserts, isEmpty);
    expect(permissions.ensureCalls, 0);
  });

  test('does not save a token when permission is denied', () async {
    permissions.granted = false;

    await service.registerToken();

    expect(repository.upserts, isEmpty);
  });

  test('does not crash when the FCM token is null', () async {
    tokenClient.token = null;

    await service.registerToken();

    expect(repository.upserts, isEmpty);
  });

  test('registers the current device document for the authenticated user', () async {
    await service.registerToken();

    expect(repository.upserts, hasLength(1));
    expect(repository.upserts.single.userId, 'user-a');
    expect(repository.upserts.single.token.deviceId, 'install-1');
    expect(repository.upserts.single.token.fcmToken, 'token-1');
    expect(repository.upserts.single.token.platform, 'android');
    expect(repository.upserts.single.token.appVersion, '1.2.3');
    expect(repository.upserts.single.token.isActive, isTrue);
  });

  test('token refresh updates the same device document', () async {
    await service.registerToken();
    identity.version = '1.2.4';

    await service.updateToken('token-2');

    expect(repository.upserts, hasLength(2));
    expect(
      repository.upserts.map((entry) => entry.token.deviceId).toSet(),
      {'install-1'},
    );
    expect(repository.upserts.last.token.fcmToken, 'token-2');
    expect(repository.upserts.last.token.isActive, isTrue);
  });

  test('initialize listens for token refresh and upserts the new token', () async {
    await service.dispose();
    final refresh = StreamController<String>.broadcast();
    service = buildService(refresh: refresh.stream);

    await service.initialize();
    await service.registerToken();
    refresh.add('token-refreshed');
    await Future<void>.delayed(Duration.zero);

    expect(repository.upserts.last.token.fcmToken, 'token-refreshed');
    await refresh.close();
  });

  test('initialize is idempotent and does not duplicate listeners', () async {
    await service.initialize();
    await service.initialize();
    authChanges.emit('user-a');
    await Future<void>.delayed(Duration.zero);

    expect(repository.upserts.length, 1);
  });

  test('login auth change registers the current device', () async {
    userIds.userId = 'user-b';
    await service.initialize();
    authChanges.emit('user-b');
    await Future<void>.delayed(Duration.zero);

    expect(repository.upserts, hasLength(1));
    expect(repository.upserts.single.userId, 'user-b');
  });

  test('deactivateCurrentDevice marks only this installation inactive', () async {
    await service.deactivateCurrentDevice();

    expect(repository.deactivations, hasLength(1));
    expect(repository.deactivations.single.userId, 'user-a');
    expect(repository.deactivations.single.deviceId, 'install-1');
  });

  test('deactivateCurrentDevice no-ops without an authenticated user', () async {
    userIds.userId = null;

    await service.deactivateCurrentDevice();

    expect(repository.deactivations, isEmpty);
  });
}
