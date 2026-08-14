import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/utils/friend_code_generator.dart';
import '../../../../core/utils/friend_code_parser.dart';
import '../../../../core/utils/activity_event_writer.dart';
import '../../../../core/utils/blocked_users_store.dart';
import '../../../../core/utils/friendship_id_helper.dart';
import '../../../auth/data/models/user_model.dart';
import '../../domain/entities/friend_code_info.dart';
import '../../domain/entities/friend_invite_preview.dart';
import '../../domain/entities/friend_invite_resolution.dart';
import '../../domain/entities/friend_request.dart';
import '../../domain/entities/user_preview.dart';
import '../models/friend_request_model.dart';
import '../models/friendship_model.dart';
import '../models/friend_code_entry_model.dart';
import 'friends_remote_datasource.dart';

@LazySingleton(as: FriendsRemoteDataSource)
class FriendsRemoteDataSourceImpl implements FriendsRemoteDataSource {
  final FirestoreService _firestoreService;
  final AppLogger _logger;

  static const _uuid = Uuid();
  static const int _maxGenerationAttempts = 12;

  FriendsRemoteDataSourceImpl(this._firestoreService, this._logger);

  @override
  Future<UserModel> ensureFriendCodeForUser(UserModel user) async {
    final existing = await _readUserRecord(user.id);
    final existingCode = existing?['friendCode'] as String?;

    if (existingCode != null && existingCode.isNotEmpty) {
      return user.copyWith(
        friendCode: existingCode,
        friendCodeVersion: (existing?['friendCodeVersion'] as num?)?.toInt() ?? 1,
      );
    }

    final code = await _generateUniqueFriendCode();
    final version = 1;
    await _assignFriendCode(
      userId: user.id,
      code: code,
      version: version,
      user: user,
      previousCode: null,
    );

    return user.copyWith(friendCode: code, friendCodeVersion: version);
  }

  @override
  Future<FriendCodeInfo> getFriendCodeInfo({
    required String userId,
    required String userName,
    String? photoUrl,
  }) async {
    final existing = await _readUserRecord(userId);
    final existingCode = existing?['friendCode'] as String?;

    if (existingCode != null && existingCode.isNotEmpty) {
      final version = (existing?['friendCodeVersion'] as num?)?.toInt() ?? 1;
      return _toFriendCodeInfo(
        code: existingCode,
        version: version,
        userName: (existing?['name'] as String?) ?? userName,
        photoUrl: (existing?['photoUrl'] as String?) ?? photoUrl,
      );
    }

    final user = UserModel(
      id: userId,
      email: (existing?['email'] as String?) ?? '',
      name: userName,
      photoUrl: photoUrl,
    );
    final enriched = await ensureFriendCodeForUser(user);
    final code = enriched.friendCode;
    if (code == null || code.isEmpty) {
      throw const ServerException(message: 'Failed to load friend code');
    }

    return _toFriendCodeInfo(
      code: code,
      version: enriched.friendCodeVersion ?? 1,
      userName: enriched.name,
      photoUrl: enriched.photoUrl,
    );
  }

  @override
  Future<FriendCodeInfo> changeFriendCode({
    required String userId,
    required String userName,
    String? photoUrl,
  }) async {
    final existing = await _readUserRecord(userId);
    final previousCode = existing?['friendCode'] as String?;
    final previousVersion = (existing?['friendCodeVersion'] as num?)?.toInt() ?? 0;
    final newVersion = previousVersion + 1;
    final newCode = await _generateUniqueFriendCode();

    final user = UserModel(
      id: userId,
      email: (existing?['email'] as String?) ?? '',
      name: (existing?['name'] as String?) ?? userName,
      photoUrl: (existing?['photoUrl'] as String?) ?? photoUrl,
    );

    await _assignFriendCode(
      userId: userId,
      code: newCode,
      version: newVersion,
      user: user,
      previousCode: previousCode,
    );

    return _toFriendCodeInfo(
      code: newCode,
      version: newVersion,
      userName: user.name,
      photoUrl: user.photoUrl,
    );
  }

  FriendCodeInfo _toFriendCodeInfo({
    required String code,
    required int version,
    required String userName,
    String? photoUrl,
  }) {
    return FriendCodeInfo(
      code: code,
      version: version,
      inviteUrl: FriendCodeGenerator.buildInviteUrl(code),
      userName: userName,
      photoUrl: photoUrl,
    );
  }

  Future<Map<String, dynamic>?> _readUserRecord(String userId) async {
    final doc = await _firestoreService.getDocument(
      FirestorePaths.root,
      FirestorePaths.users,
    );
    final raw = doc.data()?[userId];
    if (raw is! Map) return null;
    return Map<String, dynamic>.from(raw);
  }

  Future<bool> _friendCodeExists(String code) async {
    final doc = await _firestoreService.getDocument(
      FirestorePaths.root,
      FirestorePaths.friendCodes,
    );
    final data = doc.data();
    if (data == null) return false;

    final entry = data[code];
    if (entry is! Map) return false;

    final model = FriendCodeEntryModel.fromJson(
      Map<String, dynamic>.from(entry),
    );
    return model.isActive;
  }

  Future<String> _generateUniqueFriendCode() async {
    for (var attempt = 0; attempt < _maxGenerationAttempts; attempt++) {
      final code = FriendCodeGenerator.generate();
      final exists = await _friendCodeExists(code);
      if (!exists) return code;
    }

    _logger.e('Failed to generate unique friend code after $_maxGenerationAttempts attempts');
    throw const ServerException(message: 'Could not generate a unique friend code');
  }

  Future<void> _assignFriendCode({
    required String userId,
    required String code,
    required int version,
    required UserModel user,
    required String? previousCode,
  }) async {
    final entry = FriendCodeEntryModel(
      userId: userId,
      isActive: true,
      version: version,
    );

    final userPayload = <String, dynamic>{
      userId: {
        ...user.toJson(),
        'friendCode': code,
        'friendCodeVersion': version,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    };

    final codePayload = <String, dynamic>{
      code: {
        ...entry.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    };

    if (previousCode != null && previousCode.isNotEmpty && previousCode != code) {
      codePayload[previousCode] = {
        'userId': userId,
        'isActive': false,
        'version': version - 1,
        'updatedAt': FieldValue.serverTimestamp(),
      };
    }

    await _firestoreService.setDocument(
      FirestorePaths.root,
      FirestorePaths.users,
      userPayload,
      merge: true,
    );

    await _firestoreService.setDocument(
      FirestorePaths.root,
      FirestorePaths.friendCodes,
      codePayload,
      merge: true,
    );
  }

  @override
  Future<UserPreview?> lookupUserByFriendCode(String code) async {
    final normalized = FriendCodeParser.parse(code);
    if (normalized == null) return null;

    final codesDoc = await _firestoreService.getDocument(
      FirestorePaths.root,
      FirestorePaths.friendCodes,
    );
    final entry = codesDoc.data()?[normalized];
    if (entry is! Map) return null;

    final friendCodeEntry = FriendCodeEntryModel.fromJson(
      Map<String, dynamic>.from(entry),
    );
    if (!friendCodeEntry.isActive) return null;

    final userData = await _readUserRecord(friendCodeEntry.userId);
    if (userData == null) return null;

    return UserPreview(
      id: friendCodeEntry.userId,
      name: (userData['name'] as String?) ?? 'Splitwise user',
      email: userData['email'] as String?,
      phone: userData['phone'] as String?,
      photoUrl: userData['photoUrl'] as String?,
      friendCode: normalized,
    );
  }

  @override
  Future<FriendInvitePreview> resolveInvitePreview({
    required String currentUserId,
    required String friendCode,
  }) async {
    final user = await lookupUserByFriendCode(friendCode);
    if (user == null) {
      return const FriendInvitePreview(
        resolution: FriendInviteResolution.userNotFound,
      );
    }

    if (user.id == currentUserId) {
      return FriendInvitePreview(
        resolution: FriendInviteResolution.self,
        user: user,
      );
    }

    if (await areFriends(currentUserId, user.id)) {
      return FriendInvitePreview(
        resolution: FriendInviteResolution.alreadyFriends,
        user: user,
      );
    }

    final outgoingId = '${currentUserId}_${user.id}';
    final incomingId = '${user.id}_$currentUserId';

    final outgoing = await _readFriendRequest(outgoingId);
    if (outgoing?.status == FriendRequestStatus.pending.name) {
      return FriendInvitePreview(
        resolution: FriendInviteResolution.outgoingPending,
        user: user,
        requestId: outgoingId,
      );
    }

    final incoming = await _readFriendRequest(incomingId);
    if (incoming?.status == FriendRequestStatus.pending.name) {
      return FriendInvitePreview(
        resolution: FriendInviteResolution.incomingPending,
        user: user,
        requestId: incomingId,
      );
    }

    return FriendInvitePreview(
      resolution: FriendInviteResolution.canSendRequest,
      user: user,
    );
  }

  @override
  Future<bool> areFriends(String uid1, String uid2) async {
    final friendshipId = FriendshipIdHelper.forUsers(uid1, uid2);
    final doc = await _firestoreService.getDocument(
      FirestorePaths.root,
      FirestorePaths.friends,
    );
    return doc.data()?[friendshipId] is Map;
  }

  @override
  Future<void> sendFriendRequest({
    required String fromUserId,
    required String toUserId,
  }) async {
    if (fromUserId == toUserId) {
      throw const ServerException(message: 'You cannot add yourself as a friend');
    }

    if (await _isBlockedEither(fromUserId, toUserId)) {
      throw const ServerException(message: 'This user is unavailable');
    }

    if (await areFriends(fromUserId, toUserId)) {
      throw const ServerException(message: 'You are already friends');
    }

    final requestId = '${fromUserId}_$toUserId';
    final existing = await _readFriendRequest(requestId);
    if (existing?.status == FriendRequestStatus.pending.name) {
      return;
    }

    final reverseId = '${toUserId}_$fromUserId';
    final reverse = await _readFriendRequest(reverseId);
    if (reverse?.status == FriendRequestStatus.pending.name) {
      throw const ServerException(
        message: 'This person already sent you a friend request',
      );
    }

    final model = FriendRequestModel(
      id: requestId,
      fromUserId: fromUserId,
      toUserId: toUserId,
      status: FriendRequestStatus.pending.name,
    );

    await _firestoreService.setDocument(
      FirestorePaths.root,
      FirestorePaths.friendRequests,
      {
        requestId: {
          ...model.toJson(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      },
      merge: true,
    );
  }

  @override
  Future<void> acceptFriendRequest({
    required String requestId,
    required String userId,
  }) async {
    final request = await _readFriendRequest(requestId);
    if (request == null) {
      throw const ServerException(message: 'Friend request not found');
    }
    if (request.toUserId != userId) {
      throw const ServerException(message: 'Not authorized to accept this request');
    }
    if (request.status != FriendRequestStatus.pending.name) {
      throw const ServerException(message: 'Friend request is no longer pending');
    }

    final friendshipId = FriendshipIdHelper.forUsers(
      request.fromUserId,
      request.toUserId,
    );
    final friendship = FriendshipModel(
      id: friendshipId,
      userIds: FriendshipIdHelper.sortedUserIds(
        request.fromUserId,
        request.toUserId,
      ),
    );

    await _firestoreService.setDocument(
      FirestorePaths.root,
      FirestorePaths.friendRequests,
      {
        requestId: {
          ...request.toJson(),
          'status': FriendRequestStatus.accepted.name,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      },
      merge: true,
    );

    await _firestoreService.setDocument(
      FirestorePaths.root,
      FirestorePaths.friends,
      {
        friendshipId: {
          ...friendship.toJson(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      },
      merge: true,
    );
  }

  @override
  Future<void> declineFriendRequest({
    required String requestId,
    required String userId,
  }) async {
    final request = await _readFriendRequest(requestId);
    if (request == null) {
      throw const ServerException(message: 'Friend request not found');
    }
    if (request.toUserId != userId) {
      throw const ServerException(message: 'Not authorized to decline this request');
    }
    if (request.status != FriendRequestStatus.pending.name) {
      throw const ServerException(message: 'Friend request is no longer pending');
    }

    await _firestoreService.setDocument(
      FirestorePaths.root,
      FirestorePaths.friendRequests,
      {
        requestId: {
          ...request.toJson(),
          'status': FriendRequestStatus.declined.name,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      },
      merge: true,
    );
  }

  @override
  Future<List<FriendRequest>> getIncomingFriendRequests(String userId) async {
    final doc = await _firestoreService.getDocument(
      FirestorePaths.root,
      FirestorePaths.friendRequests,
    );
    final data = doc.data();
    if (data == null) return [];

    final blockedIds = await getBlockedUserIds(userId);
    final requests = <FriendRequest>[];
    for (final entry in data.entries) {
      if (entry.value is! Map) continue;
      final model = FriendRequestModel.fromJson(
        Map<String, dynamic>.from(entry.value as Map),
      );
      if (model.toUserId != userId ||
          model.status != FriendRequestStatus.pending.name) {
        continue;
      }
      if (blockedIds.contains(model.fromUserId)) continue;

      final fromUser = await _readUserRecord(model.fromUserId);
      requests.add(
        model.toEntity(
          fromUserName: fromUser?['name'] as String?,
          fromUserPhotoUrl: fromUser?['photoUrl'] as String?,
        ),
      );
    }
    return requests;
  }

  @override
  Future<List<UserPreview>> getFriends(String userId) async {
    final doc = await _firestoreService.getDocument(
      FirestorePaths.root,
      FirestorePaths.friends,
    );
    final data = doc.data();
    if (data == null) return [];

    final friendUserIds = <String>{};
    for (final entry in data.entries) {
      if (entry.value is! Map) continue;
      final model = FriendshipModel.fromJson(
        Map<String, dynamic>.from(entry.value as Map),
      );
      if (!model.userIds.contains(userId)) continue;
      final otherId = FriendshipIdHelper.otherUserId(model.userIds, userId);
      if (otherId != null) friendUserIds.add(otherId);
    }

    final blockedIds = await getBlockedUserIds(userId);
    final friends = <UserPreview>[];
    for (final friendId in friendUserIds) {
      if (blockedIds.contains(friendId)) continue;
      final userData = await _readUserRecord(friendId);
      final rawName = userData?['name'] as String?;
      final name = (rawName != null &&
              rawName.trim().isNotEmpty &&
              rawName.trim() != friendId)
          ? rawName.trim()
          : 'Splitwise user';
      friends.add(
        UserPreview(
          id: friendId,
          name: name,
          email: userData?['email'] as String?,
          phone: userData?['phone'] as String?,
          photoUrl: userData?['photoUrl'] as String?,
          friendCode: (userData?['friendCode'] as String?) ?? '',
          isPending: userData?['isPendingUser'] == true,
        ),
      );
    }

    friends.sort((a, b) => a.name.compareTo(b.name));
    return friends;
  }

  @override
  Future<void> addFriendDirectly({
    required String currentUserId,
    required String friendUserId,
  }) async {
    if (currentUserId == friendUserId) {
      throw const ServerException(message: 'You cannot add yourself as a friend');
    }

    if (await _isBlockedEither(currentUserId, friendUserId)) {
      throw const ServerException(message: 'This user is unavailable');
    }

    await _createFriendship(currentUserId, friendUserId);
  }

  Future<void> _createFriendship(String userIdA, String userIdB) async {
    if (await areFriends(userIdA, userIdB)) return;

    final friendshipId = FriendshipIdHelper.forUsers(userIdA, userIdB);
    final friendship = FriendshipModel(
      id: friendshipId,
      userIds: FriendshipIdHelper.sortedUserIds(userIdA, userIdB),
    );

    await _firestoreService.setDocument(
      FirestorePaths.root,
      FirestorePaths.friends,
      {
        friendshipId: {
          ...friendship.toJson(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      },
      merge: true,
    );
  }

  @override
  Future<void> removeFriend({
    required String currentUserId,
    required String friendUserId,
  }) async {
    final friendshipId = FriendshipIdHelper.forUsers(
      currentUserId,
      friendUserId,
    );

    try {
      await _firestoreService.updateDocument(
        FirestorePaths.root,
        FirestorePaths.friends,
        {friendshipId: FieldValue.delete()},
      );
    } catch (_) {
      // No real friendship document to delete (e.g. this "friend" is only a
      // pending/shadow contact) — fall through and clean that up instead.
    }

    await _removePendingContactIfAny(
      ownerUserId: currentUserId,
      contactId: friendUserId,
    );
  }

  /// Deletes the pending-contact invite (and its shadow user/friend-code
  /// records) owned by [ownerUserId] for [contactId], if one exists. This is
  /// what actually makes "Remove from friends list" work for contacts that
  /// were added but never turned into a real Splitwise account.
  Future<void> _removePendingContactIfAny({
    required String ownerUserId,
    required String contactId,
  }) async {
    final pendingDoc = await _firestoreService.getDocument(
      FirestorePaths.root,
      FirestorePaths.pendingContacts,
    );
    final pendingData = pendingDoc.data();
    if (pendingData == null) return;

    String? matchedKey;
    for (final entry in pendingData.entries) {
      if (entry.value is! Map) continue;
      final map = Map<String, dynamic>.from(entry.value as Map);
      final id = (map['id'] as String?) ?? entry.key;
      final ownerId = map['ownerUserId'] as String?;
      if (id == contactId && ownerId == ownerUserId) {
        matchedKey = entry.key;
        break;
      }
    }

    if (matchedKey == null) return;

    await _firestoreService.updateDocument(
      FirestorePaths.root,
      FirestorePaths.pendingContacts,
      {matchedKey: FieldValue.delete()},
    );

    final shadowUser = await _readUserRecord(contactId);
    if (shadowUser != null && shadowUser['isPendingUser'] == true) {
      await _firestoreService.updateDocument(
        FirestorePaths.root,
        FirestorePaths.users,
        {contactId: FieldValue.delete()},
      );

      final code = shadowUser['friendCode'] as String?;
      if (code != null && code.isNotEmpty) {
        await _firestoreService.updateDocument(
          FirestorePaths.root,
          FirestorePaths.friendCodes,
          {code: FieldValue.delete()},
        );
      }
    }
  }

  @override
  Future<UserPreview?> findUserByEmailOrPhone({
    String? email,
    String? phone,
  }) async {
    final normalizedEmail = email?.trim().toLowerCase();
    final normalizedPhoneDigits =
        phone?.replaceAll(RegExp(r'\D'), '').trim();

    if ((normalizedEmail == null || normalizedEmail.isEmpty) &&
        (normalizedPhoneDigits == null || normalizedPhoneDigits.isEmpty)) {
      return null;
    }

    final doc = await _firestoreService.getDocument(
      FirestorePaths.root,
      FirestorePaths.users,
    );
    final data = doc.data();
    if (data == null) return null;

    for (final entry in data.entries) {
      final raw = entry.value;
      if (raw is! Map) continue;
      final userMap = Map<String, dynamic>.from(raw);

      final userEmail = (userMap['email'] as String?)?.trim().toLowerCase();
      if (normalizedEmail != null &&
          normalizedEmail.isNotEmpty &&
          userEmail != null &&
          userEmail.isNotEmpty &&
          userEmail == normalizedEmail) {
        return UserPreview(
          id: entry.key,
          name: (userMap['name'] as String?) ?? 'Splitwise user',
          email: userEmail,
          photoUrl: userMap['photoUrl'] as String?,
          friendCode: (userMap['friendCode'] as String?) ?? '',
        );
      }

      final userPhoneDigits = (userMap['phone'] as String?)
          ?.replaceAll(RegExp(r'\D'), '')
          .trim();
      if (normalizedPhoneDigits != null &&
          normalizedPhoneDigits.isNotEmpty &&
          userPhoneDigits != null &&
          userPhoneDigits.isNotEmpty &&
          userPhoneDigits == normalizedPhoneDigits) {
        return UserPreview(
          id: entry.key,
          name: (userMap['name'] as String?) ?? 'Splitwise user',
          email: userMap['email'] as String?,
          photoUrl: userMap['photoUrl'] as String?,
          friendCode: (userMap['friendCode'] as String?) ?? '',
        );
      }
    }

    return null;
  }

  @override
  Future<void> createPendingContact({
    required String ownerUserId,
    required String displayName,
    String? email,
    String? phone,
  }) async {
    final trimmedName = displayName.trim();
    final normalizedEmail = email?.trim().toLowerCase();
    final normalizedPhoneDigits = phone?.replaceAll(RegExp(r'\D'), '').trim();

    if (trimmedName.isEmpty) {
      throw const ServerException(message: 'Name is required');
    }
    if ((normalizedEmail == null || normalizedEmail.isEmpty) &&
        (normalizedPhoneDigits == null || normalizedPhoneDigits.isEmpty)) {
      throw const ServerException(message: 'Phone or email is required');
    }

    final doc = await _firestoreService.getDocument(
      FirestorePaths.root,
      FirestorePaths.pendingContacts,
    );
    final data = doc.data();

    // Reuse an existing pending invite from the same owner to the same
    // email/phone instead of creating a duplicate — Splitwise reuses the
    // previously stored display name for repeat invites.
    String? existingId;
    if (data != null) {
      for (final entry in data.entries) {
        if (entry.value is! Map) continue;
        final map = Map<String, dynamic>.from(entry.value as Map);
        if ((map['ownerUserId'] as String?) != ownerUserId) continue;
        if ((map['status'] as String?) != 'pending') continue;

        final entryEmail = (map['email'] as String?)?.trim().toLowerCase();
        final entryPhoneDigits =
            (map['phone'] as String?)?.replaceAll(RegExp(r'\D'), '').trim();

        final emailMatches = normalizedEmail != null &&
            normalizedEmail.isNotEmpty &&
            entryEmail == normalizedEmail;
        final phoneMatches = normalizedPhoneDigits != null &&
            normalizedPhoneDigits.isNotEmpty &&
            entryPhoneDigits == normalizedPhoneDigits;

        if (emailMatches || phoneMatches) {
          existingId = (map['id'] as String?) ?? entry.key;
          break;
        }
      }
    }

    final id = existingId ?? _uuid.v4();
    final payload = <String, dynamic>{
      id: {
        'id': id,
        'ownerUserId': ownerUserId,
        'displayName': trimmedName,
        'email': normalizedEmail,
        'phone': normalizedPhoneDigits,
        'status': 'pending',
        'friendUserId': null,
        if (existingId == null) 'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    };

    await _firestoreService.setDocument(
      FirestorePaths.root,
      FirestorePaths.pendingContacts,
      payload,
      merge: true,
    );

    // Mirror a lightweight "shadow" record into the `users` table under the
    // same id so friend details can be fetched the same way as real users
    // (e.g. via getUserById), even before this contact has a real account.
    // Reuse the existing friend code on repeat invites; otherwise generate
    // and register a fresh one, same as a real user would get.
    final existingShadowUser = await _readUserRecord(id);
    var shadowFriendCode = existingShadowUser?['friendCode'] as String?;

    if (shadowFriendCode == null || shadowFriendCode.isEmpty) {
      shadowFriendCode = await _generateUniqueFriendCode();
      await _firestoreService.setDocument(
        FirestorePaths.root,
        FirestorePaths.friendCodes,
        {
          shadowFriendCode: {
            'userId': id,
            'isActive': true,
            'version': 1,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        },
        merge: true,
      );
    }

    await _firestoreService.setDocument(
      FirestorePaths.root,
      FirestorePaths.users,
      {
        id: {
          'id': id,
          'name': trimmedName,
          'email': normalizedEmail,
          'phone': normalizedPhoneDigits,
          'photoUrl': null,
          'friendCode': shadowFriendCode,
          'friendCodeVersion': 1,
          'isPendingUser': true,
          if (existingId == null) 'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      },
      merge: true,
    );
  }

  @override
  Future<List<UserPreview>> getPendingContacts(String ownerUserId) async {
    final doc = await _firestoreService.getDocument(
      FirestorePaths.root,
      FirestorePaths.pendingContacts,
    );
    final data = doc.data();
    if (data == null) return [];

    final usersDoc = await _firestoreService.getDocument(
      FirestorePaths.root,
      FirestorePaths.users,
    );
    final usersData = usersDoc.data();
    final blockedIds = await getBlockedUserIds(ownerUserId);

    final items = <UserPreview>[];
    final seenEmails = <String>{};
    final seenPhones = <String>{};
    for (final entry in data.entries) {
      if (entry.value is! Map) continue;
      final map = Map<String, dynamic>.from(entry.value as Map);
      if ((map['ownerUserId'] as String?) != ownerUserId) continue;
      if ((map['status'] as String?) != 'pending') continue;
      // Already linked to a real account — don't show as a second friends row.
      if (map['friendUserId'] != null) continue;

      final id = (map['id'] as String?) ?? entry.key;
      if (blockedIds.contains(id)) continue;

      final email = (map['email'] as String?)?.trim().toLowerCase();
      final phoneDigits =
          (map['phone'] as String?)?.replaceAll(RegExp(r'\D'), '').trim() ?? '';
      if (email != null && email.isNotEmpty && !seenEmails.add(email)) continue;
      if (phoneDigits.length >= 8 && !seenPhones.add(phoneDigits)) continue;

      final shadowUser = usersData?[id];
      final friendCode = shadowUser is Map
          ? (shadowUser['friendCode'] as String?) ?? ''
          : '';

      items.add(
        UserPreview(
          id: id,
          name: (map['displayName'] as String?) ?? 'Pending friend',
          friendCode: friendCode,
          email: map['email'] as String?,
          phone: map['phone'] as String?,
          isPending: true,
        ),
      );
    }

    items.sort((a, b) => a.name.compareTo(b.name));
    return items;
  }

  @override
  Future<void> linkPendingContactsForUser({
    required String userId,
    String? email,
    String? phone,
  }) async {
    final normalizedEmail = email?.trim().toLowerCase();
    final normalizedPhoneDigits = phone?.replaceAll(RegExp(r'\D'), '').trim();

    if ((normalizedEmail == null || normalizedEmail.isEmpty) &&
        (normalizedPhoneDigits == null || normalizedPhoneDigits.isEmpty)) {
      return;
    }

    final doc = await _firestoreService.getDocument(
      FirestorePaths.root,
      FirestorePaths.pendingContacts,
    );
    final data = doc.data();
    if (data == null) return;

    final updates = <String, dynamic>{};

    for (final entry in data.entries) {
      if (entry.value is! Map) continue;
      final map = Map<String, dynamic>.from(entry.value as Map);
      if ((map['status'] as String?) != 'pending') continue;
      if (map['friendUserId'] != null) continue;

      final ownerUserId = map['ownerUserId'] as String?;
      if (ownerUserId == null || ownerUserId == userId) continue;

      final entryEmail = (map['email'] as String?)?.trim().toLowerCase();
      final entryPhoneDigits =
          (map['phone'] as String?)?.replaceAll(RegExp(r'\D'), '').trim();

      final emailMatches = normalizedEmail != null &&
          normalizedEmail.isNotEmpty &&
          entryEmail == normalizedEmail;
      final phoneMatches = normalizedPhoneDigits != null &&
          normalizedPhoneDigits.isNotEmpty &&
          entryPhoneDigits == normalizedPhoneDigits;

      if (!emailMatches && !phoneMatches) continue;
      if (await _isBlockedEither(ownerUserId, userId)) continue;

      await _createFriendship(ownerUserId, userId);

      final key = (map['id'] as String?) ?? entry.key;
      updates[key] = {
        ...map,
        'status': 'linked',
        'friendUserId': userId,
        'updatedAt': FieldValue.serverTimestamp(),
      };
    }

    if (updates.isNotEmpty) {
      await _firestoreService.setDocument(
        FirestorePaths.root,
        FirestorePaths.pendingContacts,
        updates,
        merge: true,
      );
    }
  }

  @override
  Future<UserPreview?> getUserById(String userId) async {
    final userData = await _readUserRecord(userId);
    if (userData == null) return null;

    return UserPreview(
      id: userId,
      name: (userData['name'] as String?) ?? 'Splitwise user',
      email: userData['email'] as String?,
      phone: userData['phone'] as String?,
      photoUrl: userData['photoUrl'] as String?,
      friendCode: (userData['friendCode'] as String?) ?? '',
      isPending: userData['isPendingUser'] == true,
    );
  }

  @override
  Future<Set<String>> getBlockedUserIds(String currentUserId) {
    return BlockedUsersStore.idsBlockedBy(_firestoreService, currentUserId);
  }

  @override
  Future<void> blockUser({
    required String currentUserId,
    required String blockedUserId,
  }) async {
    if (currentUserId == blockedUserId) {
      throw const ServerException(message: 'You cannot block yourself');
    }

    final blockedPreview = await getUserById(blockedUserId);
    final blockedUserName =
        (blockedPreview?.name.trim().isNotEmpty ?? false)
            ? blockedPreview!.name.trim()
            : 'Splitwise user';

    final id = BlockedUsersStore.blockId(currentUserId, blockedUserId);
    await _firestoreService.setDocument(
      FirestorePaths.root,
      FirestorePaths.blockedUsers,
      {
        id: {
          'id': id,
          'ownerId': currentUserId,
          'blockedUserId': blockedUserId,
          'blockedUserName': blockedUserName,
          'createdAt': FieldValue.serverTimestamp(),
        },
      },
      merge: true,
    );

    await removeFriend(
      currentUserId: currentUserId,
      friendUserId: blockedUserId,
    );

    await ActivityEventWriter.appendDirect(
      _firestoreService.firestore,
      ActivityEventWriter.userBlocked(
        actorUserId: currentUserId,
        blockedUserId: blockedUserId,
        blockedUserName: blockedUserName,
      ),
    );
  }

  @override
  Future<void> unblockUser({
    required String currentUserId,
    required String blockedUserId,
  }) async {
    final id = BlockedUsersStore.blockId(currentUserId, blockedUserId);

    String? savedName;
    try {
      final blockedDoc = await _firestoreService.getDocument(
        FirestorePaths.root,
        FirestorePaths.blockedUsers,
      );
      final raw = blockedDoc.data()?[id];
      if (raw is Map) {
        savedName = (raw['blockedUserName'] as String?)?.trim();
      }
    } catch (_) {}

    try {
      await _firestoreService.updateDocument(
        FirestorePaths.root,
        FirestorePaths.blockedUsers,
        {id: FieldValue.delete()},
      );
    } catch (_) {}

    // Blocking removes the friendship — restore it on unblock so the person
    // reappears on Friends and shared balances resolve to a real profile.
    final existing = await _readUserRecord(blockedUserId);
    final existingName = (existing?['name'] as String?)?.trim();
    final needsName = existing == null ||
        existingName == null ||
        existingName.isEmpty ||
        existingName == blockedUserId;

    if (needsName && savedName != null && savedName.isNotEmpty) {
      await _firestoreService.setDocument(
        FirestorePaths.root,
        FirestorePaths.users,
        {
          blockedUserId: {
            'id': blockedUserId,
            'name': savedName,
            if (existing == null) 'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        },
        merge: true,
      );
    }

    await _createFriendship(currentUserId, blockedUserId);

    final unblockedName = (savedName != null && savedName.isNotEmpty)
        ? savedName
        : ((existing?['name'] as String?)?.trim().isNotEmpty == true
            ? (existing!['name'] as String).trim()
            : 'Splitwise user');

    await ActivityEventWriter.appendDirect(
      _firestoreService.firestore,
      ActivityEventWriter.userUnblocked(
        actorUserId: currentUserId,
        unblockedUserId: blockedUserId,
        unblockedUserName: unblockedName,
      ),
    );
  }

  @override
  Future<List<UserPreview>> getBlockedUsers(String currentUserId) async {
    final nameById = await BlockedUsersStore.namesBlockedBy(
      _firestoreService,
      currentUserId,
    );
    final users = <UserPreview>[];
    for (final entry in nameById.entries) {
      final preview = await getUserById(entry.key);
      if (preview != null && preview.name.trim().isNotEmpty) {
        users.add(preview);
      } else {
        users.add(
          UserPreview(
            id: entry.key,
            name: entry.value,
            friendCode: '',
          ),
        );
      }
    }
    users.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return users;
  }

  Future<bool> _isBlockedEither(String userIdA, String userIdB) async {
    final aBlocked = await getBlockedUserIds(userIdA);
    if (aBlocked.contains(userIdB)) return true;
    final bBlocked = await getBlockedUserIds(userIdB);
    return bBlocked.contains(userIdA);
  }

  Future<FriendRequestModel?> _readFriendRequest(String requestId) async {
    final doc = await _firestoreService.getDocument(
      FirestorePaths.root,
      FirestorePaths.friendRequests,
    );
    final raw = doc.data()?[requestId];
    if (raw is! Map) return null;
    return FriendRequestModel.fromJson(Map<String, dynamic>.from(raw));
  }
}
