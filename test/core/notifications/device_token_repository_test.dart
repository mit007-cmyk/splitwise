import 'package:flutter_test/flutter_test.dart';
import 'package:splitwise/core/errors/failures.dart';
import 'package:splitwise/core/errors/result.dart';
import 'package:splitwise/core/notifications/data/datasources/device_token_remote_datasource.dart';
import 'package:splitwise/core/notifications/data/models/device_token_model.dart';
import 'package:splitwise/core/notifications/data/repositories/device_token_repository_impl.dart';
import 'package:splitwise/core/notifications/domain/entities/device_token.dart';

class FakeDeviceTokenRemoteDataSource implements DeviceTokenRemoteDataSource {
  final Map<String, DeviceTokenModel> documents = {};
  int upsertCalls = 0;
  int deactivateCalls = 0;
  Object? upsertError;
  Object? deactivateError;

  String _key(String userId, String deviceId) => '$userId|$deviceId';

  @override
  Future<void> upsertDevice({
    required String userId,
    required DeviceTokenModel token,
  }) async {
    upsertCalls += 1;
    if (upsertError != null) throw upsertError!;
    documents[_key(userId, token.deviceId)] = token;
  }

  @override
  Future<void> deactivateDevice({
    required String userId,
    required String deviceId,
  }) async {
    deactivateCalls += 1;
    if (deactivateError != null) throw deactivateError!;
    final key = _key(userId, deviceId);
    final existing = documents[key];
    if (existing == null) return;
    documents[key] = DeviceTokenModel(
      deviceId: existing.deviceId,
      fcmToken: existing.fcmToken,
      platform: existing.platform,
      appVersion: existing.appVersion,
      isActive: false,
    );
  }
}

void main() {
  late FakeDeviceTokenRemoteDataSource remote;
  late DeviceTokenRepositoryImpl repository;

  const token = DeviceToken(
    deviceId: 'device-1',
    fcmToken: 'fcm-old',
    platform: 'android',
    appVersion: '1.0.0',
    isActive: true,
  );

  setUp(() {
    remote = FakeDeviceTokenRemoteDataSource();
    repository = DeviceTokenRepositoryImpl(remote);
  });

  test('upsert writes a device record for the user', () async {
    final result = await repository.upsertDevice(userId: 'user-a', token: token);

    expect(result.isSuccess, isTrue);
    expect(remote.upsertCalls, 1);
    expect(remote.documents['user-a|device-1']?.fcmToken, 'fcm-old');
  });

  test('upserting the same device id updates instead of creating another record', () async {
    await repository.upsertDevice(userId: 'user-a', token: token);
    final updated = DeviceToken(
      deviceId: token.deviceId,
      fcmToken: 'fcm-new',
      platform: token.platform,
      appVersion: '1.0.1',
      isActive: true,
    );

    await repository.upsertDevice(userId: 'user-a', token: updated);

    expect(remote.documents.keys, hasLength(1));
    expect(remote.documents['user-a|device-1']?.fcmToken, 'fcm-new');
    expect(remote.documents['user-a|device-1']?.appVersion, '1.0.1');
  });

  test('deactivate marks only the current device inactive', () async {
    await repository.upsertDevice(userId: 'user-a', token: token);
    await repository.upsertDevice(
      userId: 'user-a',
      token: const DeviceToken(
        deviceId: 'device-2',
        fcmToken: 'fcm-other',
        platform: 'ios',
        appVersion: '1.0.0',
        isActive: true,
      ),
    );

    final result = await repository.deactivateDevice(
      userId: 'user-a',
      deviceId: 'device-1',
    );

    expect(result.isSuccess, isTrue);
    expect(remote.documents['user-a|device-1']?.isActive, isFalse);
    expect(remote.documents['user-a|device-2']?.isActive, isTrue);
  });

  test('deactivate does not touch another user\'s devices', () async {
    await repository.upsertDevice(userId: 'user-a', token: token);
    await repository.upsertDevice(userId: 'user-b', token: token);

    await repository.deactivateDevice(userId: 'user-a', deviceId: 'device-1');

    expect(remote.documents['user-a|device-1']?.isActive, isFalse);
    expect(remote.documents['user-b|device-1']?.isActive, isTrue);
  });

  test('maps remote failures instead of throwing', () async {
    remote.upsertError = Exception('network down');

    final result = await repository.upsertDevice(userId: 'user-a', token: token);

    expect(result.isFailure, isTrue);
    expect((result as FailureResult<void>).failure, isA<UnknownFailure>());
  });
}
