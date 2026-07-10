import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/utils/activity_event_writer.dart';
import '../../../../core/utils/debt_settlement.dart';
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
  Future<void> addGroupMembers({required String groupId, required List<String> memberIds});
  Future<void> editGroup({required String groupId, required String name, required String type});
  Future<void> leaveGroup({required String groupId, required String userId});
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
            name: uData['name'] as String? ?? uId.split('@')[0],
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
  Future<void> addGroupMembers({required String groupId, required List<String> memberIds}) async {
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
    
    for (final id in memberIds) {
      if (!currentMembers.contains(id)) {
        currentMembers.add(id);
      }
    }

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

  @override
  Future<void> editGroup({
    required String groupId,
    required String name,
    required String type,
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
    groupMap['name'] = name;
    groupMap['type'] = type;

    await _firestoreService.setDocument(
      'Splitwise',
      'groups',
      {
        groupId: groupMap,
      },
      merge: true,
    );
  }

  @override
  Future<void> leaveGroup({required String groupId, required String userId}) async {
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

    currentMembers.remove(userId);

    if (currentMembers.isEmpty) {
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
    // 1. Fetch user names first from 'Splitwise/users' document
    final Map<String, String> allUserNames = {};
    try {
      final usersDoc = await _firestoreService.getDocument('Splitwise', 'users');
      final usersData = usersDoc.data();
      if (usersData != null) {
        for (final entry in usersData.entries) {
          final uId = entry.key;
          final uData = _asStringKeyMap(entry.value);
          if (uData != null) {
            allUserNames[uId] = uData['name'] as String? ?? uId.split('@')[0];
          }
        }
      }
    } catch (_) {}

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
    double overallNetBalance = 0.0;
    final topLevelExpensesByGroup = <String, List<Map<String, dynamic>>>{};

    // Preferred schema: Splitwise/expenses document (same table style as
    // groups/users where each field key is an expense id).
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

    // Backward compatibility: also read mistaken top-level `/expenses/{id}`
    // collection introduced during migration so no data disappears.
    try {
      final expenseDocs = await _firestoreService.getCollection(FirestorePaths.expenses);
      for (final doc in expenseDocs.docs) {
        final data = doc.data();
        final isDeleted = (data['isDeleted'] as bool?) ?? false;
        if (isDeleted || data['deletedAt'] != null) continue;
        final groupId = data['groupId'] as String?;
        if (groupId == null || groupId.isEmpty) continue;
        final mapped = Map<String, dynamic>.from(data);
        mapped['id'] = doc.id;
        topLevelExpensesByGroup.putIfAbsent(groupId, () => []).add(mapped);
      }
    } catch (_) {}

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
      final int memberCount = memberIds.length;

      // Get member names
      final Map<String, String> memberNames = {};
      for (final mId in memberIds) {
        memberNames[mId] =
            allUserNames[mId] ?? (mId.length > 5 ? mId.substring(0, 5) : mId);
      }

      // Map expenses.
      // New schema first (top-level `/expenses`), then legacy nested data.
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

      // Net balances map
      final Map<String, double> netBalances = {};

      for (final expense in expenses) {
        final totalAmount = (expense['amount'] as num?)?.toDouble() ?? 0.0;

        // Splits: userId -> amount owed. Falls back to an equal split
        // across all group members when the expense doesn't specify one.
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

        // Paid: userId -> amount paid. Supports both the multi-payer
        // `paidBy` map and the legacy single `paidById` string field.
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

        // Net (paid - owed) per person touched by this expense, reduced to
        // the minimal set of pairwise IOUs. A single-payer expense collapses
        // to exactly the same pairwise result the old logic produced.
        final involvedIds = {...paidByUser.keys, ...owedByUser.keys};
        final netForExpense = <String, double>{
          for (final id in involvedIds)
            id: (paidByUser[id] ?? 0.0) - (owedByUser[id] ?? 0.0),
        };

        for (final transfer in DebtSettlement.reduceToTransfers(netForExpense)) {
          if (transfer.fromUserId == userId) {
            netBalances[transfer.toUserId] =
                (netBalances[transfer.toUserId] ?? 0.0) - transfer.amount;
          } else if (transfer.toUserId == userId) {
            netBalances[transfer.fromUserId] =
                (netBalances[transfer.fromUserId] ?? 0.0) + transfer.amount;
          }
        }
      }

      final List<MemberBalanceModel> memberBalances = [];
      double groupTotalBalance = 0.0;

      netBalances.forEach((otherId, balance) {
        if (otherId.trim().isEmpty) return;
        if (balance.abs() > 0.01) {
          groupTotalBalance += balance;
          memberBalances.add(MemberBalanceModel(
            userId: otherId,
            userName: memberNames[otherId] ??
                (otherId.length > 5 ? otherId.substring(0, 5) : otherId),
            amount: balance.abs(),
            type: balance > 0 ? BalanceType.owed : BalanceType.owe,
          ));
        }
      });

      final BalanceType groupBalanceType;
      if (groupTotalBalance > 0.01) {
        groupBalanceType = BalanceType.owed;
      } else if (groupTotalBalance < -0.01) {
        groupBalanceType = BalanceType.owe;
      } else {
        groupBalanceType = BalanceType.settled;
      }

      groupsList.add(GroupSummaryModel(
        groupId: groupId,
        groupName: groupName,
        groupImage: groupImage,
        totalBalance: groupTotalBalance.abs(),
        balanceType: groupBalanceType,
        memberBalances: memberBalances,
        memberCount: memberCount,
        memberIds: memberIds,
        groupType: groupType,
        lastExpenseDate: lastExpenseDate,
      ));

      overallNetBalance += groupTotalBalance;
    }

    final BalanceType overallBalanceType;
    if (overallNetBalance > 0.01) {
      overallBalanceType = BalanceType.owed;
    } else if (overallNetBalance < -0.01) {
      overallBalanceType = BalanceType.owe;
    } else {
      overallBalanceType = BalanceType.settled;
    }

    return HomeSummaryModel(
      overallBalance: BalanceSummaryModel(
        amount: overallNetBalance.abs(),
        type: overallBalanceType,
      ),
      groups: groupsList,
    );
  }
}
