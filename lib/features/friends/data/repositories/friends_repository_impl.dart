import 'package:injectable/injectable.dart';
import '../../../../core/errors/result.dart';
import '../../../../shared/repositories/base_repository.dart';
import '../../domain/entities/friend_code_info.dart';
import '../../domain/entities/friend_invite_preview.dart';
import '../../domain/entities/friend_request.dart';
import '../../domain/entities/user_preview.dart';
import '../../domain/repositories/friends_repository.dart';
import '../datasources/friends_remote_datasource.dart';

@LazySingleton(as: FriendsRepository)
class FriendsRepositoryImpl extends BaseRepository implements FriendsRepository {
  final FriendsRemoteDataSource _remoteDataSource;

  FriendsRepositoryImpl(this._remoteDataSource);

  @override
  Future<Result<FriendCodeInfo>> getMyFriendCode({
    required String userId,
    required String userName,
    String? photoUrl,
  }) {
    return safeCall(
      () => _remoteDataSource.getFriendCodeInfo(
        userId: userId,
        userName: userName,
        photoUrl: photoUrl,
      ),
    );
  }

  @override
  Future<Result<FriendCodeInfo>> changeFriendCode({
    required String userId,
    required String userName,
    String? photoUrl,
  }) {
    return safeCall(
      () => _remoteDataSource.changeFriendCode(
        userId: userId,
        userName: userName,
        photoUrl: photoUrl,
      ),
    );
  }

  @override
  Future<Result<FriendInvitePreview>> resolveInvitePreview({
    required String currentUserId,
    required String friendCode,
  }) {
    return safeCall(
      () => _remoteDataSource.resolveInvitePreview(
        currentUserId: currentUserId,
        friendCode: friendCode,
      ),
    );
  }

  @override
  Future<Result<void>> sendFriendRequest({
    required String fromUserId,
    required String toUserId,
  }) {
    return safeCall(
      () => _remoteDataSource.sendFriendRequest(
        fromUserId: fromUserId,
        toUserId: toUserId,
      ),
    );
  }

  @override
  Future<Result<void>> acceptFriendRequest({
    required String requestId,
    required String userId,
  }) {
    return safeCall(
      () => _remoteDataSource.acceptFriendRequest(
        requestId: requestId,
        userId: userId,
      ),
    );
  }

  @override
  Future<Result<void>> declineFriendRequest({
    required String requestId,
    required String userId,
  }) {
    return safeCall(
      () => _remoteDataSource.declineFriendRequest(
        requestId: requestId,
        userId: userId,
      ),
    );
  }

  @override
  Future<Result<List<FriendRequest>>> getIncomingFriendRequests(String userId) {
    return safeCall(() => _remoteDataSource.getIncomingFriendRequests(userId));
  }

  @override
  Future<Result<List<UserPreview>>> getFriends(String userId) {
    return safeCall(() => _remoteDataSource.getFriends(userId));
  }

  @override
  Future<Result<void>> addFriendDirectly({
    required String currentUserId,
    required String friendUserId,
  }) {
    return safeCall(
      () => _remoteDataSource.addFriendDirectly(
        currentUserId: currentUserId,
        friendUserId: friendUserId,
      ),
    );
  }

  @override
  Future<Result<void>> removeFriend({
    required String currentUserId,
    required String friendUserId,
  }) {
    return safeCall(
      () => _remoteDataSource.removeFriend(
        currentUserId: currentUserId,
        friendUserId: friendUserId,
      ),
    );
  }

  @override
  Future<Result<UserPreview?>> findUserByEmailOrPhone({
    String? email,
    String? phone,
  }) {
    return safeCall(
      () => _remoteDataSource.findUserByEmailOrPhone(email: email, phone: phone),
    );
  }

  @override
  Future<Result<void>> createPendingContact({
    required String ownerUserId,
    required String displayName,
    String? email,
    String? phone,
  }) {
    return safeCall(
      () => _remoteDataSource.createPendingContact(
        ownerUserId: ownerUserId,
        displayName: displayName,
        email: email,
        phone: phone,
      ),
    );
  }

  @override
  Future<Result<List<UserPreview>>> getPendingContacts(String ownerUserId) {
    return safeCall(() => _remoteDataSource.getPendingContacts(ownerUserId));
  }

  @override
  Future<Result<void>> linkPendingContactsForUser({
    required String userId,
    String? email,
    String? phone,
  }) {
    return safeCall(
      () => _remoteDataSource.linkPendingContactsForUser(
        userId: userId,
        email: email,
        phone: phone,
      ),
    );
  }

  @override
  Future<Result<UserPreview?>> getUserById(String userId) {
    return safeCall(() => _remoteDataSource.getUserById(userId));
  }

  @override
  Future<Result<void>> blockUser({
    required String currentUserId,
    required String blockedUserId,
  }) {
    return safeCall(
      () => _remoteDataSource.blockUser(
        currentUserId: currentUserId,
        blockedUserId: blockedUserId,
      ),
    );
  }

  @override
  Future<Result<void>> unblockUser({
    required String currentUserId,
    required String blockedUserId,
  }) {
    return safeCall(
      () => _remoteDataSource.unblockUser(
        currentUserId: currentUserId,
        blockedUserId: blockedUserId,
      ),
    );
  }

  @override
  Future<Result<List<UserPreview>>> getBlockedUsers(String currentUserId) {
    return safeCall(() => _remoteDataSource.getBlockedUsers(currentUserId));
  }
}
