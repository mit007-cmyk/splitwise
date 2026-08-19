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

/// One point on the "Spending over time" line — a month when viewing all
/// time, or a day when a single month is selected.
class SpendPoint {
  final DateTime date;
  final double amount;

  const SpendPoint({required this.date, required this.amount});
}

/// One slice on the "Spending by category" chart.
class CategorySpend {
  final String category;
  final double amount;

  const CategorySpend({required this.category, required this.amount});
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

  /// All time: one point per month (gaps filled with zero, last 12 months).
  /// A specific [month]: one point per calendar day in that month.
  static List<SpendPoint> spendingOverTime({
    required List<Expense> expenses,
    required String currencyCode,
    DateTime? month,
  }) {
    if (month != null) return _dailySpending(expenses, currencyCode, month);
    return _monthlySpending(expenses, currencyCode);
  }

  /// Axis days to label when the trend is a single month: 1, 7, 14, 21, and
  /// the last day — matching the ticks Splitwise draws under the line.
  static List<int> monthAxisDays(int lastDay) {
    final ticks = <int>{1, 7, 14, 21, lastDay}
      ..removeWhere((day) => day < 1 || day > lastDay);
    return ticks.toList()..sort();
  }

  static List<SpendPoint> _monthlySpending(
    List<Expense> expenses,
    String currencyCode,
  ) {
    final totals = <DateTime, double>{};
    for (final expense in _inCurrency(expenses, currencyCode)) {
      final month = monthOf(expense.date);
      totals[month] = (totals[month] ?? 0) + expense.amount;
    }
    if (totals.isEmpty) return const [];

    final months = totals.keys.toList()..sort();
    final last = months.last;
    final first = months.first;
    final windowStart = DateTime(last.year, last.month - 11);
    var cursor = first.isAfter(windowStart) ? first : windowStart;

    final result = <SpendPoint>[];
    while (!cursor.isAfter(last)) {
      result.add(SpendPoint(date: cursor, amount: totals[cursor] ?? 0));
      cursor = DateTime(cursor.year, cursor.month + 1);
    }
    return result;
  }

  static List<SpendPoint> _dailySpending(
    List<Expense> expenses,
    String currencyCode,
    DateTime month,
  ) {
    final start = monthOf(month);
    final lastDay = DateTime(start.year, start.month + 1, 0).day;
    final totals = <int, double>{};
    for (final expense in _inCurrency(expenses, currencyCode)) {
      if (monthOf(expense.date) != start) continue;
      final day = expense.date.day;
      totals[day] = (totals[day] ?? 0) + expense.amount;
    }

    return [
      for (var day = 1; day <= lastDay; day++)
        SpendPoint(
          date: DateTime(start.year, start.month, day),
          amount: totals[day] ?? 0,
        ),
    ];
  }

  /// Category totals for [currencyCode], largest first. Pass [month] to match
  /// the Totals period filter; omit it for all-time.
  static List<CategorySpend> spendingByCategory({
    required List<Expense> expenses,
    required String currencyCode,
    DateTime? month,
  }) {
    final totals = <String, double>{};
    for (final expense in _inCurrency(expenses, currencyCode)) {
      if (month != null && monthOf(expense.date) != monthOf(month)) continue;
      final name = expense.category.trim().isEmpty
          ? 'General'
          : expense.category.trim();
      totals[name] = (totals[name] ?? 0) + expense.amount;
    }
    final rows = [
      for (final entry in totals.entries)
        CategorySpend(category: entry.key, amount: entry.value),
    ]..sort((a, b) => b.amount.compareTo(a.amount));
    return rows;
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
