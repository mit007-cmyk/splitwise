import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/di.dart';
import '../../../../core/services/contacts_service.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import 'package:splitwise/features/friends/domain/repositories/friends_repository.dart';
import 'package:splitwise/features/home/presentation/bloc/home_bloc.dart';
import 'package:splitwise/features/home/presentation/bloc/home_state.dart';
import 'package:splitwise/features/groups/domain/entities/group_member_invite.dart';
import 'package:splitwise/features/groups/presentation/bloc/add_group_members_cubit.dart';
import 'package:splitwise/features/groups/presentation/pages/add_group_members_review_page.dart';
import 'package:splitwise/features/groups/presentation/pages/group_member_invite_form_page.dart';

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

  Future<void> _openNewContact(BuildContext context, AddGroupMembersCubit cubit) async {
    final invite = await Navigator.of(context).push<GroupMemberInvite>(
      MaterialPageRoute(
        builder: (_) => const GroupMemberInviteFormPage(),
      ),
    );
    if (invite == null || !context.mounted) return;
    cubit.upsertInvite(invite);
  }

  Future<void> _openReview(BuildContext context) async {
    final cubit = context.read<AddGroupMembersCubit>();
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: AddGroupMembersReviewPage(groupId: widget.groupId),
        ),
      ),
    );
    if (added == true && context.mounted) context.pop();
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
    return AvatarWidget(
      name: user.name,
      imageUrl: user.photoUrl,
      size: radius.r * 2,
    );
  }

  Widget? _buildTrailingIcon(BuildContext context, UserModel user, AddGroupMembersState state) {
    if (state.existingMemberIds.contains(user.id)) {
      return Icon(
        Icons.check,
        color: context.appColors.hintTextColor,
      );
    }

    final isSelected = state.selected.any((invite) => invite.key == user.id);
    if (isSelected) {
      return Icon(
        Icons.check,
        color: context.colorScheme.primary,
      );
    }

    return null;
  }

  Widget _buildSelectedUsersTray(BuildContext context, AddGroupMembersState state) {
    if (state.selected.isEmpty) return const SizedBox.shrink();

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
            itemCount: state.selected.length,
            itemBuilder: (context, index) {
              final invite = state.selected[index];

              return Padding(
                padding: EdgeInsets.only(right: 16.w),
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        inviteLeadingAvatar(context, invite, radius: 20),
                        Positioned(
                          right: -4.w,
                          top: -4.h,
                          child: GestureDetector(
                            onTap: () => cubit.deselect(invite.key),
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
                        invite.shortLabel,
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

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final existingMemberIds = _getExistingMemberIds(context);

    return BlocProvider<AddGroupMembersCubit>(
      create: (context) => AddGroupMembersCubit(
        getIt<FriendsRepository>(),
        getIt<ContactsService>(),
      )..init(
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
                                onTap: () => _openNewContact(context, cubit),
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
                              ],

                              if (state.filteredContacts.isNotEmpty) ...[
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                  child: Text(
                                    'From your contacts',
                                    style: context.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                                    ),
                                  ),
                                ),
                                ...state.filteredContacts.map((contact) {
                                  final contactKey = 'contact:${contact.id}';
                                  final matched = state.registeredMatches[contact.id];
                                  final isSelected = matched != null
                                      ? cubit.isSelectedKey(matched.id)
                                      : cubit.isSelectedKey(contactKey);
                                  final onSplitwise = matched != null;
                                  return ListTile(
                                    leading: CircleAvatar(
                                      radius: 22.r,
                                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                      child: Icon(
                                        contact.phone != null
                                            ? Icons.phone
                                            : Icons.email_outlined,
                                        color: theme.colorScheme.onSurfaceVariant,
                                        size: 20.r,
                                      ),
                                    ),
                                    title: Text(
                                      contact.displayName,
                                      style: context.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text(
                                      onSplitwise
                                          ? 'On Splitwise'
                                          : (contact.subtitle.isNotEmpty
                                              ? contact.subtitle
                                              : 'Invite to the app'),
                                      style: context.textTheme.bodySmall?.copyWith(
                                        color: onSplitwise
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.onSurfaceVariant
                                                .withOpacity(0.7),
                                      ),
                                    ),
                                    trailing: isSelected
                                        ? Icon(
                                            Icons.check,
                                            color: theme.colorScheme.primary,
                                          )
                                        : Text(
                                            onSplitwise ? 'Add' : 'Invite',
                                            style: TextStyle(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                      vertical: 4.h,
                                    ),
                                    onTap: () => cubit.toggleContact(contact),
                                  );
                                }),
                              ],

                              if (state.isLoadingContacts)
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24.h),
                                  child: const Center(child: CircularProgressIndicator()),
                                )
                              else if (_searchController.text.isNotEmpty &&
                                  state.filteredUsers.isEmpty &&
                                  state.filteredContacts.isEmpty) ...[
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
                    backgroundColor: state.selected.isEmpty
                        ? theme.colorScheme.onSurface.withOpacity(0.08)
                        : theme.colorScheme.primary,
                    foregroundColor: state.selected.isEmpty
                        ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
                        : theme.colorScheme.onPrimary,
                    minimumSize: Size(double.infinity, 48.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                    elevation: 0,
                  ),
                  onPressed: state.selected.isEmpty ? null : () => _openReview(context),
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
