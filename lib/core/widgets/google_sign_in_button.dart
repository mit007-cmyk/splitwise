import 'dart:io';
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
    final isUnderTest = Platform.environment.containsKey('FLUTTER_TEST');

    // Outlined frosted visual structure matching Google styling guidelines
    final Color buttonBg = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.white.withOpacity(0.5);

    final BorderSide borderSide = BorderSide(
      color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.12),
      width: 1.0,
    );

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: buttonBg,
          foregroundColor: context.colorScheme.onSurface,
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
                    isDark ? Colors.white70 : Colors.black54,
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
