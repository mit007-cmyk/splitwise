import 'package:flutter/material.dart';
import '../utils/context_extension.dart';
import '../constants/app_constants.dart';
import 'app_button.dart';

class AppErrorWidget extends StatelessWidget {
  final String? title;
  final String message;
  final VoidCallback? onRetry;
  final IconData? icon;

  const AppErrorWidget({
    super.key,
    this.title,
    required this.message,
    this.onRetry,
    this.icon,
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
              icon ?? Icons.error_outline_rounded,
              size: 64,
              color: context.colorScheme.error,
            ),
            const SizedBox(height: 20),
            Text(
              title ?? context.translate('common_error'),
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: 150,
                child: AppButton(
                  text: context.translate('common_retry'),
                  onPressed: onRetry,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const NetworkErrorWidget({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return AppErrorWidget(
      icon: Icons.wifi_off_rounded,
      title: context.translate('network_error_title'),
      message: context.translate('network_error_msg'),
      onRetry: onRetry,
    );
  }
}
