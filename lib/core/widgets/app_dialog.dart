import 'package:flutter/material.dart';
import '../utils/context_extension.dart';
import '../constants/app_constants.dart';
import 'app_button.dart';

class AppDialog extends StatelessWidget {
  final String title;
  final String content;
  final List<Widget>? actions;

  const AppDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        title,
        style: context.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        content,
        style: context.textTheme.bodyMedium,
      ),
      actions: actions ??
          [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.translate('common_confirm')),
            ),
          ],
    );
  }

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required String content,
    List<Widget>? actions,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => AppDialog(
        title: title,
        content: content,
        actions: actions,
      ),
    );
  }
}

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String content;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    required this.onConfirm,
    this.onCancel,
    this.confirmText,
    this.cancelText,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        title,
        style: context.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        content,
        style: context.textTheme.bodyMedium,
      ),
      actionsPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.lg,
        vertical: AppDimensions.md,
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                  onCancel?.call();
                },
                child: Text(cancelText ?? context.translate('common_cancel')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                text: confirmText ?? context.translate('common_confirm'),
                onPressed: () {
                  Navigator.of(context).pop(true);
                  onConfirm();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String content,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    String? confirmText,
    String? cancelText,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        content: content,
        onConfirm: onConfirm,
        onCancel: onCancel,
        confirmText: confirmText,
        cancelText: cancelText,
      ),
    );
  }
}
