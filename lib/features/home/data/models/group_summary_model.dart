import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/balance_summary.dart';
import '../../domain/entities/group_summary.dart';

part 'group_summary_model.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class MemberBalanceModel extends MemberBalance {
  @override
  final String userId;
  @override
  final String userName;
  @override
  final double amount;
  @override
  @JsonKey(fromJson: _typeFromJson, toJson: _typeToJson)
  final BalanceType type;

  const MemberBalanceModel({
    required this.userId,
    required this.userName,
    required this.amount,
    required this.type,
  }) : super(
          userId: userId,
          userName: userName,
          amount: amount,
          type: type,
        );

  factory MemberBalanceModel.fromJson(Map<String, dynamic> json) => _$MemberBalanceModelFromJson(json);

  Map<String, dynamic> toJson() => _$MemberBalanceModelToJson(this);

  @override
  String toString() => jsonEncode(toJson());

  factory MemberBalanceModel.fromEntity(MemberBalance entity) {
    return MemberBalanceModel(
      userId: entity.userId,
      userName: entity.userName,
      amount: entity.amount,
      type: entity.type,
    );
  }

  static BalanceType _typeFromJson(dynamic jsonVal) {
    final String val = jsonVal?.toString() ?? '';
    return BalanceType.values.firstWhere(
      (e) => e.toString() == val,
      orElse: () => BalanceType.settled,
    );
  }

  static String _typeToJson(BalanceType type) => type.toString();
}

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class GroupSummaryModel extends GroupSummary {
  @override
  final String groupId;
  @override
  final String groupName;
  @override
  final String? groupImage;
  @override
  final double totalBalance;
  @override
  @JsonKey(fromJson: _typeFromJson, toJson: _typeToJson)
  final BalanceType balanceType;
  @override
  final List<MemberBalanceModel> memberBalances;
  @override
  final int memberCount;
  @override
  final List<String> memberIds;
  @override
  final String groupType;
  @override
  final DateTime? lastExpenseDate;

  const GroupSummaryModel({
    required this.groupId,
    required this.groupName,
    this.groupImage,
    required this.totalBalance,
    required this.balanceType,
    required this.memberBalances,
    required this.memberCount,
    required this.memberIds,
    required this.groupType,
    this.lastExpenseDate,
  }) : super(
          groupId: groupId,
          groupName: groupName,
          groupImage: groupImage,
          totalBalance: totalBalance,
          balanceType: balanceType,
          memberBalances: memberBalances,
          memberCount: memberCount,
          memberIds: memberIds,
          groupType: groupType,
          lastExpenseDate: lastExpenseDate,
        );

  factory GroupSummaryModel.fromJson(Map<String, dynamic> json) => _$GroupSummaryModelFromJson(json);

  Map<String, dynamic> toJson() => _$GroupSummaryModelToJson(this);

  @override
  String toString() => jsonEncode(toJson());

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

  static BalanceType _typeFromJson(dynamic jsonVal) {
    final String val = jsonVal?.toString() ?? '';
    return BalanceType.values.firstWhere(
      (e) => e.toString() == val,
      orElse: () => BalanceType.settled,
    );
  }

  static String _typeToJson(BalanceType type) => type.toString();
}
