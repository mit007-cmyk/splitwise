import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/context_extension.dart';

class AddExpenseExtendedFab extends StatelessWidget {
  final VoidCallback? onPressed;

  const AddExpenseExtendedFab({
    super.key,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return FloatingActionButton.extended(
      heroTag: 'friend_add_expense_fab',
      elevation: 4,
      backgroundColor: scheme.primary,
      hoverColor: AppColors.primaryHoverDark,
      foregroundColor: scheme.onPrimary,
      onPressed: onPressed ??
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Add expense is coming soon!')),
            );
          },
      icon: Icon(Icons.receipt, size: 22.r),
      label: Text(
        'Add expense',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14.sp,
        ),
      ),
    );
  }
}
