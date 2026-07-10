import 'package:injectable/injectable.dart';
import '../../../../core/errors/result.dart';
import '../../../../shared/repositories/base_repository.dart';
import '../../domain/entities/activity_page_result.dart';
import '../../domain/repositories/activity_repository.dart';
import '../datasources/activity_remote_datasource.dart';

@LazySingleton(as: ActivityRepository)
class ActivityRepositoryImpl extends BaseRepository implements ActivityRepository {
  final ActivityRemoteDataSource _remoteDataSource;

  ActivityRepositoryImpl(this._remoteDataSource);

  @override
  Future<Result<ActivityPageResult>> getActivityPage({
    required String userId,
    DateTime? before,
    int limit = 20,
  }) {
    return safeCall(() async {
      final result = await _remoteDataSource.getActivityPage(
        userId: userId,
        before: before,
        limit: limit,
      );
      return ActivityPageResult(
        items: result.items,
        nextCursor: result.nextCursor,
        hasMore: result.hasMore,
      );
    });
  }
}

