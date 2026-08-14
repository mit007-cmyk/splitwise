import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/di.dart';
import '../../../../core/routing/route_constants.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../../core/services/support_email_service.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../activity/presentation/bloc/activity_bloc.dart';
import '../../../activity/presentation/bloc/activity_event.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../home/domain/entities/group_summary.dart';
import '../../../home/domain/repositories/home_repository.dart';
import '../../../home/presentation/bloc/home_bloc.dart';
import '../../../home/presentation/bloc/home_event.dart';
import '../../domain/entities/user_preview.dart';
import '../../domain/repositories/friends_repository.dart';
import '../bloc/friends_list_cubit.dart';

class FriendSettingsPage extends StatefulWidget {
  final String friendId;

  const FriendSettingsPage({
    super.key,
    required this.friendId,
  });

  @override
  State<FriendSettingsPage> createState() => _FriendSettingsPageState();
}

class _FriendSettingsPageState extends State<FriendSettingsPage> {
  UserPreview? _friend;
  List<GroupSummary> _sharedGroups = [];
  bool _isLoading = true;
  bool _isRemoving = false;
  bool _isBlocking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  String? get _currentUserId {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) return authState.user.id;
    return null;
  }

  Future<void> _load() async {
    final friendResult =
        await getIt<FriendsRepository>().getUserById(widget.friendId);

    List<GroupSummary> sharedGroups = [];
    final currentUserId = _currentUserId;
    if (currentUserId != null) {
      final groupsResult =
          await getIt<HomeRepository>().getGroups(userId: currentUserId);
      if (groupsResult.isSuccess) {
        sharedGroups = groupsResult.dataOrThrow
            .where((group) => group.memberIds.contains(widget.friendId))
            .toList();
      }
    }

    if (!mounted) return;
    setState(() {
      _friend = friendResult.isSuccess ? friendResult.dataOrThrow : null;
      _sharedGroups = sharedGroups;
      _isLoading = false;
    });
  }

  Future<void> _confirmBlockUser() async {
    final friend = _friend;
    final currentUserId = _currentUserId;
    if (friend == null || currentUserId == null || _isBlocking) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Block user'),
        content: Text(
          'Block ${friend.name}? They will be removed from your friends list, '
          'groups you share will be hidden, and you will not get activity from them. '
          'They will not be notified. Expense history is kept.\n\n'
          'You can unblock them later from Account settings → Manage your blocklist.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('Block'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isBlocking = true);
    final result = await getIt<FriendsRepository>().blockUser(
      currentUserId: currentUserId,
      blockedUserId: friend.id,
    );
    if (!mounted) return;

    if (result.isFailure) {
      setState(() => _isBlocking = false);
      AppToast.show(context, 'Could not block user.', type: ToastType.error);
      return;
    }

    AppToast.show(
      context,
      '${friend.name} has been blocked.',
      type: ToastType.success,
    );
    context.read<HomeBloc>().add(const RefreshHome());
    context.read<ActivityBloc>().add(const RefreshActivity());
    getIt<FriendsListCubit>().load(currentUserId);
    context.pop();
    context.pop();
  }

  Future<void> _reportUser() async {
    final friend = _friend;
    final authState = context.read<AuthBloc>().state;
    if (friend == null || authState is! Authenticated) return;

    try {
      await getIt<SupportEmailService>().composeAbuseReport(
        reporterEmail: authState.user.email,
        reporterUserId: authState.user.id,
        reportedUserId: friend.id,
        reportedUserName: friend.name,
      );
    } catch (_) {
      if (!mounted) return;
      AppToast.show(
        context,
        'Could not open email. Write to ${AppConstants.abuseEmail}.',
        type: ToastType.error,
      );
    }
  }

  void _showSharedGroupsBlockedDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('You have shared groups'),
        content: const Text(
          'If you wish to delete this person from your friends list, you '
          'will need to delete them (or yourself) from your groups, or '
          'remove the groups entirely.\n\n'
          'You can access these settings by tapping on a group on this screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _openGroupSettings(String groupId) async {
    await context.pushNamed(
      RouteConstants.groupSettingsName,
      pathParameters: {'groupId': groupId},
    );
    if (mounted) {
      _load();
    }
  }

  Future<void> _confirmRemoveFriend() async {
    final friend = _friend;
    final currentUserId = _currentUserId;
    if (friend == null || currentUserId == null) return;

    if (_sharedGroups.isNotEmpty) {
      _showSharedGroupsBlockedDialog();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove friend'),
        content: Text(
          'Remove ${friend.name} from your friends list? '
          'You can add them again later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isRemoving = true);

    final result = await getIt<FriendsRepository>().removeFriend(
      currentUserId: currentUserId,
      friendUserId: friend.id,
    );

    if (!mounted) return;

    if (result.isFailure) {
      setState(() => _isRemoving = false);
      AppToast.show(context, 'Could not remove friend.', type: ToastType.error);
      return;
    }

    // Pop settings page and friend detail page, back to the friends list.
    context.pop();
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Friend settings',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _friend == null
              ? Center(
                  child: Text(
                    'Friend not found',
                    style: context.textTheme.bodyMedium,
                  ),
                )
              : _buildBody(context, _friend!),
    );
  }

  Widget _buildBody(BuildContext context, UserPreview friend) {
    final scheme = context.colorScheme;

    return AbsorbPointer(
      absorbing: _isRemoving || _isBlocking,
      child: Opacity(
        opacity: (_isRemoving || _isBlocking) ? 0.6 : 1,
        child: ListView(
          padding: EdgeInsets.symmetric(vertical: AppDimensions.lg.h),
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppDimensions.lg.w),
              child: Row(
                children: [
                  AvatarWidget(
                    name: friend.name,
                    imageUrl: friend.photoUrl,
                    size: 56.w,
                  ),
                  SizedBox(width: AppDimensions.md.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          friend.name,
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if ((friend.email ?? '').isNotEmpty) ...[
                          SizedBox(height: 2.h),
                          Text(
                            friend.email!,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppDimensions.xl.h),
            _SectionHeader(title: 'Shared groups'),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppDimensions.lg.w),
              child: _sharedGroups.isEmpty
                  ? Text(
                      'You and ${friend.name} do not share any groups.',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _sharedGroups
                          .map(
                            (group) => InkWell(
                              onTap: () => _openGroupSettings(group.groupId),
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 4.h),
                                child: Text(
                                  group.groupName,
                                  style: context.textTheme.bodyMedium?.copyWith(
                                    color: scheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
            SizedBox(height: AppDimensions.xl.h),
            _SectionHeader(title: 'Manage relationship'),
            _SettingsActionTile(
              icon: Icons.person_remove_alt_1_outlined,
              iconColor: scheme.error,
              title: 'Remove from friends list',
              titleColor: scheme.error,
              subtitle: 'Remove this user from your friends list.',
              onTap: _confirmRemoveFriend,
            ),
            _SettingsActionTile(
              icon: Icons.block_outlined,
              title: 'Block user',
              subtitle:
                  'Remove this user from your friends list, hide any groups you share, and suppress future expenses/notifications from them.',
              onTap: _confirmBlockUser,
            ),
            _SettingsActionTile(
              icon: Icons.report_gmailerrorred_outlined,
              title: 'Report user',
              subtitle: 'Flag an abusive, suspicious, or spam account.',
              onTap: _reportUser,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.lg.w,
        0,
        AppDimensions.lg.w,
        AppDimensions.sm.h,
      ),
      child: Text(
        title,
        style: context.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final Color? titleColor;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.lg.w,
          vertical: AppDimensions.md.h,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor ?? scheme.onSurface, size: 22.r),
            SizedBox(width: AppDimensions.md.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.textTheme.bodyLarge?.copyWith(
                      color: titleColor ?? scheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
