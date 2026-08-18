import '../../../expenses/data/datasources/currency_catalog.dart';
import '../../../expenses/domain/entities/expense.dart';

/// What a group spent, and how much of it is yours, for a single currency and
/// a single period (one month, or all time when the period is null).
class GroupSpendingSummary {
  final String currencyCode;
  final String currencySymbol;
  final double totalSpent;
  final double yourShare;

  const GroupSpendingSummary({
    required this.currencyCode,
    required this.currencySymbol,
    required this.totalSpent,
    required this.yourShare,
  });

  bool get isEmpty => totalSpent.abs() < 0.01;

  /// Your share as the whole-number percentage Splitwise shows under the
  /// amount. Returns 0 when the group hasn't spent anything.
  int get yourSharePercent =>
      totalSpent <= 0 ? 0 : ((yourShare / totalSpent) * 100).round();

  String formatted(double amount) =>
      '$currencySymbol${amount.toStringAsFixed(2)}';
}

/// Spending totals behind the group "Totals" screen.
///
/// Amounts are never converted between currencies, so every figure on that
/// screen belongs to exactly one currency the group has actually used.
class GroupSpendingCalculator {
  GroupSpendingCalculator._();

  /// Settlements move money between members instead of adding to what the
  /// group spent, so they are excluded from every total here.
  static bool counts(Expense expense) =>
      !expense.isDeleted && expense.category.toLowerCase() != 'settlement';

  /// Currency codes with spending in this group, biggest spender first.
  static List<String> currencyCodes(List<Expense> expenses) {
    final totals = <String, double>{};
    for (final expense in expenses.where(counts)) {
      final code = CurrencyCatalog.normalizeCode(expense.currencyCode);
      totals[code] = (totals[code] ?? 0) + expense.amount;
    }
    final codes = totals.keys.toList()
      ..sort((a, b) => totals[b]!.compareTo(totals[a]!));
    return codes;
  }

  /// Months that contain spending in [currencyCode], oldest first, each
  /// normalised to the first day of the month.
  static List<DateTime> months(List<Expense> expenses, String currencyCode) {
    final seen = <DateTime>{};
    for (final expense in _inCurrency(expenses, currencyCode)) {
      seen.add(monthOf(expense.date));
    }
    final result = seen.toList()..sort();
    return result;
  }

  static GroupSpendingSummary summarize({
    required List<Expense> expenses,
    required String currencyCode,
    required String userId,
    DateTime? month,
  }) {
    final code = CurrencyCatalog.normalizeCode(currencyCode);
    var totalSpent = 0.0;
    var yourShare = 0.0;
    String? symbol;

    for (final expense in _inCurrency(expenses, code)) {
      if (month != null && monthOf(expense.date) != monthOf(month)) continue;
      symbol ??= expense.currencySymbol.trim().isEmpty
          ? null
          : expense.currencySymbol.trim();
      totalSpent += expense.amount;
      yourShare += expense.splits[userId] ?? 0.0;
    }

    return GroupSpendingSummary(
      currencyCode: code,
      currencySymbol: CurrencyCatalog.symbolFor(code, symbol),
      totalSpent: totalSpent,
      yourShare: yourShare,
    );
  }

  static DateTime monthOf(DateTime date) => DateTime(date.year, date.month);

  static Iterable<Expense> _inCurrency(
    List<Expense> expenses,
    String currencyCode,
  ) {
    final code = CurrencyCatalog.normalizeCode(currencyCode);
    return expenses.where(
      (expense) =>
          counts(expense) &&
          CurrencyCatalog.normalizeCode(expense.currencyCode) == code,
    );
  }
}
