import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/context_extension.dart';
import '../bloc/add_expense_bloc.dart';
import '../bloc/add_expense_event.dart';
import '../bloc/add_expense_state.dart';

/// Lets the user pick which group this expense belongs to — the "With you
/// and: ..." chip on the Add Expense screen opens this sheet.
class GroupPickerSheet extends StatelessWidget {
  const GroupPickerSheet({super.key});

  static Future<void> show(BuildContext context, AddExpenseBloc bloc) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: context.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXl.r)),
      ),
      builder: (sheetContext) => BlocProvider.value(
        value: bloc,
        child: const GroupPickerSheet(),
      ),
    );
  }

  Color _colorFor(String name) =>
      AppColors.avatarPlaceholders[name.length % AppColors.avatarPlaceholders.length];

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return BlocBuilder<AddExpenseBloc, AddExpenseState>(
      builder: (context, state) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: context.screenHeight * 0.7),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.all(AppDimensions.lg.w),
                  child: Text(
                    'With you and:',
                    style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (state.availableGroups.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDimensions.lg.w,
                      vertical: AppDimensions.xl.h,
                    ),
                    child: Text(
                      "You don't have any groups yet. Create a group first to add an expense.",
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: state.availableGroups.length,
                      itemBuilder: (context, index) {
                        final group = state.availableGroups[index];
                        final isSelected = group.groupId == state.groupId;

                        return ListTile(
                          leading: CircleAvatar(
                            radius: 20.r,
                            backgroundColor: _colorFor(group.groupName),
                            child: Icon(
                              Icons.list_alt_rounded,
                              color: context.appColors.onImageColor,
                              size: 18.r,
                            ),
                          ),
                          title: Text('All of ${group.groupName}'),
                          trailing:
                              isSelected ? Icon(Icons.check, color: scheme.primary) : null,
                          onTap: () {
                            context.read<AddExpenseBloc>().add(GroupSelected(group.groupId));
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    ),
                  ),
                SizedBox(height: AppDimensions.sm.h),
              ],
            ),
          ),
        );
      },
    );
  }
}
