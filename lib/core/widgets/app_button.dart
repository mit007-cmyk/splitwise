import 'package:flutter/material.dart';
import '../utils/context_extension.dart';
import '../constants/app_constants.dart';
import 'loading_indicator.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  }) : isSecondary = false;

  const AppButton.secondary({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  }) : isSecondary = true;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    
    // Determine loading content or standard button contents
    final Widget labelWidget = isLoading
        ? AppLoadingIndicator(
            size: 20,
            color: isSecondary ? context.colorScheme.primary : Colors.white,
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(text),
            ],
          );

    final VoidCallback? activeCallback = isLoading ? null : onPressed;

    if (isSecondary) {
      return OutlinedButton(
        onPressed: activeCallback,
        style: theme.outlinedButtonTheme.style,
        child: Container(
          height: AppDimensions.buttonHeight,
          alignment: Alignment.center,
          child: labelWidget,
        ),
      );
    }

    return ElevatedButton(
      onPressed: activeCallback,
      style: theme.elevatedButtonTheme.style,
      child: Container(
        height: AppDimensions.buttonHeight,
        alignment: Alignment.center,
        child: labelWidget,
      ),
    );
  }
}
