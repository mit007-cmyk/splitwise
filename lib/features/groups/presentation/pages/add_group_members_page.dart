import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/di.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import 'package:splitwise/features/friends/domain/repositories/friends_repository.dart';
import 'package:splitwise/features/home/presentation/bloc/home_bloc.dart';
import 'package:splitwise/features/home/presentation/bloc/home_event.dart';
import 'package:splitwise/features/home/presentation/bloc/home_state.dart';
import 'package:splitwise/features/groups/presentation/bloc/add_group_members_cubit.dart';
import 'package:splitwise/features/activity/presentation/bloc/activity_bloc.dart';
import 'package:splitwise/features/activity/presentation/bloc/activity_event.dart';

class AddGroupMembersPage extends StatefulWidget {
  final String groupId;

  const AddGroupMembersPage({
    super.key,
    required this.groupId,
  });

  @override
  State<AddGroupMembersPage> createState() => _AddGroupMembersPageState();
}

class _AddGroupMembersPageState extends State<AddGroupMembersPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _currentUserId(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) return authState.user.id;
    return '';
  }

  void _reloadFriends(BuildContext context, AddGroupMembersCubit cubit) {
    cubit.init(
      currentUserId: _currentUserId(context),
      existingMemberIds: _getExistingMemberIds(context),
    );
  }

  List<String> _getExistingMemberIds(BuildContext context) {
    final homeBloc = context.read<HomeBloc>();
    final homeState = homeBloc.state;
    if (homeState is HomeLoaded) {
      final matchingGroups = homeState.summary.groups.where((g) => g.groupId == widget.groupId);
      if (matchingGroups.isNotEmpty) {
        return matchingGroups.first.memberIds;
      }
    }
    return [];
  }

  Widget _buildUserAvatar(UserModel user, {double radius = 22}) {
    final isUnderTest = Platform.environment.containsKey('FLUTTER_TEST');
    if (!isUnderTest && user.photoUrl != null && user.photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius.r,
        backgroundImage: NetworkImage(user.photoUrl!),
        backgroundColor: Colors.transparent,
      );
    }

    final colors = AppColors.avatarPlaceholders;
    final index = user.name.length % colors.length;
    final color = colors[index];
    final initial = user.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : 'U';

    return CircleAvatar(
      radius: radius.r,
      backgroundColor: color,
      child: Text(
        initial,
        style: TextStyle(
          color: context.appColors.onImageColor,
          fontWeight: FontWeight.bold,
          fontSize: (radius * 0.75).sp,
        ),
      ),
    );
  }

  Widget? _buildTrailingIcon(BuildContext context, UserModel user, AddGroupMembersState state) {
    if (state.existingMemberIds.contains(user.id)) {
      return Icon(
        Icons.check,
        color: context.appColors.hintTextColor,
      );
    }

    final isSelected = state.selectedUsers.any((u) => u.id == user.id);
    if (isSelected) {
      return Icon(
        Icons.check,
        color: context.colorScheme.primary,
      );
    }

    return null;
  }

  Widget _buildSelectedUsersTray(BuildContext context, AddGroupMembersState state) {
    if (state.selectedUsers.isEmpty) return const SizedBox.shrink();

    final cubit = context.read<AddGroupMembersCubit>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 84.h,
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: state.selectedUsers.length,
            itemBuilder: (context, index) {
              final user = state.selectedUsers[index];

              return Padding(
                padding: EdgeInsets.only(right: 16.w),
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _buildUserAvatar(user, radius: 20),
                        Positioned(
                          right: -4.w,
                          top: -4.h,
                          child: GestureDetector(
                            onTap: () => cubit.deselectUser(user.id),
                            child: CircleAvatar(
                              radius: 8.r,
                              backgroundColor: context.colorScheme.onSurfaceVariant,
                              child: Icon(
                                Icons.close,
                                size: 10.r,
                                color: context.appColors.onImageColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    SizedBox(
                      width: 50.w,
                      child: Text(
                        user.name.split(' ')[0],
                        style: context.textTheme.bodySmall?.copyWith(
                          fontSize: 10.sp,
                          overflow: TextOverflow.ellipsis,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  void _submitSelected(BuildContext context, List<UserModel> selectedUsers) {
    if (selectedUsers.isEmpty) return;

    final authState = context.read<AuthBloc>().state;
    final actorUserId = authState is Authenticated ? authState.user.id : '';
    if (actorUserId.isEmpty) return;

    context.read<HomeBloc>().add(AddGroupMembersRequested(
          groupId: widget.groupId,
          memberIds: selectedUsers.map((u) => u.id).toList(),
          actorUserId: actorUserId,
        ));
    context.read<ActivityBloc>().add(const RefreshActivity());

    AppToast.show(context, '${selectedUsers.length} members added to the group!', type: ToastType.success);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final existingMemberIds = _getExistingMemberIds(context);

    return BlocProvider<AddGroupMembersCubit>(
      create: (context) => AddGroupMembersCubit(getIt<FriendsRepository>())
        ..init(
          currentUserId: _currentUserId(context),
          existingMemberIds: existingMemberIds,
        ),
      child: BlocListener<HomeBloc, HomeState>(
        listener: (context, homeState) {
          if (homeState is HomeLoaded) {
            final matchingGroups = homeState.summary.groups.where((g) => g.groupId == widget.groupId);
            if (matchingGroups.isNotEmpty) {
              context.read<AddGroupMembersCubit>().updateExistingMemberIds(matchingGroups.first.memberIds);
            }
          }
        },
        child: BlocBuilder<AddGroupMembersCubit, AddGroupMembersState>(
          builder: (context, state) {
          final cubit = context.read<AddGroupMembersCubit>();

          return Scaffold(
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Custom Search AppBar
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => context.pop(),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: TextStyle(fontSize: 16.sp, color: theme.colorScheme.onSurface),
                            decoration: InputDecoration(
                              hintText: 'Enter name, email, or phone #',
                              hintStyle: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
                            ),
                            onChanged: cubit.filterUsers,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Tray for Selected Users
                  _buildSelectedUsersTray(context, state),

                  Expanded(
                    child: state.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              // Trigger to go to Add Friend
                              InkWell(
                                onTap: () async {
                                  await context.push('/add-friend');
                                  // Refresh lists when returning
                                  _reloadFriends(context, cubit);
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 22.r,
                                        backgroundColor: theme.colorScheme.onSurface.withOpacity(0.06),
                                        child: Icon(
                                          Icons.person_add_alt_1_outlined,
                                          color: theme.colorScheme.onSurface,
                                          size: 22.r,
                                        ),
                                      ),
                                      SizedBox(width: 16.w),
                                      Text(
                                        'Add a new contact to Splitwise',
                                        style: context.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Section: Friends on Splitwise
                              if (state.filteredUsers.isNotEmpty) ...[
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                  child: Text(
                                    'Friends on Splitwise',
                                    style: context.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                                    ),
                                  ),
                                ),
                                ...state.filteredUsers.map((user) {
                                  final isAlreadyInGroup = state.existingMemberIds.contains(user.id);
                                  return ListTile(
                                    leading: _buildUserAvatar(user),
                                    title: Text(
                                      user.name,
                                      style: context.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: isAlreadyInGroup
                                            ? theme.colorScheme.onSurface.withOpacity(0.5)
                                            : theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    subtitle: isAlreadyInGroup
                                        ? Text(
                                            'Already in group',
                                            style: context.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                                            ),
                                          )
                                        : null,
                                    trailing: _buildTrailingIcon(context, user, state),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                      vertical: 4.h,
                                    ),
                                    onTap: () => cubit.toggleSelection(user),
                                  );
                                }),
                              ] else if (_searchController.text.isNotEmpty) ...[
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 32.h),
                                  child: Center(
                                    child: Text(
                                      'No contacts found.',
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: state.selectedUsers.isEmpty
                        ? theme.colorScheme.onSurface.withOpacity(0.08)
                        : theme.colorScheme.primary,
                    foregroundColor: state.selectedUsers.isEmpty
                        ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
                        : theme.colorScheme.onPrimary,
                    minimumSize: Size(double.infinity, 48.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                    elevation: 0,
                  ),
                  onPressed: state.selectedUsers.isEmpty ? null : () => _submitSelected(context, state.selectedUsers),
                  child: Text(
                    'Next',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
  }
}
