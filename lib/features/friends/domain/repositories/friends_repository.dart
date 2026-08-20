import '../../../../core/errors/result.dart';
import '../../domain/entities/friend_code_info.dart';
import '../../domain/entities/friend_invite_preview.dart';
import '../../domain/entities/friend_request.dart';
import '../../domain/entities/user_preview.dart';

abstract class FriendsRepository {
  Future<Result<FriendCodeInfo>> getMyFriendCode({
    required String userId,
    required String userName,
    String? photoUrl,
  });

  Future<Result<FriendCodeInfo>> changeFriendCode({
    required String userId,
    required String userName,
    String? photoUrl,
  });

  Future<Result<FriendInvitePreview>> resolveInvitePreview({
    required String currentUserId,
    required String friendCode,
  });

  Future<Result<void>> sendFriendRequest({
    required String fromUserId,
    required String toUserId,
  });

  Future<Result<void>> acceptFriendRequest({
    required String requestId,
    required String userId,
  });

  Future<Result<void>> declineFriendRequest({
    required String requestId,
    required String userId,
  });

  Future<Result<List<FriendRequest>>> getIncomingFriendRequests(String userId);

  Future<Result<List<UserPreview>>> getFriends(String userId);

  Future<Result<void>> addFriendDirectly({
    required String currentUserId,
    required String friendUserId,
  });

  /// Removes an existing friendship between two users.
  Future<Result<void>> removeFriend({
    required String currentUserId,
    required String friendUserId,
  });

  /// Registered accounts only (skips pending shadow users). Used to match
  /// on-device contacts without uploading the address book.
  Future<Result<List<UserPreview>>> getRegisteredUsers();

  /// Finds a Splitwise user by email or phone.
  /// Returns null when no user matches.
  Future<Result<UserPreview?>> findUserByEmailOrPhone({
    String? email,
    String? phone,
  });

  Future<Result<String>> createPendingContact({
    required String ownerUserId,
    required String displayName,
    String? email,
    String? phone,
  });

  Future<Result<void>> updatePendingContact({
    required String ownerUserId,
    required String contactId,
    required String displayName,
    String? email,
    String? phone,
  });

  Future<Result<List<UserPreview>>> getPendingContacts(String ownerUserId);

  /// Converts any pending contacts matching this user's email/phone into
  /// real friendships. Call this right after login/signup.
  Future<Result<void>> linkPendingContactsForUser({
    required String userId,
    String? email,
    String? phone,
  });

  Future<Result<UserPreview?>> getUserById(String userId);

  /// One-way block: removes friendship, does not delete expense history.
  Future<Result<void>> blockUser({
    required String currentUserId,
    required String blockedUserId,
  });

  Future<Result<void>> unblockUser({
    required String currentUserId,
    required String blockedUserId,
  });

  Future<Result<List<UserPreview>>> getBlockedUsers(String currentUserId);
}
