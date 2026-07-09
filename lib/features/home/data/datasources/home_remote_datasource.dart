import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/firestore_service.dart';
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
}

@LazySingleton(as: HomeRemoteDataSource)
class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final FirestoreService _firestoreService;

  HomeRemoteDataSourceImpl(this._firestoreService);

  @override
  Future<void> createGroup({required String groupId, required Map<String, dynamic> data}) async {
    return _firestoreService.setDocument(
      'Splitwise',
      'groups',
      {
        groupId: data,
      },
      merge: true,
    );
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
        final uData = entry.value as Map?;
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

    final groupMap = Map<String, dynamic>.from(groupsData[groupId] as Map);
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

    final groupMap = Map<String, dynamic>.from(groupsData[groupId] as Map);
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

    final groupMap = Map<String, dynamic>.from(groupsData[groupId] as Map);
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
  Future<HomeSummaryModel> getHomeSummary(String userId) async {
    // 1. Fetch user names first from 'Splitwise/users' document
    final Map<String, String> allUserNames = {};
    try {
      final usersDoc = await _firestoreService.getDocument('Splitwise', 'users');
      final usersData = usersDoc.data();
      if (usersData != null) {
        for (final entry in usersData.entries) {
          final uId = entry.key;
          final uData = entry.value as Map?;
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

    for (final entry in groupsData.entries) {
      final groupId = entry.key;
      final groupData = Map<String, dynamic>.from(entry.value as Map);
      
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
        memberNames[mId] = allUserNames[mId] ?? mId.substring(0, 5);
      }

      // Map expenses
      final List<Map<String, dynamic>> expenses = [];
      DateTime? lastExpenseDate;
      if (groupData['expenses'] is Map) {
        final expensesMap = groupData['expenses'] as Map;
        for (final expEntry in expensesMap.entries) {
          final expId = expEntry.key as String;
          final expData = Map<String, dynamic>.from(expEntry.value as Map);
          expData['id'] = expId;

          final Timestamp? timestamp = expData['date'] as Timestamp?;
          if (timestamp != null) {
            final date = timestamp.toDate();
            if (lastExpenseDate == null || date.isAfter(lastExpenseDate)) {
              lastExpenseDate = date;
            }
          }
          expenses.add(expData);
        }
      }

      // Net balances map
      final Map<String, double> netBalances = {};

      for (final expense in expenses) {
        final totalAmount = (expense['amount'] as num?)?.toDouble() ?? 0.0;

        // Splits: userId -> amount owed. Falls back to an equal split
        // across all group members when the expense doesn't specify one.
        final Map<String, double> owedByUser = {};
        if (expense['splits'] is Map) {
          (expense['splits'] as Map).forEach((key, value) {
            owedByUser[key as String] = (value as num?)?.toDouble() ?? 0.0;
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
        if (expense['paidBy'] is Map) {
          (expense['paidBy'] as Map).forEach((key, value) {
            paidByUser[key as String] = (value as num?)?.toDouble() ?? 0.0;
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
        if (balance.abs() > 0.01) {
          groupTotalBalance += balance;
          memberBalances.add(MemberBalanceModel(
            userId: otherId,
            userName: memberNames[otherId] ?? otherId.substring(0, 5),
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
