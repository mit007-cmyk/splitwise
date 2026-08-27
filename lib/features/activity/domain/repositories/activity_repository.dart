import '../../../../core/errors/result.dart';
import '../entities/activity_page_result.dart';

abstract class ActivityRepository {
  Future<Result<ActivityPageResult>> getActivityPage({
    required String userId,
    DateTime? before,
    int limit = 20,
  });

  Future<Result<void>> markAsRead({
    required String eventId,
    required String userId,
  });
}

