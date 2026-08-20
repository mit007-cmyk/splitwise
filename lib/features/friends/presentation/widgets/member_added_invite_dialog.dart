import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/context_extension.dart';

/// Shown after adding someone who is not on the app yet.
class MemberAddedInviteDialog extends StatelessWidget {
  final String title;
  final String sendLabel;

  const MemberAddedInviteDialog({
    super.key,
    this.title = 'Your new group member has been added',
    this.sendLabel = 'Send text message',
  });

  static Future<bool> show(
    BuildContext context, {
    String title = 'Your new group member has been added',
    String sendLabel = 'Send text message',
  }) async {
    final sent = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => MemberAddedInviteDialog(
        title: title,
        sendLabel: sendLabel,
      ),
    );
    return sent == true;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return AlertDialog(
      backgroundColor: scheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg.r),
      ),
      title: Text(
        '🎉  $title',
        style: context.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(
        'Send a text message to let them know:',
        style: context.textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            sendLabel,
            style: TextStyle(
              color: scheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
