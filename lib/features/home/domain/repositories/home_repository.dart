import '../../../../core/errors/result.dart';
import '../../../auth/data/models/user_model.dart';
import '../entities/balance_summary.dart';
import '../entities/group_summary.dart';
import '../entities/home_summary.dart';

abstract class HomeRepository {
  Future<Result<HomeSummary>> getHomeSummary({
    required String userId,
    bool forceRefresh = false,
  });

  Future<Result<BalanceSummary>> getOverallBalance({required String userId});

  Future<Result<List<GroupSummary>>> getGroups({required String userId});

  Future<Result<List<GroupSummary>>> refreshGroups({required String userId});

  Future<Result<void>> createGroup({
    required String userId,
    required String userName,
    required String name,
    required String type,
  });

  /// Idempotently makes sure a group document with [groupId] exists with at
  /// least [memberIds]/[name]/[type] set, without touching it if it already
  /// exists. Used to lazily provision the synthetic "non-group expenses"
  /// context the first time two friends split an expense directly.
  Future<Result<GroupSummary>> ensureGroupExists({
    required String groupId,
    required String name,
    required String type,
    required List<String> memberIds,
  });

  Future<Result<List<UserModel>>> getAllUsers();

  Future<Result<void>> addContact({
    required String name,
    String? phone,
    String? email,
  });

  Future<Result<void>> addGroupMembers({
    required String groupId,
    required List<String> memberIds,
  });

  Future<Result<void>> editGroup({
    required String groupId,
    required String name,
    required String type,
  });

  Future<Result<void>> leaveGroup({
    required String groupId,
    required String userId,
  });

  Future<Result<void>> deleteGroup({
    required String groupId,
    required String userId,
  });
}
