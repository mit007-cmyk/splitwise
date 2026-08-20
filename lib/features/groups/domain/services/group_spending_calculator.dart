import '../../../expenses/data/datasources/currency_catalog.dart';
import '../../../expenses/domain/entities/default_categories.dart';
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
  final String? categoryId;
  final String? categoryIcon;
  final double amount;

  const CategorySpend({
    required this.category,
    this.categoryId,
    this.categoryIcon,
    required this.amount,
  });
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

  /// The amount that counts for a chart or total. Group view uses the full
  /// expense; [forUserId] uses that person's split ("You" / my expenses).
  static double attributedAmount(Expense expense, {String? forUserId}) {
    if (forUserId == null || forUserId.isEmpty) return expense.amount;
    return expense.splits[forUserId] ?? 0.0;
  }

  /// Currency codes with spending in this group, biggest spender first.
  /// Pass [forUserId] to only include currencies where that person has a share.
  static List<String> currencyCodes(
    List<Expense> expenses, {
    String? forUserId,
  }) {
    final totals = <String, double>{};
    for (final expense in expenses.where(counts)) {
      final amount = attributedAmount(expense, forUserId: forUserId);
      if (amount.abs() < 0.01) continue;
      final code = CurrencyCatalog.normalizeCode(expense.currencyCode);
      totals[code] = (totals[code] ?? 0) + amount;
    }
    final codes = totals.keys.toList()
      ..sort((a, b) => totals[b]!.compareTo(totals[a]!));
    return codes;
  }

  /// Months that contain spending in [currencyCode], oldest first, each
  /// normalised to the first day of the month.
  static List<DateTime> months(
    List<Expense> expenses,
    String currencyCode, {
    String? forUserId,
  }) {
    final seen = <DateTime>{};
    for (final expense in _inCurrency(
      expenses,
      currencyCode,
      forUserId: forUserId,
    )) {
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
    String? forUserId,
  }) {
    final code = CurrencyCatalog.normalizeCode(currencyCode);
    var totalSpent = 0.0;
    var yourShare = 0.0;
    String? symbol;

    for (final expense in _inCurrency(
      expenses,
      code,
      forUserId: forUserId,
    )) {
      if (month != null && monthOf(expense.date) != monthOf(month)) continue;
      symbol ??= expense.currencySymbol.trim().isEmpty
          ? null
          : expense.currencySymbol.trim();
      totalSpent += attributedAmount(expense, forUserId: forUserId);
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
    String? forUserId,
  }) {
    if (month != null) {
      return _dailySpending(
        expenses,
        currencyCode,
        month,
        forUserId: forUserId,
      );
    }
    return _monthlySpending(expenses, currencyCode, forUserId: forUserId);
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
    String currencyCode, {
    String? forUserId,
  }) {
    final totals = <DateTime, double>{};
    for (final expense in _inCurrency(
      expenses,
      currencyCode,
      forUserId: forUserId,
    )) {
      final month = monthOf(expense.date);
      totals[month] =
          (totals[month] ?? 0) + attributedAmount(expense, forUserId: forUserId);
    }
    if (totals.isEmpty) return const [];

    final months = totals.keys.toList()..sort();
    final last = months.last;
    final first = months.first;
    // A single month of data would otherwise be one point and no line. Always
    // show at least four months so All time still reads as a trend.
    final paddedStart = DateTime(last.year, last.month - 3);
    final capStart = DateTime(last.year, last.month - 11);
    var cursor = first.isAfter(paddedStart) ? paddedStart : first;
    if (cursor.isBefore(capStart)) cursor = capStart;

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
    DateTime month, {
    String? forUserId,
  }) {
    final start = monthOf(month);
    final lastDay = DateTime(start.year, start.month + 1, 0).day;
    final totals = <int, double>{};
    for (final expense in _inCurrency(
      expenses,
      currencyCode,
      forUserId: forUserId,
    )) {
      if (monthOf(expense.date) != start) continue;
      final day = expense.date.day;
      totals[day] =
          (totals[day] ?? 0) + attributedAmount(expense, forUserId: forUserId);
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
  /// the Totals period filter; omit it for all-time. Pass [forUserId] to chart
  /// that person's share instead of the group's full amounts.
  static List<CategorySpend> spendingByCategory({
    required List<Expense> expenses,
    required String currencyCode,
    DateTime? month,
    String? forUserId,
  }) {
    final totals = <String, _CategoryBucket>{};
    for (final expense in _inCurrency(
      expenses,
      currencyCode,
      forUserId: forUserId,
    )) {
      if (month != null && monthOf(expense.date) != monthOf(month)) continue;
      final key = _categoryKey(expense);
      final amount = attributedAmount(expense, forUserId: forUserId);
      final existing = totals[key];
      if (existing == null) {
        totals[key] = _CategoryBucket(
          name: _categoryName(expense),
          categoryId: expense.categoryId ?? DefaultCategories.byName(expense.category)?.id,
          iconKey: expense.categoryIcon ??
              DefaultCategories.byName(expense.category)?.iconKey,
          amount: amount,
          latestDate: expense.date,
        );
      } else {
        existing.amount += amount;
        if (expense.date.isAfter(existing.latestDate)) {
          existing.name = _categoryName(expense);
          existing.latestDate = expense.date;
        }
      }
    }
    final rows = [
      for (final bucket in totals.values)
        CategorySpend(
          category: bucket.name,
          categoryId: bucket.categoryId,
          categoryIcon: bucket.iconKey,
          amount: bucket.amount,
        ),
    ]..sort((a, b) => b.amount.compareTo(a.amount));
    return rows;
  }

  static String _categoryName(Expense expense) {
    final name = expense.category.trim();
    return name.isEmpty ? 'General' : name;
  }

  static String _categoryKey(Expense expense) {
    final inferred = DefaultCategories.byName(expense.category);
    final id = expense.categoryId ?? inferred?.id;
    if (id != null && id.isNotEmpty) {
      final source = expense.categorySource ?? inferred?.source;
      return '${source?.value ?? 'default'}:$id';
    }
    return 'name:${_categoryName(expense).toLowerCase()}';
  }

  static DateTime monthOf(DateTime date) => DateTime(date.year, date.month);

  static Iterable<Expense> _inCurrency(
    List<Expense> expenses,
    String currencyCode, {
    String? forUserId,
  }) {
    final code = CurrencyCatalog.normalizeCode(currencyCode);
    return expenses.where((expense) {
      if (!counts(expense)) return false;
      if (CurrencyCatalog.normalizeCode(expense.currencyCode) != code) {
        return false;
      }
      if (forUserId == null || forUserId.isEmpty) return true;
      return attributedAmount(expense, forUserId: forUserId).abs() >= 0.01;
    });
  }
}

class _CategoryBucket {
  String name;
  final String? categoryId;
  final String? iconKey;
  double amount;
  DateTime latestDate;

  _CategoryBucket({
    required this.name,
    required this.categoryId,
    required this.iconKey,
    required this.amount,
    required this.latestDate,
  });
}
