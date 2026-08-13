import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/utils/context_extension.dart';
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

    final Color amountColor;
    final String prefixLabel;
    final String amountText;

    switch (balance.type) {
      case BalanceType.owed:
        amountColor = colors.positiveBalanceColor;
        prefixLabel = 'Overall, you are owed ';
        amountText = '₹${balance.amount.toStringAsFixed(2)}';
        break;
      case BalanceType.owe:
        amountColor = colors.negativeBalanceColor;
        prefixLabel = 'Overall, you owe ';
        amountText = '₹${balance.amount.toStringAsFixed(2)}';
        break;
      case BalanceType.settled:
        amountColor = colors.settledBalanceColor;
        prefixLabel = "You're all settled up";
        amountText = '';
        break;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: RichText(
              text: TextSpan(
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                children: [
                  TextSpan(text: prefixLabel),
                  if (amountText.isNotEmpty)
                    TextSpan(
                      text: amountText,
                      style: TextStyle(
                        color: amountColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
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
