import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/di.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../domain/repositories/friends_repository.dart';
import '../../domain/services/friend_reminder_message.dart';

/// "How do you want to remind X?" sheet from the friend detail screen.
///
/// In-app delivery needs a Splitwise-side messaging channel we don't have, so
/// that row stays disabled and the reminder goes out through the platform
/// share sheet instead.
class FriendReminderSheet extends StatefulWidget {
  final String friendName;
  final int outstandingBalanceCount;
  final String currentUserId;
  final String currentUserName;
  final String? currentUserPhotoUrl;

  const FriendReminderSheet({
    super.key,
    required this.friendName,
    required this.outstandingBalanceCount,
    required this.currentUserId,
    required this.currentUserName,
    this.currentUserPhotoUrl,
  });

  static Future<void> show(
    BuildContext context, {
    required String friendName,
    required int outstandingBalanceCount,
    required String currentUserId,
    required String currentUserName,
    String? currentUserPhotoUrl,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: context.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl.r),
        ),
      ),
      builder: (_) => FriendReminderSheet(
        friendName: friendName,
        outstandingBalanceCount: outstandingBalanceCount,
        currentUserId: currentUserId,
        currentUserName: currentUserName,
        currentUserPhotoUrl: currentUserPhotoUrl,
      ),
    );
  }

  @override
  State<FriendReminderSheet> createState() => _FriendReminderSheetState();
}

class _FriendReminderSheetState extends State<FriendReminderSheet> {
  String? _inviteUrl;
  bool _isPreparing = false;

  @override
  void initState() {
    super.initState();
    _prefetchInviteUrl();
  }

  Future<void> _prefetchInviteUrl() async {
    final url = await _fetchInviteUrl();
    if (!mounted || url == null) return;
    setState(() => _inviteUrl = url);
  }

  /// The reminder links back to the sender's own friend code so the recipient
  /// lands on the shared activity after following it.
  Future<String?> _fetchInviteUrl() async {
    final result = await getIt<FriendsRepository>().getMyFriendCode(
      userId: widget.currentUserId,
      userName: widget.currentUserName,
      photoUrl: widget.currentUserPhotoUrl,
    );
    return result.isSuccess ? result.dataOrThrow.inviteUrl : null;
  }

  Future<void> _shareReminder() async {
    if (_isPreparing) return;

    var url = _inviteUrl;
    if (url == null) {
      setState(() => _isPreparing = true);
      url = await _fetchInviteUrl();
      if (!mounted) return;
      setState(() {
        _inviteUrl = url;
        _isPreparing = false;
      });
    }

    if (url == null) {
      AppToast.show(
        context,
        'Could not prepare the reminder link. Please try again.',
        type: ToastType.error,
      );
      return;
    }

    final message = FriendReminderMessage.build(
      friendName: widget.friendName,
      outstandingBalanceCount: widget.outstandingBalanceCount,
      inviteUrl: url,
    );

    Navigator.of(context).pop();
    await Share.share(message, subject: 'Splitwise reminder');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppDimensions.lg.w,
          AppDimensions.xl.h,
          AppDimensions.lg.w,
          AppDimensions.lg.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppDimensions.sm.w),
              child: Text(
                'How do you want to remind '
                '${FriendReminderMessage.firstNameOf(widget.friendName)}?',
                style: context.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
            ),
            SizedBox(height: AppDimensions.xl.h),
            _buildOption(
              context,
              icon: Icons.shortcut,
              label: 'Send via Splitwise',
              subtitle: 'Unavailable for this recipient.',
            ),
            _buildOption(
              context,
              icon: Icons.share,
              label: 'More share options',
              isBusy: _isPreparing,
              onTap: _shareReminder,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? subtitle,
    bool isBusy = false,
    VoidCallback? onTap,
  }) {
    final scheme = context.colorScheme;
    final opacity = onTap == null ? 0.4 : 1.0;

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: AppDimensions.sm.w),
      leading: isBusy
          ? SizedBox(
              width: 24.r,
              height: 24.r,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              icon,
              size: 24.r,
              color: scheme.onSurfaceVariant.withValues(alpha: opacity),
            ),
      title: Text(
        label,
        style: context.textTheme.titleMedium?.copyWith(
          color: scheme.onSurface.withValues(alpha: opacity),
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Padding(
              padding: EdgeInsets.only(top: AppDimensions.xs.h),
              child: Text(
                subtitle,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: opacity),
                ),
              ),
            ),
      onTap: onTap,
    );
  }
}
