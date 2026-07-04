import 'package:flutter/material.dart';
import '../utils/context_extension.dart';
import '../constants/app_constants.dart';
import 'app_button.dart';

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String description;
  final IconData? icon;
  final String? actionText;
  final VoidCallback? onAction;
  final String? secondaryActionText;
  final VoidCallback? onSecondaryAction;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.description,
    this.icon,
    this.actionText,
    this.onAction,
    this.secondaryActionText,
    this.onSecondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.inbox_outlined,
              size: 64,
              color: context.colorScheme.secondary.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            if ((actionText != null && onAction != null) || 
                (secondaryActionText != null && onSecondaryAction != null)) ...[
              const SizedBox(height: 24),
              Wrap(
                spacing: AppDimensions.md,
                runSpacing: AppDimensions.sm,
                alignment: WrapAlignment.center,
                children: [
                  if (actionText != null && onAction != null)
                    SizedBox(
                      width: 160,
                      child: AppButton(
                        text: actionText!,
                        onPressed: onAction,
                      ),
                    ),
                  if (secondaryActionText != null && onSecondaryAction != null)
                    SizedBox(
                      width: 160,
                      child: AppButton.secondary(
                        text: secondaryActionText!,
                        onPressed: onSecondaryAction,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
