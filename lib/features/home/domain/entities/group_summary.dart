import 'package:equatable/equatable.dart';
import 'balance_summary.dart';

class MemberBalance extends Equatable {
  final String userId;
  final String userName;
  final double amount;
  final BalanceType type;

  const MemberBalance({
    required this.userId,
    required this.userName,
    required this.amount,
    required this.type,
  });

  @override
  List<Object?> get props => [userId, userName, amount, type];
}

class GroupSummary extends Equatable {
  /// [groupType] value used for the synthetic 1:1 "non-group expenses"
  /// bucket created when an expense is added directly from a friend's page
  /// without picking a real group. Kept here (rather than in the expenses
  /// feature) since [groupType] is this entity's own concept.
  static const String directGroupType = 'direct';

  final String groupId;
  final String groupName;
  final String? groupImage;
  final double totalBalance;
  final BalanceType balanceType;
  final List<MemberBalance> memberBalances;
  final int memberCount;
  final List<String> memberIds;
  final String groupType;
  final DateTime? lastExpenseDate;

  /// When true, group balances are reduced to the fewest repayments.
  /// Underlying expenses are never changed.
  final bool simplifyDebts;

  const GroupSummary({
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
    this.simplifyDebts = true,
  });

  @override
  List<Object?> get props => [
        groupId,
        groupName,
        groupImage,
        totalBalance,
        balanceType,
        memberBalances,
        memberCount,
        memberIds,
        groupType,
        lastExpenseDate,
        simplifyDebts,
      ];
}
