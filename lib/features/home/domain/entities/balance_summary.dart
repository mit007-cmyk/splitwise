import 'package:equatable/equatable.dart';

enum BalanceType { owed, owe, settled }

class BalanceSummary extends Equatable {
  final double amount;
  final BalanceType type;

  const BalanceSummary({
    required this.amount,
    required this.type,
  });

  @override
  List<Object?> get props => [amount, type];
}
