import '../../../../core/utils/debt_settlement.dart';
import '../../data/datasources/currency_catalog.dart';
import '../entities/expense.dart';

/// Converts a single expense into [targetCode] at a market FX [rate]
/// (units of target per 1 unit of the expense's current currency).
///
/// [paidBy] and [splits] are scaled with the total so they still sum to
/// [Expense.amount] after 2-decimal rounding.
class CurrencyConverter {
  CurrencyConverter._();

  static Expense convert({
    required Expense expense,
    required String targetCode,
    required double rate,
    String? conversionNote,
  }) {
    final from = CurrencyCatalog.normalizeCode(expense.currencyCode);
    final to = CurrencyCatalog.normalizeCode(targetCode);
    if (from == to) return expense;

    final amount = _round2(expense.amount * rate);
    final paidBy = _scaleToTotal(expense.paidBy, amount);
    final splits = _scaleToTotal(expense.splits, amount);
    final symbol = CurrencyCatalog.symbolFor(to);
    final note = _mergeNote(expense.notes, conversionNote);

    return expense.copyWith(
      amount: amount,
      currencyCode: to,
      currencySymbol: symbol,
      paidBy: paidBy,
      splits: splits,
      notes: note,
    );
  }

  static String conversionNote({
    required Expense expense,
    required String targetCode,
    required double rate,
  }) {
    final from = CurrencyCatalog.byCode(
      CurrencyCatalog.normalizeCode(expense.currencyCode),
    );
    final to = CurrencyCatalog.byCode(CurrencyCatalog.normalizeCode(targetCode));
    return 'Converted from ${from.symbol}${expense.amount.toStringAsFixed(2)} '
        '${from.code} at 1 ${from.code} = ${to.symbol}${rate.toStringAsFixed(4)} ${to.code}.';
  }

  static String? _mergeNote(String? existing, String? addition) {
    final extra = addition?.trim() ?? '';
    if (extra.isEmpty) return existing;
    final prior = existing?.trim() ?? '';
    if (prior.isEmpty) return extra;
    return '$prior\n$extra';
  }

  static Map<String, double> _scaleToTotal(
    Map<String, double> source,
    double targetTotal,
  ) {
    if (source.isEmpty) return source;
    final originalTotal = source.values.fold<double>(0, (sum, value) => sum + value);
    if (originalTotal.abs() <= DebtSettlement.epsilon) {
      return {for (final entry in source.entries) entry.key: 0.0};
    }

    final scaled = <String, double>{
      for (final entry in source.entries)
        entry.key: _round2(entry.value * targetTotal / originalTotal),
    };
    final roundedTotal = scaled.values.fold<double>(0, (sum, value) => sum + value);
    final drift = _round2(targetTotal - roundedTotal);
    if (drift.abs() >= 0.01) {
      final key = scaled.entries
          .reduce((a, b) => a.value.abs() >= b.value.abs() ? a : b)
          .key;
      scaled[key] = _round2(scaled[key]! + drift);
    }
    return scaled;
  }

  static double _round2(double value) => (value * 100).round() / 100;
}
