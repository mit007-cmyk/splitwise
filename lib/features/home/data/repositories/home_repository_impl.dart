import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../domain/entities/balance_summary.dart';
import '../../domain/entities/group_summary.dart';
import '../../domain/entities/home_summary.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_local_datasource.dart';
import '../datasources/home_remote_datasource.dart';

@LazySingleton(as: HomeRepository)
class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource _remoteDataSource;
  final HomeLocalDataSource _localDataSource;
  final ConnectivityService _connectivityService;

  HomeRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._connectivityService,
  );

  @override
  Future<Result<HomeSummary>> getHomeSummary({
    required String userId,
    bool forceRefresh = false,
  }) async {
    final isOnline = await _connectivityService.isConnected;

    if (isOnline) {
      try {
        final remoteData = await _remoteDataSource.getHomeSummary(userId);
        await _localDataSource.cacheHomeSummary(userId, remoteData);
        return Result.success(remoteData);
      } catch (e) {
        // Fallback to local cache if remote fetch fails
        final cachedData = await _localDataSource.getCachedHomeSummary(userId);
        if (cachedData != null) {
          return Result.success(cachedData);
        }
        return Result.failure(ServerFailure('Failed to load summary from Firestore: $e'));
      }
    } else {
      // Offline fallback
      final cachedData = await _localDataSource.getCachedHomeSummary(userId);
      if (cachedData != null) {
        return Result.success(cachedData);
      }
      return Result.failure(const NetworkFailure('No internet connection and no cached data found.'));
    }
  }

  @override
  Future<Result<BalanceSummary>> getOverallBalance({required String userId}) async {
    final summaryResult = await getHomeSummary(userId: userId);
    if (summaryResult is SuccessResult<HomeSummary>) {
      return Result.success(summaryResult.data.overallBalance);
    }
    return Result.failure((summaryResult as FailureResult<HomeSummary>).failure);
  }

  @override
  Future<Result<List<GroupSummary>>> getGroups({required String userId}) async {
    final summaryResult = await getHomeSummary(userId: userId);
    if (summaryResult is SuccessResult<HomeSummary>) {
      return Result.success(summaryResult.data.groups);
    }
    return Result.failure((summaryResult as FailureResult<HomeSummary>).failure);
  }

  @override
  Future<Result<List<GroupSummary>>> refreshGroups({required String userId}) async {
    final summaryResult = await getHomeSummary(userId: userId, forceRefresh: true);
    if (summaryResult is SuccessResult<HomeSummary>) {
      return Result.success(summaryResult.data.groups);
    }
    return Result.failure((summaryResult as FailureResult<HomeSummary>).failure);
  }

  @override
  Future<Result<void>> createGroup({
    required String userId,
    required String userName,
    required String name,
    required String type,
  }) async {
    try {
      final isOnline = await _connectivityService.isConnected;
      if (!isOnline) {
        return Result.failure(const NetworkFailure('Cannot create group while offline.'));
      }

      final groupId = const Uuid().v4();

      final groupData = {
        'id': groupId,
        'name': name.trim(),
        'type': type,
        'createdBy': userId,
        'members': [userId],
        'createdAt': FieldValue.serverTimestamp(),
        'expenses': {},
      };

      await _remoteDataSource.createGroup(
        groupId: groupId,
        data: groupData,
      );

      return Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure('Failed to create group: $e'));
    }
  }

  @override
  Future<Result<GroupSummary>> ensureGroupExists({
    required String groupId,
    required String name,
    required String type,
    required List<String> memberIds,
  }) async {
    try {
      final isOnline = await _connectivityService.isConnected;
      if (!isOnline) {
        return Result.failure(const NetworkFailure('Cannot start this expense while offline.'));
      }

      await _remoteDataSource.ensureGroupExists(
        groupId: groupId,
        name: name,
        type: type,
        memberIds: memberIds,
      );

      return Result.success(GroupSummary(
        groupId: groupId,
        groupName: name,
        totalBalance: 0,
        balanceType: BalanceType.settled,
        memberBalances: const [],
        memberCount: memberIds.length,
        memberIds: memberIds,
        groupType: type,
      ));
    } catch (e) {
      return Result.failure(ServerFailure('Failed to prepare this expense: $e'));
    }
  }

  @override
  Future<Result<List<UserModel>>> getAllUsers() async {
    try {
      final users = await _remoteDataSource.getAllUsers();
      return Result.success(users);
    } catch (e) {
      return Result.failure(ServerFailure('Failed to fetch users: $e'));
    }
  }

  @override
  Future<Result<void>> addContact({
    required String name,
    String? phone,
    String? email,
  }) async {
    try {
      final isOnline = await _connectivityService.isConnected;
      if (!isOnline) {
        return Result.failure(const NetworkFailure('Cannot add friend while offline.'));
      }
      await _remoteDataSource.addContact(name: name, phone: phone, email: email);
      return Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure('Failed to add contact: $e'));
    }
  }

  @override
  Future<Result<void>> addGroupMembers({
    required String groupId,
    required List<String> memberIds,
  }) async {
    try {
      final isOnline = await _connectivityService.isConnected;
      if (!isOnline) {
        return Result.failure(const NetworkFailure('Cannot update group members while offline.'));
      }
      await _remoteDataSource.addGroupMembers(groupId: groupId, memberIds: memberIds);
      return Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure('Failed to add group members: $e'));
    }
  }

  @override
  Future<Result<void>> editGroup({
    required String groupId,
    required String name,
    required String type,
  }) async {
    try {
      final isOnline = await _connectivityService.isConnected;
      if (!isOnline) {
        return Result.failure(const NetworkFailure('Cannot edit group while offline.'));
      }
      await _remoteDataSource.editGroup(groupId: groupId, name: name, type: type);
      return Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure('Failed to edit group: $e'));
    }
  }

  @override
  Future<Result<void>> leaveGroup({
    required String groupId,
    required String userId,
  }) async {
    try {
      final isOnline = await _connectivityService.isConnected;
      if (!isOnline) {
        return Result.failure(const NetworkFailure('Cannot leave group while offline.'));
      }
      await _remoteDataSource.leaveGroup(groupId: groupId, userId: userId);
      return Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure('Failed to leave group: $e'));
    }
  }

  @override
  Future<Result<void>> deleteGroup({
    required String groupId,
    required String userId,
  }) async {
    try {
      final isOnline = await _connectivityService.isConnected;
      if (!isOnline) {
        return Result.failure(const NetworkFailure('Cannot delete group while offline.'));
      }
      await _remoteDataSource.deleteGroup(
        groupId: groupId,
        actorUserId: userId,
      );
      return Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure('Failed to delete group: $e'));
    }
  }
}
