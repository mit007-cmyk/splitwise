import 'package:equatable/equatable.dart';
import '../../../../core/utils/currency_amount.dart';

enum BalanceType { owed, owe, settled }

class BalanceSummary extends Equatable {
  final double amount;
  final BalanceType type;
  final List<CurrencyAmount> amounts;

  const BalanceSummary({
    required this.amount,
    required this.type,
    this.amounts = const [],
  });

  factory BalanceSummary.fromAmounts(List<CurrencyAmount> amounts) {
    final sorted = MultiCurrency.netByCurrency(amounts);
    if (sorted.isEmpty) {
      return const BalanceSummary(
        amount: 0,
        type: BalanceType.settled,
        amounts: [],
      );
    }
    final hasOwed = sorted.any((item) => item.isOwed);
    final hasOwe = sorted.any((item) => item.isOwe);
    final BalanceType type;
    if (hasOwed && hasOwe) {
      type = BalanceType.owed;
    } else if (hasOwed) {
      type = BalanceType.owed;
    } else {
      type = BalanceType.owe;
    }
    return BalanceSummary(
      amount: sorted.first.amount.abs(),
      type: type,
      amounts: sorted,
    );
  }

  List<CurrencyAmount> get displayAmounts {
    if (amounts.isNotEmpty) return MultiCurrency.netByCurrency(amounts);
    if (amount.abs() <= 0.01 || type == BalanceType.settled) return const [];
    return [
      CurrencyAmount(
        amount: type == BalanceType.owed ? amount : -amount,
        currencyCode: 'INR',
        currencySymbol: '₹',
      ),
    ];
  }

  bool get hasOwed => displayAmounts.any((item) => item.isOwed);
  bool get hasOwe => displayAmounts.any((item) => item.isOwe);

  @override
  List<Object?> get props => [amount, type, amounts];
}
