import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/di.dart';
import '../../../../core/routing/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../../core/widgets/app_switch.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import 'package:splitwise/features/home/domain/entities/balance_summary.dart';
import 'package:splitwise/features/home/domain/entities/group_summary.dart';
import 'package:splitwise/features/home/domain/repositories/home_repository.dart';
import 'package:splitwise/features/activity/presentation/bloc/activity_bloc.dart';
import 'package:splitwise/features/activity/presentation/bloc/activity_event.dart';
import 'package:splitwise/features/home/presentation/bloc/home_bloc.dart';
import 'package:splitwise/features/home/presentation/bloc/home_event.dart';
import 'package:splitwise/features/home/presentation/bloc/home_state.dart';

class GroupSettingsPage extends StatefulWidget {
  final String groupId;

  const GroupSettingsPage({
    super.key,
    required this.groupId,
  });

  @override
  State<GroupSettingsPage> createState() => _GroupSettingsPageState();
}

class _GroupSettingsPageState extends State<GroupSettingsPage> {
  List<UserModel> _allUsers = [];
  bool _isLoadingUsers = true;
  bool _simplifyDebts = false;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    final result = await getIt<HomeRepository>().getAllUsers();
    if (mounted) {
      setState(() {
        _allUsers = result.isSuccess ? result.dataOrThrow : [];
        _isLoadingUsers = false;
      });
    }
  }

  Color _getGroupColor(String name) {
    final index = name.length % AppColors.avatarPlaceholders.length;
    return AppColors.avatarPlaceholders[index];
  }

  Widget _buildUserAvatar(BuildContext context, String name) {
    final color = _getGroupColor(name);
    final initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U';

    return CircleAvatar(
      radius: 22.r,
      backgroundColor: color,
      child: Text(
        initial,
        style: TextStyle(
          color: context.appColors.onImageColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showMemberActionsSheet(
    BuildContext context, {
    required String groupId,
    required UserModel member,
    required bool isSettled,
    required String balanceLabel,
    required Color balanceColor,
  }) {
    final theme = context.theme;
    final homeBloc = context.read<HomeBloc>();

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(top: 8.h, bottom: 8.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 16.h),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    children: [
                      _buildUserAvatar(context, member.name),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member.name,
                              style: context.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (member.email.isNotEmpty)
                              Text(
                                member.email,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        balanceLabel,
                        style: TextStyle(
                          color: balanceColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.person_outline, color: theme.colorScheme.onSurface),
                  title: Text(
                    'View settings',
                    style: context.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    context.pushNamed(
                      RouteConstants.friendSettingsName,
                      pathParameters: {'friendId': member.id},
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.logout_rounded,
                    color: isSettled
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                  ),
                  title: Text(
                    'Remove from group',
                    style: TextStyle(
                      color: isSettled
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: isSettled
                      ? null
                      : Text(
                          "You can't remove this person until their debts are settled up.",
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                            fontSize: 12.sp,
                          ),
                        ),
                  onTap: isSettled
                      ? () {
                          Navigator.of(sheetContext).pop();
                          _confirmRemoveGroupMember(
                            homeBloc: homeBloc,
                            groupId: groupId,
                            member: member,
                          );
                        }
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmRemoveGroupMember({
    required HomeBloc homeBloc,
    required String groupId,
    required UserModel member,
  }) {
    final theme = context.theme;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Remove group member',
          style: context.textTheme.titleLarge,
        ),
        content: Text(
          'Are you sure you want to remove this person from this group?',
          style: context.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              homeBloc.add(
                RemoveGroupMemberRequested(groupId: groupId, memberId: member.id),
              );
              AppToast.show(context, '${member.name} removed from group.', type: ToastType.success);
            },
            child: Text(
              'OK',
              style: TextStyle(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteGroup({required GroupSummary group}) {
    final theme = context.theme;
    final hasUnsettledBalances = group.memberBalances.isNotEmpty;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Delete group?',
          style: context.textTheme.titleLarge,
        ),
        content: Text(
          hasUnsettledBalances
              ? 'This group still has unsettled balances. Settle up before deleting "${group.groupName}".'
              : 'Are you sure you want to permanently delete "${group.groupName}"? This cannot be undone.',
          style: context.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              hasUnsettledBalances ? 'OK' : 'Cancel',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          if (!hasUnsettledBalances)
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<HomeBloc>().add(
                      DeleteGroupRequested(groupId: widget.groupId),
                    );
                context.read<ActivityBloc>().add(const RefreshActivity());
                AppToast.show(context, '"${group.groupName}" was deleted.', type: ToastType.success);
                context.go('/home/groups');
              },
              child: Text(
                'Delete',
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
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
          final groupIndex = state.summary.groups.indexWhere((g) => g.groupId == widget.groupId);
          if (groupIndex == -1) {
            return const Scaffold(
              body: Center(child: Text('Group details not found.')),
            );
          }
          final group = state.summary.groups[groupIndex];

          // Get current authenticated user ID
          String currentUserId = '';
          final authState = context.read<AuthBloc>().state;
          if (authState is Authenticated) {
            currentUserId = authState.user.id;
          }

          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
              title: Text(
                'Group settings',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: false,
            ),
            body: ListView(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              children: [
                // Group Info Header Row
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  child: Row(
                    children: [
                      Container(
                        width: 56.w,
                        height: 56.h,
                        decoration: BoxDecoration(
                          color: _getGroupColor(group.groupName),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.list_alt_rounded,
                          color: context.appColors.onImageColor,
                          size: 32,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.groupName,
                              style: context.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              group.groupType,
                              style: context.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit_outlined, color: theme.colorScheme.onSurface),
                        onPressed: () => context.push('/group-detail/${widget.groupId}/edit'),
                      ),
                    ],
                  ),
                ),
                
                const Divider(),

                // Group Members Section
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: Text(
                    'Group members',
                    style: context.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                ),

                ListTile(
                  leading: CircleAvatar(
                    radius: 22.r,
                    backgroundColor: theme.colorScheme.onSurface.withOpacity(0.06),
                    child: Icon(Icons.person_add_alt_1_outlined, color: theme.colorScheme.onSurface),
                  ),
                  title: Text(
                    'Add people to group',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () async {
                    await context.push('/group-detail/${widget.groupId}/add-members');
                    _fetchUsers(); // Refresh when returning
                  },
                ),

                ListTile(
                  leading: CircleAvatar(
                    radius: 22.r,
                    backgroundColor: theme.colorScheme.onSurface.withOpacity(0.06),
                    child: Icon(Icons.link_rounded, color: theme.colorScheme.onSurface),
                  ),
                  title: Text(
                    'Invite via link',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () => context.push('/group-detail/${widget.groupId}/invite-link'),
                ),

                if (_isLoadingUsers)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ))
                else
                  ...group.memberIds.map((mId) {
                    final user = _allUsers.firstWhere(
                      (u) => u.id == mId,
                      orElse: () => UserModel(id: mId, name: mId.split('@')[0], email: ''),
                    );

                    final bool isMe = user.id == currentUserId;
                    final displayName = isMe ? '${user.name} (you)' : user.name;

                    MemberBalance? balanceEntry;
                    for (final balance in group.memberBalances) {
                      if (balance.userId == mId) {
                        balanceEntry = balance;
                        break;
                      }
                    }

                    final String balanceLabel;
                    final Color balanceColor;
                    if (balanceEntry == null) {
                      balanceLabel = 'settled up';
                      balanceColor = context.appColors.settledBalanceColor;
                    } else if (balanceEntry.type == BalanceType.owed) {
                      balanceLabel = 'owes ₹${balanceEntry.amount.toStringAsFixed(2)}';
                      balanceColor = context.appColors.positiveBalanceColor;
                    } else {
                      balanceLabel = 'you owe ₹${balanceEntry.amount.toStringAsFixed(2)}';
                      balanceColor = context.appColors.negativeBalanceColor;
                    }

                    return ListTile(
                      leading: _buildUserAvatar(context, user.name),
                      title: Text(
                        displayName,
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: user.email.isNotEmpty
                          ? Text(
                              user.email,
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                              ),
                            )
                          : null,
                      trailing: isMe
                          ? null
                          : Text(
                              balanceLabel,
                              style: TextStyle(
                                color: balanceColor,
                                fontWeight: FontWeight.w500,
                                fontSize: 12.sp,
                              ),
                            ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                      onTap: isMe
                          ? null
                          : () => _showMemberActionsSheet(
                                context,
                                groupId: widget.groupId,
                                member: user,
                                isSettled: balanceEntry == null,
                                balanceLabel: balanceLabel,
                                balanceColor: balanceColor,
                              ),
                    );
                  }),

                const Divider(),

                // Advanced Settings Section
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: Text(
                    'Advanced settings',
                    style: context.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                ),

                ListTile(
                  leading: Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: Icon(Icons.share_outlined, color: theme.colorScheme.onSurface),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Simplify group debts',
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      AppSwitch(
                        value: _simplifyDebts,
                        onChanged: (val) {
                          setState(() {
                            _simplifyDebts = val;
                          });
                        },
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: EdgeInsets.only(top: 4.h),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                          fontSize: 12.sp,
                          height: 1.3,
                        ),
                        children: [
                          const TextSpan(
                            text: 'Automatically combines debts to reduce the total number of repayments between group members. ',
                          ),
                          TextSpan(
                            text: 'Learn more',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                ListTile(
                  leading: Padding(
                    padding: EdgeInsets.only(top: 4.h),
                    child: Icon(Icons.dehaze_rounded, color: theme.colorScheme.onSurface),
                  ),
                  title: Row(
                    children: [
                      Text(
                        'Default split',
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          'PRO',
                          style: TextStyle(
                            color: Colors.purpleAccent,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: EdgeInsets.only(top: 4.h),
                    child: Text(
                      'Paid by you and split equally\n\nNew expenses you add to this group will default to this setting, which is personal, not group-wide.',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                        fontSize: 12.sp,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),

                ListTile(
                  leading: Icon(Icons.logout_rounded, color: theme.colorScheme.error),
                  title: Text(
                    'Leave group',
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        backgroundColor: theme.colorScheme.surfaceContainerHigh,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        title: Text(
                          'Leave group?',
                          style: context.textTheme.titleLarge,
                        ),
                        content: Text(
                          'Are you sure you want to leave this group? This cannot be undone.',
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: Text(
                              'Cancel',
                              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              context.read<HomeBloc>().add(LeaveGroupRequested(groupId: widget.groupId));
                              AppToast.show(context, 'You have left the group.', type: ToastType.success);
                              context.go('/home/groups');
                            },
                            child: Text(
                              'Leave',
                              style: TextStyle(
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                ListTile(
                  leading: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error),
                  title: Text(
                    'Delete group',
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () => _confirmDeleteGroup(group: group),
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
