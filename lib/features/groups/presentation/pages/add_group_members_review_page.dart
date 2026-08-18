import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../activity/presentation/bloc/activity_bloc.dart';
import '../../../activity/presentation/bloc/activity_event.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../home/presentation/bloc/home_bloc.dart';
import '../../../home/presentation/bloc/home_event.dart';
import '../../domain/entities/group_member_invite.dart';
import '../bloc/add_group_members_cubit.dart';
import 'group_member_invite_form_page.dart';

class AddGroupMembersReviewPage extends StatelessWidget {
  final String groupId;

  const AddGroupMembersReviewPage({
    super.key,
    required this.groupId,
  });

  Future<void> _addMembers(BuildContext context) async {
    final authState = context.read<AuthBloc>().state;
    final actorUserId = authState is Authenticated ? authState.user.id : '';
    if (actorUserId.isEmpty) return;

    final cubit = context.read<AddGroupMembersCubit>();
    final result = await cubit.resolveSelectedMemberIds(actorUserId);
    if (!context.mounted) return;

    if (result.isFailure) {
      AppToast.show(
        context,
        cubit.state.errorMessage ?? 'Could not add members.',
        type: ToastType.error,
      );
      return;
    }

    final memberIds = result.dataOrThrow;
    context.read<HomeBloc>().add(AddGroupMembersRequested(
          groupId: groupId,
          memberIds: memberIds,
          actorUserId: actorUserId,
        ));
    context.read<ActivityBloc>().add(const RefreshActivity());
    AppToast.show(
      context,
      memberIds.length == 1
          ? 'Member added to the group!'
          : '${memberIds.length} members added to the group!',
      type: ToastType.success,
    );
    context.pop(true);
  }

  Future<void> _editInvite(BuildContext context, GroupMemberInvite invite) async {
    final updated = await Navigator.of(context).push<GroupMemberInvite>(
      MaterialPageRoute(
        builder: (_) => GroupMemberInviteFormPage(
          title: 'Edit',
          initial: invite,
        ),
      ),
    );
    if (updated == null || !context.mounted) return;
    context.read<AddGroupMembersCubit>().upsertInvite(updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return BlocConsumer<AddGroupMembersCubit, AddGroupMembersState>(
      listenWhen: (previous, current) =>
          previous.selected.isNotEmpty && current.selected.isEmpty,
      listener: (context, state) {
        context.pop();
      },
      builder: (context, state) {
        final cubit = context.read<AddGroupMembersCubit>();

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: state.isSubmitting ? null : () => context.pop(),
            ),
            title: Text(
              'Review',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(
                  Icons.check,
                  color: state.isSubmitting
                      ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
                      : theme.colorScheme.onSurface,
                ),
                onPressed: state.isSubmitting ? null : () => _addMembers(context),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.only(top: 8.h, bottom: 24.h),
                  children: [
                    ...state.selected.map((invite) {
                      return ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 6.h,
                        ),
                        leading: _ReviewAvatar(
                          invite: invite,
                          onRemove: state.isSubmitting
                              ? null
                              : () => cubit.deselect(invite.key),
                        ),
                        title: Text(
                          invite.displayName,
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: invite.reviewSubtitle.isNotEmpty
                            ? Text(
                                invite.reviewSubtitle,
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.7),
                                ),
                              )
                            : null,
                        trailing: invite.isRegistered
                            ? null
                            : TextButton(
                                onPressed: state.isSubmitting
                                    ? null
                                    : () => _editInvite(context, invite),
                                child: Text(
                                  'Edit',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15.sp,
                                  ),
                                ),
                              ),
                      );
                    }),
                    Padding(
                      padding: EdgeInsets.fromLTRB(32.w, 24.h, 32.w, 0),
                      child: Text(
                        "These people will be notified you've added them to your group. You can start adding expenses right away.",
                        textAlign: TextAlign.center,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.7),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        minimumSize: Size(double.infinity, 48.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24.r),
                        ),
                        elevation: 0,
                      ),
                      onPressed: state.isSubmitting ? null : () => _addMembers(context),
                      child: state.isSubmitting
                          ? SizedBox(
                              width: 22.w,
                              height: 22.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: theme.colorScheme.onPrimary,
                              ),
                            )
                          : Text(
                              'Add members',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReviewAvatar extends StatelessWidget {
  final GroupMemberInvite invite;
  final VoidCallback? onRemove;

  const _ReviewAvatar({
    required this.invite,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _inviteAvatar(context, invite, radius: 24),
        Positioned(
          right: -4.w,
          top: -4.h,
          child: GestureDetector(
            onTap: onRemove,
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
    );
  }
}

Widget inviteLeadingAvatar(BuildContext context, GroupMemberInvite invite, {double radius = 22}) {
  return _inviteAvatar(context, invite, radius: radius);
}

Widget _inviteAvatar(BuildContext context, GroupMemberInvite invite, {required double radius}) {
  if (invite.isRegistered) {
    return AvatarWidget(
      name: invite.displayName,
      imageUrl: invite.photoUrl,
      size: radius.r * 2,
    );
  }

  return CircleAvatar(
    radius: radius.r,
    backgroundColor: context.colorScheme.surfaceContainerHighest,
    child: Icon(
      invite.phone != null ? Icons.outgoing_mail : Icons.email_outlined,
      color: context.colorScheme.onSurfaceVariant,
      size: (radius * 0.95).r,
    ),
  );
}
