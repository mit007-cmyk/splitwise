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
}
