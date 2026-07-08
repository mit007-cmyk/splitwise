import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/utils/context_extension.dart';

/// Empty state shown when a friend (or group) has no expenses yet.
class FriendExpensesEmptyState extends StatelessWidget {
  const FriendExpensesEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'No expenses here yet.',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            'Add an expense to get this party started.',
            style: context.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 48.h),
          Transform.rotate(
            angle: 0.6,
            child: Icon(
              Icons.double_arrow_rounded,
              size: 80.r,
              color: scheme.secondary.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}
