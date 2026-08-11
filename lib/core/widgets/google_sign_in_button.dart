import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../utils/context_extension.dart';
import 'spacing.dart';

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const GoogleSignInButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.theme.brightness == Brightness.dark;
    // bool.fromEnvironment works on all platforms including web (unlike dart:io Platform)
    const isUnderTest = bool.fromEnvironment('FLUTTER_TEST');
    final colors = context.appColors;
    final scheme = context.colorScheme;

    final Color buttonBg = colors.glassSurface.withValues(
      alpha: isDark ? 0.06 : 0.5,
    );

    final BorderSide borderSide = BorderSide(
      color: colors.overlayColor.withValues(alpha: 0.12),
      width: 1.0,
    );

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: buttonBg,
          foregroundColor: scheme.onSurface,
          side: borderSide,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.lg,
            vertical: AppDimensions.md,
          ),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? colors.onImageColor.withValues(alpha: 0.7) : scheme.onSurface.withValues(alpha: 0.54),
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  isUnderTest
                      ? const Icon(Icons.g_mobiledata, size: 24)
                      : Image.asset(
                          'assets/images/google-logo.png',
                          width: 20,
                          height: 20,
                        ),
                  Spacing.horizontal(AppDimensions.md),
                  Text(
                    'Sign in with Google',
                    style: context.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
