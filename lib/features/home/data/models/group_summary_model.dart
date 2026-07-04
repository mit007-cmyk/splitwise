import '../../domain/entities/balance_summary.dart';
import '../../domain/entities/group_summary.dart';

class MemberBalanceModel extends MemberBalance {
  const MemberBalanceModel({
    required super.userId,
    required super.userName,
    required super.amount,
    required super.type,
  });

  factory MemberBalanceModel.fromJson(Map<String, dynamic> json) {
    return MemberBalanceModel(
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: BalanceType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => BalanceType.settled,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'amount': amount,
      'type': type.toString(),
    };
  }

  factory MemberBalanceModel.fromEntity(MemberBalance entity) {
    return MemberBalanceModel(
      userId: entity.userId,
      userName: entity.userName,
      amount: entity.amount,
      type: entity.type,
    );
  }
}

class GroupSummaryModel extends GroupSummary {
  const GroupSummaryModel({
    required super.groupId,
    required super.groupName,
    super.groupImage,
    required super.totalBalance,
    required super.balanceType,
    required List<MemberBalanceModel> super.memberBalances,
    required super.memberCount,
    required super.memberIds,
    required super.groupType,
    super.lastExpenseDate,
  });

  factory GroupSummaryModel.fromJson(Map<String, dynamic> json) {
    return GroupSummaryModel(
      groupId: json['groupId'] as String? ?? '',
      groupName: json['groupName'] as String? ?? '',
      groupImage: json['groupImage'] as String?,
      totalBalance: (json['totalBalance'] as num?)?.toDouble() ?? 0.0,
      balanceType: BalanceType.values.firstWhere(
        (e) => e.toString() == json['balanceType'],
        orElse: () => BalanceType.settled,
      ),
      memberBalances: (json['memberBalances'] as List<dynamic>?)
              ?.map((e) => MemberBalanceModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      memberCount: json['memberCount'] as int? ?? 0,
      memberIds: (json['memberIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      groupType: json['groupType'] as String? ?? 'Other',
      lastExpenseDate: json['lastExpenseDate'] != null
          ? DateTime.tryParse(json['lastExpenseDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'groupName': groupName,
      'groupImage': groupImage,
      'totalBalance': totalBalance,
      'balanceType': balanceType.toString(),
      'memberBalances': memberBalances
          .map((e) => MemberBalanceModel.fromEntity(e).toJson())
          .toList(),
      'memberCount': memberCount,
      'memberIds': memberIds,
      'groupType': groupType,
      'lastExpenseDate': lastExpenseDate?.toIso8601String(),
    };
  }

  factory GroupSummaryModel.fromEntity(GroupSummary entity) {
    return GroupSummaryModel(
      groupId: entity.groupId,
      groupName: entity.groupName,
      groupImage: entity.groupImage,
      totalBalance: entity.totalBalance,
      balanceType: entity.balanceType,
      memberBalances: entity.memberBalances
          .map((e) => MemberBalanceModel.fromEntity(e))
          .toList(),
      memberCount: entity.memberCount,
      memberIds: entity.memberIds,
      groupType: entity.groupType,
      lastExpenseDate: entity.lastExpenseDate,
    );
  }
}
