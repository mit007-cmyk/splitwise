import 'package:intl/intl.dart';

extension DoubleExtension on double {
  String toCurrency({String currencySymbol = '\$', int decimalDigits = 2}) {
    return NumberFormat.currency(
      symbol: currencySymbol,
      decimalDigits: decimalDigits,
    ).format(this);
  }

  String toPercentage({int decimalDigits = 1}) {
    return '${toStringAsFixed(decimalDigits)}%';
  }
}
