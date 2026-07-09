import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/context_extension.dart';

class AddExpenseExtendedFab extends StatelessWidget {
  final String? groupId;

  /// When set, opens the simplified "friend mode" Add Expense flow with
  /// this friend pre-selected instead of asking the user to choose a group.
  final String? friendId;

  /// Called after returning from the Add Expense screen, regardless of
  /// whether an expense was actually saved — callers should treat this as
  /// "the user is back, refresh whatever depends on expense data".
  final VoidCallback? onExpenseAdded;

  const AddExpenseExtendedFab({
    super.key,
    this.groupId,
    this.friendId,
    this.onExpenseAdded,
  });

  Future<void> _handlePressed(BuildContext context) async {
    await context.pushNamed(
      RouteConstants.addExpenseName,
      queryParameters: {
        if (friendId != null) 'friendId': friendId!,
        if (friendId == null && groupId != null) 'groupId': groupId!,
      },
    );
    onExpenseAdded?.call();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return FloatingActionButton.extended(
      heroTag: 'friend_add_expense_fab',
      elevation: 4,
      backgroundColor: scheme.primary,
      hoverColor: AppColors.primaryHoverDark,
      foregroundColor: scheme.onPrimary,
      onPressed: () => _handlePressed(context),
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
