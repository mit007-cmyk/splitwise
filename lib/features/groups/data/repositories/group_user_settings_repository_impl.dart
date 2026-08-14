import 'package:injectable/injectable.dart';
import '../../../../core/errors/result.dart';
import '../../../../shared/repositories/base_repository.dart';
import '../../domain/entities/group_default_split.dart';
import '../../domain/repositories/group_user_settings_repository.dart';
import '../datasources/group_user_settings_remote_datasource.dart';
import '../models/group_default_split_model.dart';

@LazySingleton(as: GroupUserSettingsRepository)
class GroupUserSettingsRepositoryImpl extends BaseRepository
    implements GroupUserSettingsRepository {
  final GroupUserSettingsRemoteDataSource _remoteDataSource;

  GroupUserSettingsRepositoryImpl(this._remoteDataSource);

  @override
  Future<Result<GroupDefaultSplit?>> getDefaultSplit({
    required String groupId,
    required String userId,
  }) {
    return safeCall(() async {
      return _remoteDataSource.getDefaultSplit(groupId: groupId, userId: userId);
    });
  }

  @override
  Future<Result<void>> saveDefaultSplit(GroupDefaultSplit split) {
    return safeCall(() async {
      await _remoteDataSource.saveDefaultSplit(
        GroupDefaultSplitModel.fromEntity(split),
      );
    });
  }
}
