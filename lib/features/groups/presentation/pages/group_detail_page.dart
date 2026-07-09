import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/context_extension.dart';
import 'package:splitwise/features/home/presentation/bloc/home_bloc.dart';
import 'package:splitwise/features/home/presentation/bloc/home_event.dart';
import 'package:splitwise/features/home/presentation/bloc/home_state.dart';

class GroupDetailPage extends StatelessWidget {
  final String groupId;

  const GroupDetailPage({
    super.key,
    required this.groupId,
  });

  Color _heroColor(String name) {
    return AppColors.avatarPlaceholders[
        name.length % AppColors.avatarPlaceholders.length];
  }

  Color _heroColorDark(String name) {
    return Color.lerp(_heroColor(name), AppColors.shadow, 0.35)!;
  }

  Future<void> _openAddExpense(BuildContext context, String groupId) async {
    await context.pushNamed(
      RouteConstants.addExpenseName,
      queryParameters: {'groupId': groupId},
    );
    if (context.mounted) {
      context.read<HomeBloc>().add(const RefreshHome());
    }
  }

  void _showAddExpenseDialog(BuildContext context, String groupId) {
    final theme = context.theme;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'You are the only person in this group.',
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              Text(
                'Do you need to add anyone to your group before you start adding expenses?',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              ElevatedButton(
                style: theme.elevatedButtonTheme.style,
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _openAddExpense(context, groupId);
                },
                child: Text(
                  'Start adding expenses',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp),
                ),
              ),
              SizedBox(height: 12.h),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  context.push('/group-detail/$groupId/add-members');
                },
                child: Text(
                  'Add group members',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15.sp,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionPill(BuildContext context, String label, {IconData? icon}) {
    final scheme = context.colorScheme;
    return Container(
      margin: EdgeInsets.only(right: 8.w),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outline),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16.r, color: scheme.secondary),
            SizedBox(width: 6.w),
          ],
          Text(
            label,
            style: context.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is HomeLoaded) {
          final groupIndex = state.summary.groups.indexWhere((g) => g.groupId == groupId);
          if (groupIndex == -1) {
            return const Scaffold(
              body: Center(child: Text('Group details not found.')),
            );
          }
          final group = state.summary.groups[groupIndex];
          final colors = context.appColors;
          final heroColor = _heroColor(group.groupName);
          final heroColorDark = _heroColorDark(group.groupName);
          final memberCount = group.memberIds.length;
          final isSingleMember = memberCount <= 1;

          return Scaffold(
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 180.h,
                    backgroundColor: heroColor,
                    elevation: 0,
                    leading: Padding(
                      padding: EdgeInsets.only(left: 8.w, top: 4.h, bottom: 4.h),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: colors.onImageColor),
                        style: IconButton.styleFrom(
                          backgroundColor: colors.overlayColor.withValues(alpha: 0.3),
                          shape: const CircleBorder(),
                        ),
                        onPressed: () => context.pop(),
                      ),
                    ),
                    actions: [
                      Padding(
                        padding: EdgeInsets.only(right: 8.w, top: 4.h, bottom: 4.h),
                        child: IconButton(
                          icon: Icon(Icons.settings_outlined, color: colors.onImageColor),
                          style: IconButton.styleFrom(
                            backgroundColor: colors.overlayColor.withValues(alpha: 0.3),
                            shape: const CircleBorder(),
                          ),
                          onPressed: () => context.push('/group-detail/$groupId/settings'),
                        ),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      collapseMode: CollapseMode.pin,
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [heroColor, heroColorDark],
                          ),
                        ),
                        padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 16.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              group.groupName,
                              style: context.textTheme.headlineMedium?.copyWith(
                                color: colors.onImageColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (!isSingleMember) ...[
                              SizedBox(height: 8.h),
                              InkWell(
                                onTap: () => context.push('/group-detail/$groupId/settings'),
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                                  decoration: BoxDecoration(
                                    color: colors.overlayColor.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.people_outline_rounded,
                                        size: 16.r,
                                        color: colors.onImageColor.withValues(alpha: 0.9),
                                      ),
                                      SizedBox(width: 6.w),
                                      Text(
                                        '$memberCount people +',
                                        style: TextStyle(
                                          color: colors.onImageColor.withValues(alpha: 0.9),
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      title: LayoutBuilder(
                        builder: (context, constraints) {
                          // Standard appBarMaxHeight collapsed is roughly 88.0 under safe area.
                          // constraints.maxHeight gives us the dynamic height of the flex app bar.
                          final isCollapsed = constraints.maxHeight <= (Scaffold.of(context).appBarMaxHeight ?? 88.0);
                          return AnimatedOpacity(
                            duration: const Duration(milliseconds: 150),
                            opacity: isCollapsed ? 1.0 : 0.0,
                            child: Text(
                              group.groupName,
                              style: TextStyle(
                                color: colors.onImageColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                      centerTitle: false,
                    ),
                  ),
                ];
              },
              body: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Scrollable actions
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildActionPill(context, 'Settle up'),
                            _buildActionPill(context, 'Charts', icon: Icons.diamond_rounded),
                            _buildActionPill(context, 'Balances'),
                            _buildActionPill(context, 'Totals'),
                          ],
                        ),
                      ),
                    ),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (isSingleMember) ...[
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 20.w),
                              decoration: BoxDecoration(
                                color: colors.elevatedSurface,
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    "You're the only one here!",
                                    style: context.textTheme.titleMedium?.copyWith(
                                      color: colors.onImageColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 20.h),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      style: theme.elevatedButtonTheme.style?.copyWith(
                                        shape: WidgetStatePropertyAll(
                                          RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(24.r),
                                          ),
                                        ),
                                        padding: WidgetStatePropertyAll(
                                          EdgeInsets.symmetric(vertical: 12.h),
                                        ),
                                      ),
                                      onPressed: () => context.push('/group-detail/$groupId/add-members'),
                                      icon: const Icon(Icons.person_add_outlined),
                                      label: const Text('Add group members'),
                                    ),
                                  ),
                                  SizedBox(height: 12.h),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color: colors.onImageColor.withValues(alpha: 0.24),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(24.r),
                                        ),
                                        padding: EdgeInsets.symmetric(vertical: 12.h),
                                      ),
                                      onPressed: () {},
                                      child: Text(
                                        'Share group link',
                                        style: TextStyle(color: colors.onImageColor),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            // When multiple members exist but no expenses are listed
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 16.w),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'No expenses here yet.',
                                    style: context.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    'Add an expense to get this party started.',
                                    style: context.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 48.h),
                                  Transform.rotate(
                                    angle: 0.6,
                                    child: Icon(
                                      Icons.double_arrow_rounded,
                                      size: 80.r,
                                      color: theme.colorScheme.secondary.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            floatingActionButton: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: null,
                  elevation: 4,
                  backgroundColor: colors.elevatedSurface,
                  hoverColor: colors.elevatedSurfaceHover,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Receipt scanning coming soon!')),
                    );
                  },
                  child: Icon(Icons.photo_camera_outlined, color: colors.onImageColor),
                ),
                SizedBox(height: 12.h),
                FloatingActionButton(
                  heroTag: null,
                  elevation: 4,
                  backgroundColor: theme.colorScheme.primary,
                  hoverColor: AppColors.primaryHoverDark,
                  onPressed: () {
                    if (isSingleMember) {
                      _showAddExpenseDialog(context, groupId);
                    } else {
                      _openAddExpense(context, groupId);
                    }
                  },
                  child: Icon(Icons.receipt, color: theme.colorScheme.onPrimary),
                ),
              ],
            ),
          );
        }

        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
