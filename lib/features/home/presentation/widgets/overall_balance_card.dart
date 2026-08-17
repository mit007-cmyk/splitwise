import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../../core/utils/currency_amount.dart';
import '../../../../core/widgets/filter_popup_button.dart';
import '../../domain/entities/balance_summary.dart';

class OverallBalanceCard extends StatelessWidget {
  final BalanceSummary balance;
  final String selectedFilter;
  final ValueChanged<String> onFilterSelected;

  const OverallBalanceCard({
    super.key,
    required this.balance,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = context.appColors;
    final amounts = balance.displayAmounts;
    final hasOwed = amounts.any((item) => item.isOwed);
    final hasOwe = amounts.any((item) => item.isOwe);

    final Color amountColor;
    if (amounts.isEmpty) {
      amountColor = colors.settledBalanceColor;
    } else if (hasOwed && hasOwe) {
      amountColor = theme.colorScheme.onSurface;
    } else if (hasOwed) {
      amountColor = colors.positiveBalanceColor;
    } else {
      amountColor = colors.negativeBalanceColor;
    }

    final label = MultiCurrency.overallLabel(
      amounts: amounts,
      owedPrefix: 'you are owed',
      owePrefix: 'you owe',
      settled: "You're all settled up",
      overall: amounts.isNotEmpty,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: amountColor,
              ),
            ),
          ),
          FilterPopupButton(
            selectedFilter: selectedFilter,
            options: FilterPopupButton.groupFilters,
            onSelected: onFilterSelected,
          ),
        ],
      ),
    );
  }
}
