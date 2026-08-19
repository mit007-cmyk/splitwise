import '../../../../core/errors/result.dart';

/// Market FX quotes used to convert historical expenses into one currency.
abstract class ExchangeRateRepository {
  /// Units of each currency code per 1 USD. USD itself is always `1`.
  Future<Result<Map<String, double>>> getUsdRates();
}
