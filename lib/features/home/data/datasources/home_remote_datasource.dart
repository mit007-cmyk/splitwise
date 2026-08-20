import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/utils/activity_event_writer.dart';
import '../../../../core/utils/blocked_users_store.dart';
import '../../../../core/utils/currency_amount.dart';
import '../../../../core/utils/group_balance_calculator.dart';
import '../../../../core/utils/user_display_names.dart';
import '../../../auth/data/models/user_model.dart';
import '../../domain/entities/balance_summary.dart';
import '../models/balance_summary_model.dart';
import '../models/group_summary_model.dart';
import '../models/home_summary_model.dart';

abstract class HomeRemoteDataSource {
  Future<HomeSummaryModel> getHomeSummary(String userId);
  Future<void> createGroup({required String groupId, required Map<String, dynamic> data});
  Future<void> ensureGroupExists({
    required String groupId,
    required String name,
    required String type,
    required List<String> memberIds,
  });
  Future<List<UserModel>> getAllUsers();
  Future<void> addContact({
    required String name,
    String? phone,
    String? email,
  });
  Future<void> addGroupMembers({
    required String groupId,
    required List<String> memberIds,
    required String actorUserId,
  });
  Future<void> editGroup({
    required String groupId,
    required String name,
    required String type,
    required String actorUserId,
  });
  Future<void> updateSimplifyDebts({
    required String groupId,
    required bool enabled,
    required String actorUserId,
  });
  Future<void> leaveGroup({
    required String groupId,
    required String userId,
    required String actorUserId,
  });
  Future<void> deleteGroup({
    required String groupId,
    required String actorUserId,
  });
}

@LazySingleton(as: HomeRemoteDataSource)
class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final FirestoreService _firestoreService;

  HomeRemoteDataSourceImpl(this._firestoreService);

  Map<String, dynamic>? _asStringKeyMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  void _readAmountMap(
    dynamic raw,
    void Function(String userId, double amount) onEntry,
  ) {
    final map = _asStringKeyMap(raw);
    if (map == null) return;
    map.forEach((key, value) {
      final id = key.toString().trim();
      if (id.isEmpty) return;
      onEntry(id, (value as num?)?.toDouble() ?? 0.0);
    });
  }

  @override
  Future<void> createGroup({required String groupId, required Map<String, dynamic> data}) async {
    final firestore = _firestoreService.firestore;
    final groupsRef = firestore.collection(FirestorePaths.root).doc(FirestorePaths.groups);
    final eventsRef = ActivityEventWriter.eventsRef(firestore);

    await _firestoreService.runTransaction((transaction) async {
      transaction.set(groupsRef, {groupId: data}, SetOptions(merge: true));
      ActivityEventWriter.append(
        transaction,
        eventsRef,
        ActivityEventWriter.groupCreated(groupId: groupId, groupData: data),
      );
    });
  }

  @override
  Future<void> ensureGroupExists({
    required String groupId,
    required String name,
    required String type,
    required List<String> memberIds,
  }) async {
    final groupsDoc = await _firestoreService.getDocument('Splitwise', 'groups');
    final groupsData = groupsDoc.data();
    final existing = groupsData?[groupId];
    if (existing is Map && existing['members'] is List && (existing['members'] as List).isNotEmpty) {
      return;
    }

    await _firestoreService.setDocument(
      'Splitwise',
      'groups',
      {
        groupId: {
          'id': groupId,
          'name': name,
          'type': type,
          'createdBy': memberIds.isNotEmpty ? memberIds.first : '',
          'members': memberIds,
          'simplifyDebts': true,
          'createdAt': FieldValue.serverTimestamp(),
        },
      },
      merge: true,
    );
  }

  @override
  Future<List<UserModel>> getAllUsers() async {
    try {
      final usersDoc = await _firestoreService.getDocument('Splitwise', 'users');
      final usersData = usersDoc.data();
      if (usersData == null) return [];
      
      final List<UserModel> list = [];
      for (final entry in usersData.entries) {
        final uId = entry.key;
        final uData = _asStringKeyMap(entry.value);
        if (uData != null) {
          list.add(UserModel(
            id: uId,
            email: uData['email'] as String? ?? uData['phone'] as String? ?? '',
            name: uData['name'] as String? ??
                ((uData['email'] as String?)?.contains('@') == true
                    ? (uData['email'] as String).split('@').first
                    : 'Splitwise user'),
            photoUrl: uData['photoUrl'] as String?,
          ));
        }
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> addContact({
    required String name,
    String? phone,
    String? email,
  }) async {
    final friendId = const Uuid().v4();
    final friendData = {
      'id': friendId,
      'name': name.trim(),
      if (phone != null && phone.isNotEmpty) 'phone': phone.trim(),
      if (email != null && email.isNotEmpty) 'email': email.trim(),
      'photoUrl': null,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _firestoreService.setDocument(
      'Splitwise',
      'users',
      {
        friendId: friendData,
      },
      merge: true,
    );
  }

  @override
  Future<void> addGroupMembers({
    required String groupId,
    required List<String> memberIds,
    required String actorUserId,
  }) async {
    final groupsDoc = await _firestoreService.getDocument('Splitwise', 'groups');
    final groupsData = groupsDoc.data();
    if (groupsData == null || !groupsData.containsKey(groupId)) {
      throw Exception('Group not found');
    }

    final groupMap = _asStringKeyMap(groupsData[groupId]);
    if (groupMap == null) {
      throw Exception('Group not found');
    }
    final List<dynamic> currentMembers = List.from(groupMap['members'] as List? ?? []);
    final memberSet = currentMembers.map((e) => e.toString()).toSet();
    final addedIds = <String>[];

    for (final id in memberIds) {
      final trimmed = id.trim();
      if (trimmed.isEmpty || memberSet.contains(trimmed)) continue;
      memberSet.add(trimmed);
      currentMembers.add(trimmed);
      addedIds.add(trimmed);
    }

    if (addedIds.isEmpty) return;

    groupMap['members'] = currentMembers;
    final groupName = (groupMap['name'] as String?) ?? 'group';

    await _firestoreService.setDocument(
      'Splitwise',
      'groups',
      {
        groupId: groupMap,
      },
      merge: true,
    );

    final displayNames = await UserDisplayNames.load(_firestoreService);
    final visibility = currentMembers
        .map((id) => id.toString().trim())
        .where((id) => id.isNotEmpty)
        .toList();

    final usersDoc = await _firestoreService.getDocument('Splitwise', 'users');
    final usersData = usersDoc.data();

    for (final memberId in addedIds) {
      final userRaw = usersData?[memberId];
      final invited = userRaw is Map && userRaw['isPendingUser'] == true;
      await ActivityEventWriter.appendDirect(
        _firestoreService.firestore,
        ActivityEventWriter.memberAddedToGroup(
          groupId: groupId,
          groupName: groupName,
          actorUserId: actorUserId,
          memberUserId: memberId,
          memberName: UserDisplayNames.resolve(displayNames, memberId),
          visibilityUserIds: visibility,
          invited: invited,
        ),
      );
    }
  }

  @override
  Future<void> editGroup({
    required String groupId,
    required String name,
    required String type,
    required String actorUserId,
  }) async {
    final groupsDoc = await _firestoreService.getDocument('Splitwise', 'groups');
    final groupsData = groupsDoc.data();
    if (groupsData == null || !groupsData.containsKey(groupId)) {
      throw Exception('Group not found');
    }

    final groupMap = _asStringKeyMap(groupsData[groupId]);
    if (groupMap == null) {
      throw Exception('Group not found');
    }
    final previousName = (groupMap['name'] as String?) ?? '';
    final previousType = (groupMap['type'] as String?) ?? '';
    final nextName = name.trim();
    final nextType = type.trim();
    final changed = <String>[];
    if (previousName != nextName) changed.add('name');
    if (previousType != nextType) changed.add('type');

    groupMap['name'] = nextName;
    groupMap['type'] = nextType;

    await _firestoreService.setDocument(
      'Splitwise',
      'groups',
      {
        groupId: groupMap,
      },
      merge: true,
    );

    if (changed.isEmpty) return;

    await ActivityEventWriter.appendDirect(
      _firestoreService.firestore,
      ActivityEventWriter.groupUpdated(
        groupId: groupId,
        actorUserId: actorUserId,
        groupName: nextName,
        previousGroupName: previousName,
        changedFields: changed,
        visibilityUserIds: ActivityEventWriter.memberIdsFromGroup(groupMap),
        extraMetadata: {
          'groupType': nextType,
          'previousGroupType': previousType,
        },
      ),
    );
  }

  @override
  Future<void> updateSimplifyDebts({
    required String groupId,
    required bool enabled,
    required String actorUserId,
  }) async {
    final groupsDoc = await _firestoreService.getDocument('Splitwise', 'groups');
    final groupsData = groupsDoc.data();
    if (groupsData == null || !groupsData.containsKey(groupId)) {
      throw Exception('Group not found');
    }

    final groupMap = _asStringKeyMap(groupsData[groupId]);
    if (groupMap == null) {
      throw Exception('Group not found');
    }
    final previous = groupMap['simplifyDebts'] as bool? ?? true;
    groupMap['simplifyDebts'] = enabled;

    await _firestoreService.setDocument(
      'Splitwise',
      'groups',
      {
        groupId: groupMap,
      },
      merge: true,
    );

    if (previous == enabled) return;

    final groupName = (groupMap['name'] as String?) ?? 'group';
    await ActivityEventWriter.appendDirect(
      _firestoreService.firestore,
      ActivityEventWriter.groupUpdated(
        groupId: groupId,
        actorUserId: actorUserId,
        groupName: groupName,
        changedFields: const ['simplifyDebts'],
        visibilityUserIds: ActivityEventWriter.memberIdsFromGroup(groupMap),
        extraMetadata: {
          'simplifyDebts': enabled,
        },
      ),
    );
  }

  @override
  Future<void> leaveGroup({
    required String groupId,
    required String userId,
    required String actorUserId,
  }) async {
    final groupsDoc = await _firestoreService.getDocument('Splitwise', 'groups');
    final groupsData = groupsDoc.data();
    if (groupsData == null || !groupsData.containsKey(groupId)) {
      return;
    }

    final groupMap = _asStringKeyMap(groupsData[groupId]);
    if (groupMap == null) {
      return;
    }
    final List<dynamic> currentMembers = List.from(groupMap['members'] as List? ?? []);
    final wasMember = currentMembers.any((id) => id.toString() == userId);
    if (!wasMember) return;

    currentMembers.removeWhere((id) => id.toString() == userId);
    final groupName = (groupMap['name'] as String?) ?? 'group';
    final remainingIds = currentMembers
        .map((id) => id.toString().trim())
        .where((id) => id.isNotEmpty)
        .toList();

    if (remainingIds.isEmpty) {
      await _firestoreService.setDocument(
        'Splitwise',
        'groups',
        {
          groupId: FieldValue.delete(),
        },
        merge: true,
      );
    } else {
      groupMap['members'] = currentMembers;
      await _firestoreService.setDocument(
        'Splitwise',
        'groups',
        {
          groupId: groupMap,
        },
        merge: true,
      );
    }

    final displayNames = await UserDisplayNames.load(_firestoreService);
    final visibility = <String>{
      ...remainingIds,
      userId,
      actorUserId,
    }.where((id) => id.trim().isNotEmpty).toList();

    await ActivityEventWriter.appendDirect(
      _firestoreService.firestore,
      ActivityEventWriter.memberLeftGroup(
        groupId: groupId,
        groupName: groupName,
        actorUserId: actorUserId,
        memberUserId: userId,
        memberName: UserDisplayNames.resolve(displayNames, userId),
        visibilityUserIds: visibility,
        removed: actorUserId.trim() != userId.trim(),
      ),
    );
  }

  @override
  Future<void> deleteGroup({
    required String groupId,
    required String actorUserId,
  }) async {
    final firestore = _firestoreService.firestore;
    final groupsRef = firestore.collection(FirestorePaths.root).doc(FirestorePaths.groups);
    final eventsRef = ActivityEventWriter.eventsRef(firestore);

    await _firestoreService.runTransaction((transaction) async {
      final groupsSnap = await transaction.get(groupsRef);
      final groupsData = groupsSnap.data();
      if (groupsData == null || !groupsData.containsKey(groupId)) {
        throw StateError('Group not found.');
      }

      final groupMap = _asStringKeyMap(groupsData[groupId]);
      if (groupMap == null) {
        throw StateError('Group not found.');
      }

      final memberIds = ActivityEventWriter.memberIdsFromGroup(groupMap);
      if (!memberIds.contains(actorUserId.trim())) {
        throw StateError('You are not a member of this group.');
      }

      transaction.set(
        groupsRef,
        {groupId: FieldValue.delete()},
        SetOptions(merge: true),
      );
      ActivityEventWriter.append(
        transaction,
        eventsRef,
        ActivityEventWriter.groupDeleted(
          groupId: groupId,
          groupData: groupMap,
          actorUserId: actorUserId,
        ),
      );
    });
  }

  @override
  Future<HomeSummaryModel> getHomeSummary(String userId) async {
    // 1. Resolve display names (users + pending contacts — never raw ids).
    final allUserNames = await UserDisplayNames.load(_firestoreService);

    // 2. Fetch the groups document from Firestore 'Splitwise/groups'
    final DocumentSnapshot<Map<String, dynamic>> groupsDoc;
    try {
      groupsDoc = await _firestoreService.getDocument('Splitwise', 'groups');
    } catch (_) {
      return const HomeSummaryModel(
        overallBalance: BalanceSummaryModel(amount: 0.0, type: BalanceType.settled),
        groups: [],
      );
    }

    final groupsData = groupsDoc.data();
    if (groupsData == null) {
      return const HomeSummaryModel(
        overallBalance: BalanceSummaryModel(amount: 0.0, type: BalanceType.settled),
        groups: [],
      );
    }

    final List<GroupSummaryModel> groupsList = [];
    final overallAmounts = <CurrencyAmount>[];
    final topLevelExpensesByGroup = <String, List<Map<String, dynamic>>>{};

    // Preferred schema: Splitwise/expenses document (expense id -> map).
    try {
      final expensesDoc = await _firestoreService.getDocument(
        FirestorePaths.root,
        FirestorePaths.expenses,
      );
      final expensesData = expensesDoc.data();
      if (expensesData != null) {
        for (final entry in expensesData.entries) {
          if (entry.value is! Map) continue;
          final mapped = Map<String, dynamic>.from(entry.value as Map);
          final isDeleted = (mapped['isDeleted'] as bool?) ?? false;
          if (isDeleted || mapped['deletedAt'] != null) continue;
          final groupId = mapped['groupId'] as String?;
          if (groupId == null || groupId.isEmpty) continue;
          mapped['id'] = entry.key;
          topLevelExpensesByGroup.putIfAbsent(groupId, () => []).add(mapped);
        }
      }
    } catch (_) {}

    final blockedIds = await BlockedUsersStore.idsBlockedBy(
      _firestoreService,
      userId,
    );

    for (final entry in groupsData.entries) {
      final groupId = entry.key;
      final groupData = _asStringKeyMap(entry.value);
      if (groupData == null) continue;
      
      final groupName = groupData['name'] as String? ?? 'Unnamed Group';
      final groupImage = groupData['groupImage'] as String?;
      final groupType = groupData['type'] as String? ?? 'Other';

      // Check membership
      final List<String> memberIds = [];
      if (groupData['members'] is List) {
        final membersList = groupData['members'] as List;
        memberIds.addAll(membersList.map((e) => e.toString()));
      }

      if (!memberIds.contains(userId)) continue;
      if (memberIds.any(blockedIds.contains)) continue;
      final int memberCount = memberIds.length;

      // Get member names
      final Map<String, String> memberNames = {};
      for (final mId in memberIds) {
        memberNames[mId] = UserDisplayNames.resolve(allUserNames, mId);
      }

      // Map expenses.
      // Splitwise/expenses first, then nested group.expenses if present.
      final Map<String, Map<String, dynamic>> expensesById = {
        for (final expense in (topLevelExpensesByGroup[groupId] ?? const <Map<String, dynamic>>[]))
          (expense['id'] as String): Map<String, dynamic>.from(expense),
      };
      DateTime? lastExpenseDate;
      final expensesMap = _asStringKeyMap(groupData['expenses']);
      if (expensesMap != null) {
        for (final expEntry in expensesMap.entries) {
          final expId = expEntry.key.toString();
          final expData = _asStringKeyMap(expEntry.value);
          if (expData == null) continue;
          final isDeleted = (expData['isDeleted'] as bool?) ?? false;
          if (isDeleted || expData['deletedAt'] != null) continue;
          expData['id'] = expId;
          // Top-level doc wins for same id; use legacy only when missing.
          expensesById.putIfAbsent(expId, () => expData);
        }
      }

      final expenses = expensesById.values.toList();
      for (final expData in expenses) {
        final Timestamp? timestamp = expData['date'] as Timestamp?;
        if (timestamp != null) {
          final date = timestamp.toDate();
          if (lastExpenseDate == null || date.isAfter(lastExpenseDate)) {
            lastExpenseDate = date;
          }
        }
      }

      final shares = <ExpenseShare>[];
      for (final expense in expenses) {
        final totalAmount = (expense['amount'] as num?)?.toDouble() ?? 0.0;

        final Map<String, double> owedByUser = {};
        if (_asStringKeyMap(expense['splits']) != null) {
          _readAmountMap(expense['splits'], (id, amount) {
            owedByUser[id] = amount;
          });
        } else if (memberIds.isNotEmpty) {
          final equalShare = totalAmount / memberIds.length;
          for (final mId in memberIds) {
            owedByUser[mId] = equalShare;
          }
        }

        final Map<String, double> paidByUser = {};
        if (_asStringKeyMap(expense['paidBy']) != null) {
          _readAmountMap(expense['paidBy'], (id, amount) {
            paidByUser[id] = amount;
          });
        } else {
          final legacyPaidById = expense['paidById'] as String?;
          if (legacyPaidById != null && legacyPaidById.isNotEmpty) {
            paidByUser[legacyPaidById] = totalAmount;
          }
        }

        final involvedIds = {...paidByUser.keys, ...owedByUser.keys};
        if (involvedIds.any(blockedIds.contains)) continue;

        final currencyCode = (expense['currencyCode'] as String?)?.trim();
        final currencySymbol = (expense['currencySymbol'] as String?)?.trim();
        shares.add(ExpenseShare(
          paidBy: paidByUser,
          owedBy: owedByUser,
          currencyCode: currencyCode == null || currencyCode.isEmpty ? 'INR' : currencyCode,
          currencySymbol:
              currencySymbol == null || currencySymbol.isEmpty ? '₹' : currencySymbol,
        ));
      }

      final simplifyDebts = groupData['simplifyDebts'] as bool? ?? true;
      final transfers = GroupBalanceCalculator.computeTransfersFromShares(
        expenses: shares,
        memberIds: memberIds,
        simplifyDebts: simplifyDebts,
      );
      final computedBalances = GroupBalanceCalculator.memberBalancesFromTransfers(
        transfers: transfers,
        currentUserId: userId,
        memberNames: memberNames,
        excludedUserIds: blockedIds,
      );

      final List<MemberBalanceModel> memberBalances = computedBalances
          .map(MemberBalanceModel.fromEntity)
          .toList();
      final currencyTotals = MultiCurrency.netByCurrency(
        memberBalances.map(
          (balance) => CurrencyAmount(
            amount: balance.signedAmount,
            currencyCode: balance.currencyCode,
            currencySymbol: balance.currencySymbol,
          ),
        ),
      );
      final hasOwed = currencyTotals.any((item) => item.isOwed);
      final hasOwe = currencyTotals.any((item) => item.isOwe);
      final BalanceType groupBalanceType;
      if (currencyTotals.isEmpty) {
        groupBalanceType = BalanceType.settled;
      } else if (hasOwed && !hasOwe) {
        groupBalanceType = BalanceType.owed;
      } else if (hasOwe && !hasOwed) {
        groupBalanceType = BalanceType.owe;
      } else {
        groupBalanceType = BalanceType.owed;
      }

      groupsList.add(GroupSummaryModel(
        groupId: groupId,
        groupName: groupName,
        groupImage: groupImage,
        totalBalance: currencyTotals.isEmpty ? 0.0 : currencyTotals.first.amount.abs(),
        balanceType: groupBalanceType,
        memberBalances: memberBalances,
        memberCount: memberCount,
        memberIds: memberIds,
        groupType: groupType,
        lastExpenseDate: lastExpenseDate,
        simplifyDebts: simplifyDebts,
      ));

      overallAmounts.addAll(currencyTotals);
    }

    final overall = BalanceSummary.fromAmounts(overallAmounts);

    return HomeSummaryModel(
      overallBalance: BalanceSummaryModel.fromEntity(overall),
      groups: groupsList,
    );
  }
}
