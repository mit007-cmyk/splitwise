import '../../../../core/errors/result.dart';
import '../entities/group_default_split.dart';

abstract class GroupUserSettingsRepository {
  Future<Result<GroupDefaultSplit?>> getDefaultSplit({
    required String groupId,
    required String userId,
  });

  Future<Result<void>> saveDefaultSplit(GroupDefaultSplit split);
}
