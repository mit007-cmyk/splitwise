import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static String format(double amount, {String currencySymbol = '\$', int decimalDigits = 2}) {
    return NumberFormat.currency(
      symbol: currencySymbol,
      decimalDigits: decimalDigits,
    ).format(amount);
  }

  static String formatCompact(double amount, {String currencySymbol = '\$'}) {
    return NumberFormat.compactSimpleCurrency(name: currencySymbol).format(amount);
  }
}
