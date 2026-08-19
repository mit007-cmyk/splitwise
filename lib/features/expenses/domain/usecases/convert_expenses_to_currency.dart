import 'package:injectable/injectable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/services/firestore_service.dart';
import '../../data/datasources/currency_catalog.dart';
import '../entities/expense.dart';
import '../repositories/exchange_rate_repository.dart';
import '../repositories/expense_repository.dart';
import '../services/currency_converter.dart';

class CurrencyConversionResult {
  final int convertedCount;
  final String targetCode;
  final String targetSymbol;

  const CurrencyConversionResult({
    required this.convertedCount,
    required this.targetCode,
    required this.targetSymbol,
  });
}

/// Rewrites past expenses into the signed-in user's default currency using
/// live market rates — Splitwise Pro's "Convert to [currency]" behaviour.
@lazySingleton
class ConvertExpensesToCurrency {
  final ExchangeRateRepository _exchangeRates;
  final ExpenseRepository _expenseRepository;
  final FirestoreService _firestore;

  ConvertExpensesToCurrency(
    this._exchangeRates,
    this._expenseRepository,
    this._firestore,
  );

  static const _accountSettingsFallback = 'USD';

  Future<String> defaultCurrencyCode(String userId) async {
    try {
      final usersDoc = await _firestore.getDocument(
        FirestorePaths.root,
        FirestorePaths.users,
      );
      final usersData = usersDoc.data();
      final userMap = usersData?[userId];
      if (userMap is Map) {
        return _resolveStoredCode(userMap['currency'] as String?);
      }
    } catch (_) {
      // Fall through to Account Settings' default when prefs can't be read.
    }
    return _accountSettingsFallback;
  }

  bool needsConversion(List<Expense> expenses, String targetCode) {
    final target = CurrencyCatalog.normalizeCode(targetCode);
    return expenses.any(
      (expense) =>
          !expense.isDeleted &&
          CurrencyCatalog.normalizeCode(expense.currencyCode) != target,
    );
  }

  Future<Result<CurrencyConversionResult>> call({
    required String actorUserId,
    required List<Expense> expenses,
  }) async {
    final targetCode = await defaultCurrencyCode(actorUserId);
    final targetSymbol = CurrencyCatalog.symbolFor(targetCode);
    final toConvert = expenses
        .where(
          (expense) =>
              !expense.isDeleted &&
              CurrencyCatalog.normalizeCode(expense.currencyCode) !=
                  targetCode,
        )
        .toList();
    if (toConvert.isEmpty) {
      return Result.success(
        CurrencyConversionResult(
          convertedCount: 0,
          targetCode: targetCode,
          targetSymbol: targetSymbol,
        ),
      );
    }

    final ratesResult = await _exchangeRates.getUsdRates();
    if (ratesResult.isFailure) {
      return Result.failure(
        (ratesResult as FailureResult<Map<String, double>>).failure,
      );
    }
    final usdRates = ratesResult.dataOrThrow;

    for (final expense in toConvert) {
      final from = CurrencyCatalog.normalizeCode(expense.currencyCode);
      final rate = _rate(usdRates, from: from, to: targetCode);
      if (rate == null) {
        return Result.failure(
          ServerFailure('No market rate available to convert $from to $targetCode.'),
        );
      }
      final converted = CurrencyConverter.convert(
        expense: expense,
        targetCode: targetCode,
        rate: rate,
        conversionNote: CurrencyConverter.conversionNote(
          expense: expense,
          targetCode: targetCode,
          rate: rate,
        ),
      );
      final update = await _expenseRepository.updateExpense(
        expense: converted,
        actorUserId: actorUserId,
      );
      if (update.isFailure) {
        return Result.failure((update as FailureResult<void>).failure);
      }
    }

    return Result.success(
      CurrencyConversionResult(
        convertedCount: toConvert.length,
        targetCode: targetCode,
        targetSymbol: targetSymbol,
      ),
    );
  }

  static String _resolveStoredCode(String? stored) {
    final raw = (stored ?? '').trim();
    if (raw.isEmpty) return _accountSettingsFallback;
    final upper = raw.toUpperCase();
    for (final currency in CurrencyCatalog.all) {
      if (upper == currency.code || upper.startsWith('${currency.code} ')) {
        return currency.code;
      }
    }
    return CurrencyCatalog.normalizeCode(raw);
  }

  /// [usdRates] is units of each code per 1 USD.
  static double? _rate(
    Map<String, double> usdRates, {
    required String from,
    required String to,
  }) {
    if (from == to) return 1;
    final fromPerUsd = from == 'USD' ? 1.0 : usdRates[from];
    final toPerUsd = to == 'USD' ? 1.0 : usdRates[to];
    if (fromPerUsd == null ||
        toPerUsd == null ||
        fromPerUsd <= 0 ||
        toPerUsd <= 0) {
      return null;
    }
    return toPerUsd / fromPerUsd;
  }
}
