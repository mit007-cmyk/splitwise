import 'package:equatable/equatable.dart';
import 'balance_summary.dart';
import 'group_summary.dart';

class HomeSummary extends Equatable {
  final BalanceSummary overallBalance;
  final List<GroupSummary> groups;

  const HomeSummary({
    required this.overallBalance,
    required this.groups,
  });

  @override
  List<Object?> get props => [overallBalance, groups];
}
