import '../../../errors/result.dart';
import '../entities/device_token.dart';

abstract class DeviceTokenRepository {
  Future<Result<void>> upsertDevice({
    required String userId,
    required DeviceToken token,
  });

  Future<Result<void>> deactivateDevice({
    required String userId,
    required String deviceId,
  });
}
