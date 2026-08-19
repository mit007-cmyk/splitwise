import 'package:equatable/equatable.dart';
import '../../features/expenses/data/datasources/currency_catalog.dart';
import 'debt_settlement.dart';

/// Signed amount in a single currency. Positive = you are owed, negative = you owe.
class CurrencyAmount extends Equatable {
  final double amount;
  final String currencyCode;
  final String currencySymbol;

  const CurrencyAmount({
    required this.amount,
    required this.currencyCode,
    required this.currencySymbol,
  });

  bool get isOwed => amount > DebtSettlement.epsilon;
  bool get isOwe => amount < -DebtSettlement.epsilon;

  String get formatted => '$currencySymbol${amount.abs().toStringAsFixed(2)}';

  factory CurrencyAmount.fromJson(Map<String, dynamic> json) {
    return CurrencyAmount(
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currencyCode: (json['currencyCode'] as String?) ?? 'INR',
      currencySymbol: (json['currencySymbol'] as String?) ?? '₹',
    );
  }

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'currencyCode': currencyCode,
        'currencySymbol': currencySymbol,
      };

  @override
  List<Object?> get props => [amount, currencyCode, currencySymbol];
}

/// Splitwise-style multi-currency display: never mix $ and ₹ into one number.
class MultiCurrency {
  MultiCurrency._();

  static const _priority = ['USD', 'EUR', 'GBP', 'INR'];

  static CurrencyAmount of({
    required double amount,
    String? currencyCode,
    String? currencySymbol,
  }) {
    final code = CurrencyCatalog.normalizeCode(currencyCode);
    return CurrencyAmount(
      amount: amount,
      currencyCode: code,
      currencySymbol: CurrencyCatalog.symbolFor(code, currencySymbol),
    );
  }

  static List<CurrencyAmount> sort(Iterable<CurrencyAmount> amounts) {
    final list = amounts
        .where((item) => item.amount.abs() > DebtSettlement.epsilon)
        .toList();
    list.sort((a, b) {
      final ai = _priority.indexOf(a.currencyCode);
      final bi = _priority.indexOf(b.currencyCode);
      final ap = ai == -1 ? _priority.length : ai;
      final bp = bi == -1 ? _priority.length : bi;
      if (ap != bp) return ap.compareTo(bp);
      return a.currencyCode.compareTo(b.currencyCode);
    });
    return list;
  }

  static List<CurrencyAmount> netByCurrency(Iterable<CurrencyAmount> amounts) {
    final byCode = <String, CurrencyAmount>{};
    for (final item in amounts) {
      if (item.amount.abs() <= DebtSettlement.epsilon) continue;
      final existing = byCode[item.currencyCode];
      if (existing == null) {
        byCode[item.currencyCode] = item;
      } else {
        byCode[item.currencyCode] = CurrencyAmount(
          amount: existing.amount + item.amount,
          currencyCode: existing.currencyCode,
          currencySymbol: existing.currencySymbol,
        );
      }
    }
    return sort(byCode.values);
  }

  static String join(Iterable<CurrencyAmount> amounts) {
    return netByCurrency(amounts).map((item) => item.formatted).join(' + ');
  }

  /// Primary line for friend rows: home currency when present, else first, with `*` if more exist.
  static ({String text, bool mixedDirections, bool hasMore}) friendSummary(
    Iterable<CurrencyAmount> amounts,
  ) {
    final list = netByCurrency(amounts);
    if (list.isEmpty) {
      return (text: '', mixedDirections: false, hasMore: false);
    }
    final home = list.where(
      (item) => item.currencyCode == CurrencyCatalog.defaultCurrency.code,
    );
    final primary = home.isNotEmpty ? home.first : list.first;
    final othersSameDirection = list.where((item) {
      if (item.currencyCode == primary.currencyCode) return false;
      return (primary.isOwed && item.isOwed) || (primary.isOwe && item.isOwe);
    });
    final mixed = list.any((item) => item.isOwed) && list.any((item) => item.isOwe);
    final hasMore = othersSameDirection.isNotEmpty || (mixed && list.length > 1);
    return (text: primary.formatted, mixedDirections: mixed, hasMore: hasMore);
  }

  static String overallLabel({
    required Iterable<CurrencyAmount> amounts,
    String owedPrefix = 'you are owed',
    String owePrefix = 'you owe',
    String settled = 'settled up',
    bool overall = false,
  }) {
    final list = netByCurrency(amounts);
    if (list.isEmpty) return settled;

    final owed = list.where((item) => item.isOwed).toList();
    final owe = list.where((item) => item.isOwe).toList();
    final owedText = join(owed);
    final oweText = join(owe);
    final owedLead = overall ? 'Overall, $owedPrefix' : owedPrefix;
    final oweLead = overall ? 'Overall, $owePrefix' : owePrefix;

    if (owed.isNotEmpty && owe.isNotEmpty) {
      return '$owedLead $owedText and $owePrefix $oweText';
    }
    if (owed.isNotEmpty) return '$owedLead $owedText';
    return '$oweLead $oweText';
  }
}
