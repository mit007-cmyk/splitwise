import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/context_extension.dart';
import '../constants/app_constants.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = AppDimensions.radiusLg,
    this.padding = const EdgeInsets.all(AppDimensions.lg),
    this.margin,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.theme.brightness == Brightness.dark;

    // Glass properties depending on light/dark theme
    final Color glassColor = isDark
        ? const Color(0xFF1E293B).withOpacity(0.4)
        : Colors.white.withOpacity(0.25);

    final Border glassBorder = isDark
        ? Border.all(color: Colors.white.withOpacity(0.12), width: 1.0)
        : Border.all(color: Colors.white.withOpacity(0.45), width: 1.0);

    final BoxShadow glassShadow = BoxShadow(
      color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
      blurRadius: 24,
      spreadRadius: -4,
      offset: const Offset(0, 8),
    );

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [glassShadow],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: glassColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: glassBorder,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
