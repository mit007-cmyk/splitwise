import 'package:injectable/injectable.dart';

import '../../../errors/result.dart';
import '../../../../shared/repositories/base_repository.dart';
import '../../domain/entities/device_token.dart';
import '../../domain/repositories/device_token_repository.dart';
import '../datasources/device_token_remote_datasource.dart';
import '../models/device_token_model.dart';

@LazySingleton(as: DeviceTokenRepository)
class DeviceTokenRepositoryImpl extends BaseRepository
    implements DeviceTokenRepository {
  DeviceTokenRepositoryImpl(this._remoteDataSource);

  final DeviceTokenRemoteDataSource _remoteDataSource;

  @override
  Future<Result<void>> upsertDevice({
    required String userId,
    required DeviceToken token,
  }) {
    return safeCall(() {
      return _remoteDataSource.upsertDevice(
        userId: userId,
        token: DeviceTokenModel.fromEntity(token),
      );
    });
  }

  @override
  Future<Result<void>> deactivateDevice({
    required String userId,
    required String deviceId,
  }) {
    return safeCall(() {
      return _remoteDataSource.deactivateDevice(
        userId: userId,
        deviceId: deviceId,
      );
    });
  }
}
