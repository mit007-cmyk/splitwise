import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_state.dart';

class GroupDetailPage extends StatelessWidget {
  final String groupId;

  const GroupDetailPage({
    super.key,
    required this.groupId,
  });

  void _showAddExpenseDialog(BuildContext context, String groupId) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2C2E),
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
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              Text(
                'Do you need to add anyone to your group before you start adding expenses?',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.7),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF15B77E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Add Expense is coming soon!')),
                  );
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
                    color: const Color(0xFF15B77E),
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

  Widget _buildTopBanner(BuildContext context, String groupName, int memberCount, String groupId) {
    final showPill = memberCount > 1;

    return Container(
      height: 160.h,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF8B4513), // dark orange-brown banner
            Color(0xFF5C2D0C),
          ],
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            groupName,
            style: context.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (showPill) ...[
            SizedBox(height: 8.h),
            InkWell(
              onTap: () => context.push('/group-detail/$groupId/settings'),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people_outline_rounded,
                      size: 16.r,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      '$memberCount people +',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
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
    );
  }

  Widget _buildActionPill(String label, {IconData? icon}) {
    return Container(
      margin: EdgeInsets.only(right: 8.w),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16.r, color: Colors.purpleAccent),
            SizedBox(width: 6.w),
          ],
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
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
          
          final memberCount = group.memberIds.length;
          final isSingleMember = memberCount <= 1;

          return AppScaffold(
            appBar: AppBar(
              backgroundColor: const Color(0xFF8B4513),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Colors.white),
                  onPressed: () => context.push('/group-detail/$groupId/settings'),
                ),
              ],
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTopBanner(context, group.groupName, memberCount, groupId),
                
                // Scrollable actions
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildActionPill('Settle up'),
                        _buildActionPill('Charts', icon: Icons.diamond_rounded),
                        _buildActionPill('Balances'),
                        _buildActionPill('Totals'),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (isSingleMember) ...[
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 20.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C2C2E),
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  "You're the only one here!",
                                  style: context.textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 20.h),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF15B77E),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24.r),
                                      ),
                                      padding: EdgeInsets.symmetric(vertical: 12.h),
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
                                      side: const BorderSide(color: Colors.white24),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24.r),
                                      ),
                                      padding: EdgeInsets.symmetric(vertical: 12.h),
                                    ),
                                    onPressed: () {},
                                    child: const Text('Share group link', style: TextStyle(color: Colors.white)),
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
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  'Add an expense to get this party started.',
                                  style: context.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 48.h),
                                Transform.rotate(
                                  angle: 0.6,
                                  child: Icon(
                                    Icons.double_arrow_rounded,
                                    size: 80.r,
                                    color: Colors.pinkAccent.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            floatingActionButton: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'group_scan_fab',
                  elevation: 4,
                  backgroundColor: const Color(0xFF2C2C2E),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Receipt scanning coming soon!')),
                    );
                  },
                  icon: const Icon(Icons.photo_camera_outlined, color: Colors.white),
                  label: const Text('Scan', style: TextStyle(color: Colors.white)),
                ),
                SizedBox(height: 12.h),
                FloatingActionButton.extended(
                  heroTag: 'group_add_expense_fab',
                  elevation: 4,
                  backgroundColor: const Color(0xFF15B77E),
                  onPressed: () {
                    if (isSingleMember) {
                      _showAddExpenseDialog(context, groupId);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Add Expense is coming soon!')),
                      );
                    }
                  },
                  icon: const Icon(Icons.receipt_long_rounded, color: Colors.white),
                  label: const Text('Add expense', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
