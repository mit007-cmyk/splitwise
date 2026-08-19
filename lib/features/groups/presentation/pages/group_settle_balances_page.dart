import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../expenses/presentation/utils/currency_conversion_action.dart';
import '../../../home/domain/entities/balance_summary.dart';
import '../../../home/domain/entities/group_summary.dart';
import 'group_record_payment_page.dart';

class GroupSettleBalancesPage extends StatelessWidget {
  final String groupId;
  final String currentUserId;
  final List<MemberBalance> balances;
  final List<Expense> expenses;
  final String? defaultCurrencyCode;

  const GroupSettleBalancesPage({
    super.key,
    required this.groupId,
    required this.currentUserId,
    required this.balances,
    this.expenses = const [],
    this.defaultCurrencyCode,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final appColors = context.appColors;
    final validBalances = balances
        .where((b) => b.userId.trim().isNotEmpty && b.amount > 0.01)
        .toList();
    final showConvert = CurrencyConversionAction.shouldShow(
      expenses,
      defaultCurrencyCode,
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: Text(
          'Select a balance to settle',
          style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: AppDimensions.md.h),
        children: [
          ...validBalances.map((balance) {
            final isOwed = balance.type == BalanceType.owed;
            return ListTile(
              leading: AvatarWidget(name: balance.userName, size: 42.w),
              title: Text(
                balance.userName,
                style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isOwed ? 'you are owed' : 'you owe',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: isOwed
                          ? appColors.positiveBalanceColor
                          : appColors.negativeBalanceColor,
                    ),
                  ),
                  Text(
                    balance.formattedAmount,
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isOwed
                          ? appColors.positiveBalanceColor
                          : appColors.negativeBalanceColor,
                    ),
                  ),
                ],
              ),
              onTap: () async {
                final recorded = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => GroupRecordPaymentPage(
                      groupId: groupId,
                      currentUserId: currentUserId,
                      balance: balance,
                    ),
                  ),
                );
                if (recorded == true && context.mounted) {
                  Navigator.of(context).pop(true);
                }
              },
            );
          }),
          if (showConvert) ...[
            SizedBox(height: AppDimensions.lg.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppDimensions.lg.w),
              child: Text(
                'More options',
                style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            SizedBox(height: AppDimensions.md.h),
            Center(
              child: OutlinedButton.icon(
                onPressed: () => _convert(context),
                icon: CurrencyConversionAction.buttonIcon(
                  defaultCode: defaultCurrencyCode ?? 'USD',
                  color: scheme.secondary,
                  size: 18.r,
                ),
                label: Text(
                  CurrencyConversionAction.buttonLabel(
                    defaultCurrencyCode ?? 'USD',
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _convert(BuildContext context) async {
    if (currentUserId.isEmpty) {
      AppToast.show(context, 'Please log in again.', type: ToastType.error);
      return;
    }
    final converted = await CurrencyConversionAction.confirmAndRun(
      context: context,
      actorUserId: currentUserId,
      expenses: expenses,
      scopeLabel: 'group',
    );
    if (converted && context.mounted) {
      Navigator.of(context).pop(true);
    }
  }
}
