import 'package:flutter/material.dart';

import '../../../../core/di/di.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../data/datasources/currency_catalog.dart';
import '../../domain/entities/expense.dart';
import '../../domain/usecases/convert_expenses_to_currency.dart';
import '../widgets/currency_convert_icon.dart';

/// Shared confirm + convert flow for group and friend "Convert to [currency]".
class CurrencyConversionAction {
  CurrencyConversionAction._();

  static ConvertExpensesToCurrency get _useCase =>
      getIt<ConvertExpensesToCurrency>();

  static Future<String> defaultCode(String userId) async {
    try {
      return await _useCase.defaultCurrencyCode(userId);
    } catch (_) {
      return 'USD';
    }
  }

  static bool shouldShow(List<Expense> expenses, String? defaultCode) {
    final codes = expenses
        .where((expense) => !expense.isDeleted)
        .map((expense) => CurrencyCatalog.normalizeCode(expense.currencyCode))
        .toSet();
    if (codes.length > 1) return true;
    if (defaultCode == null || defaultCode.isEmpty || codes.isEmpty) {
      return false;
    }
    return codes.any(
      (code) => code != CurrencyCatalog.normalizeCode(defaultCode),
    );
  }

  static String buttonLabel(String defaultCode) =>
      'Convert to ${CurrencyCatalog.normalizeCode(defaultCode)}';

  static Widget buttonIcon({
    required String defaultCode,
    required Color color,
    required double size,
  }) {
    return CurrencyConvertIcon(
      currencyCode: defaultCode,
      color: color,
      size: size,
    );
  }

  static Future<bool> confirmAndRun({
    required BuildContext context,
    required String actorUserId,
    required List<Expense> expenses,
    required String scopeLabel,
  }) async {
    final targetCode = await _useCase.defaultCurrencyCode(actorUserId);
    if (!context.mounted) return false;

    if (!_useCase.needsConversion(expenses, targetCode)) {
      AppToast.show(
        context,
        'All expenses are already in $targetCode.',
        type: ToastType.info,
      );
      return false;
    }

    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Convert to $targetCode?',
      content:
          'This converts every past expense in this $scopeLabel to $targetCode '
          'at the current market exchange rate. Amounts, splits, and balances '
          'will update.',
      confirmText: 'Convert',
      onConfirm: () {},
    );
    if (confirmed != true || !context.mounted) return false;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = await _useCase(
      actorUserId: actorUserId,
      expenses: expenses,
    );

    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    if (!context.mounted) return false;

    if (result.isFailure) {
      AppToast.show(
        context,
        (result as FailureResult).failure.message,
        type: ToastType.error,
      );
      return false;
    }

    final converted = result.dataOrThrow;
    AppToast.show(
      context,
      converted.convertedCount == 1
          ? 'Converted 1 expense to ${converted.targetCode}.'
          : 'Converted ${converted.convertedCount} expenses to ${converted.targetCode}.',
      type: ToastType.success,
    );
    return true;
  }
}
