import '../../../auth/data/models/user_model.dart';
import '../../domain/entities/friend_code_info.dart';
import '../../domain/entities/friend_invite_preview.dart';
import '../../domain/entities/friend_request.dart';
import '../../domain/entities/user_preview.dart';

abstract class FriendsRemoteDataSource {
  Future<UserModel> ensureFriendCodeForUser(UserModel user);

  Future<FriendCodeInfo> getFriendCodeInfo({
    required String userId,
    required String userName,
    String? photoUrl,
  });

  Future<FriendCodeInfo> changeFriendCode({
    required String userId,
    required String userName,
    String? photoUrl,
  });

  Future<UserPreview?> lookupUserByFriendCode(String code);

  Future<FriendInvitePreview> resolveInvitePreview({
    required String currentUserId,
    required String friendCode,
  });

  Future<bool> areFriends(String uid1, String uid2);

  Future<void> sendFriendRequest({
    required String fromUserId,
    required String toUserId,
  });

  Future<void> acceptFriendRequest({
    required String requestId,
    required String userId,
  });

  Future<void> declineFriendRequest({
    required String requestId,
    required String userId,
  });

  Future<List<FriendRequest>> getIncomingFriendRequests(String userId);

  Future<List<UserPreview>> getFriends(String userId);

  /// Instantly creates a friendship — no friend request step (Splitwise scan flow).
  Future<void> addFriendDirectly({
    required String currentUserId,
    required String friendUserId,
  });

  /// Removes an existing friendship between two users.
  Future<void> removeFriend({
    required String currentUserId,
    required String friendUserId,
  });

  /// Finds a user by matching email or phone from the `users` table.
  /// Returns null if no match is found.
  Future<UserPreview?> findUserByEmailOrPhone({
    String? email,
    String? phone,
  });

  Future<String> createPendingContact({
    required String ownerUserId,
    required String displayName,
    String? email,
    String? phone,
  });

  Future<List<UserPreview>> getPendingContacts(String ownerUserId);

  /// Called after a user signs up/logs in. Finds any pending contacts
  /// (invited by other users) whose email/phone matches this user, and
  /// converts them into real friendships — Splitwise-style "contact linking".
  Future<void> linkPendingContactsForUser({
    required String userId,
    String? email,
    String? phone,
  });

  Future<UserPreview?> getUserById(String userId);

  Future<void> blockUser({
    required String currentUserId,
    required String blockedUserId,
  });

  Future<void> unblockUser({
    required String currentUserId,
    required String blockedUserId,
  });

  Future<List<UserPreview>> getBlockedUsers(String currentUserId);

  Future<Set<String>> getBlockedUserIds(String currentUserId);
}
