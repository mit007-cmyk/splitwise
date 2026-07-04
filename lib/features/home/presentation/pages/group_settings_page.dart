import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/di.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/repositories/home_repository.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';

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
    final colors = [
      const Color(0xFF0F766E), // teal
      const Color(0xFF1E3A8A), // deep blue
      const Color(0xFF065F46), // deep green
      const Color(0xFF9D174D), // pink
      const Color(0xFF374151), // slate grey
    ];
    final index = name.length % colors.length;
    return colors[index];
  }

  Widget _buildUserAvatar(String name) {
    final colors = [
      const Color(0xFF0F766E),
      const Color(0xFF1E3A8A),
      const Color(0xFF065F46),
      const Color(0xFF9D174D),
      const Color(0xFF374151),
    ];
    final index = name.length % colors.length;
    final color = colors[index];
    final initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U';

    return CircleAvatar(
      radius: 22.r,
      backgroundColor: color,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
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
                        child: const Icon(
                          Icons.list_alt_rounded,
                          color: Colors.white,
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
                  onTap: () {},
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

                    return ListTile(
                      leading: _buildUserAvatar(user.name),
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
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
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
                      Switch(
                        value: _simplifyDebts,
                        onChanged: (val) {
                          setState(() {
                            _simplifyDebts = val;
                          });
                        },
                        activeColor: theme.colorScheme.primary,
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
                  leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                  title: const Text(
                    'Leave group',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        backgroundColor: const Color(0xFF2C2C2E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        title: Text(
                          'Leave group?',
                          style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold),
                        ),
                        content: Text(
                          'Are you sure you want to leave this group? This cannot be undone.',
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14.sp),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              context.read<HomeBloc>().add(LeaveGroupRequested(groupId: widget.groupId));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('You have left the group.')),
                              );
                              context.go('/home/groups');
                            },
                            child: const Text('Leave', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
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
