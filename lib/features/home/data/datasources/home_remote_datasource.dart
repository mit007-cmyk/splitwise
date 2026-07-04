import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../auth/data/models/user_model.dart';
import '../../domain/entities/balance_summary.dart';
import '../models/balance_summary_model.dart';
import '../models/group_summary_model.dart';
import '../models/home_summary_model.dart';

abstract class HomeRemoteDataSource {
  Future<HomeSummaryModel> getHomeSummary(String userId);
  Future<void> createGroup({required String groupId, required Map<String, dynamic> data});
  Future<List<UserModel>> getAllUsers();
  Future<void> addContact({required String name, required String emailOrPhone});
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
            email: uData['email'] as String? ?? '',
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
  Future<void> addContact({required String name, required String emailOrPhone}) async {
    final friendId = const Uuid().v4();
    final friendData = {
      'id': friendId,
      'name': name.trim(),
      'email': emailOrPhone.trim(),
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
        final paidById = expense['paidById'] as String? ?? '';
        final totalAmount = (expense['amount'] as num?)?.toDouble() ?? 0.0;

        final List<Map<String, dynamic>> splits = [];
        if (expense['splits'] is Map) {
          final splitsMap = expense['splits'] as Map;
          for (final splitEntry in splitsMap.entries) {
            splits.add({
              'userId': splitEntry.key as String,
              'amount': (splitEntry.value as num).toDouble(),
            });
          }
        }

        if (splits.isEmpty && memberIds.isNotEmpty) {
          final equalShare = totalAmount / memberIds.length;
          for (final mId in memberIds) {
            splits.add({'userId': mId, 'amount': equalShare});
          }
        }

        if (paidById == userId) {
          for (final split in splits) {
            final debtorId = split['userId'] as String? ?? '';
            if (debtorId == userId) continue;
            final debtAmount = (split['amount'] as num?)?.toDouble() ?? 0.0;
            netBalances[debtorId] = (netBalances[debtorId] ?? 0.0) + debtAmount;
          }
        } else {
          final currentUserSplit = splits.firstWhere(
            (s) => s['userId'] == userId,
            orElse: () => {'amount': 0.0},
          );
          final oweAmount = (currentUserSplit['amount'] as num?)?.toDouble() ?? 0.0;
          if (oweAmount > 0) {
            netBalances[paidById] = (netBalances[paidById] ?? 0.0) - oweAmount;
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
