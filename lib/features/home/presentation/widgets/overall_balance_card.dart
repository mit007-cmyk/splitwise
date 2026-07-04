import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/utils/context_extension.dart';
import '../../domain/entities/balance_summary.dart';

class OverallBalanceCard extends StatelessWidget {
  final BalanceSummary balance;
  final String selectedFilter;
  final VoidCallback onFilterTap;

  const OverallBalanceCard({
    super.key,
    required this.balance,
    required this.selectedFilter,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    final Color amountColor;
    final String prefixLabel;
    final String amountText;

    switch (balance.type) {
      case BalanceType.owed:
        amountColor = const Color(0xFF26E09C);
        prefixLabel = 'Overall, you are owed ';
        amountText = '₹${balance.amount.toStringAsFixed(2)}';
        break;
      case BalanceType.owe:
        amountColor = const Color(0xFFDD6B20);
        prefixLabel = 'Overall, you owe ';
        amountText = '₹${balance.amount.toStringAsFixed(2)}';
        break;
      case BalanceType.settled:
        amountColor = theme.colorScheme.onSurfaceVariant;
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
          IconButton(
            icon: Icon(
              selectedFilter == 'all'
                  ? Icons.filter_list_rounded
                  : Icons.filter_list_off_rounded,
              color: selectedFilter == 'all'
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.primary,
            ),
            onPressed: onFilterTap,
          ),
        ],
      ),
    );
  }
}
