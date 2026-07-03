import 'package:flutter/material.dart';
import '../utils/context_extension.dart';

class GlassBackground extends StatelessWidget {
  final Widget child;

  const GlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = context.theme.brightness == Brightness.dark;

    // Soft bleeding colors
    final primaryGlow = context.colorScheme.primary.withOpacity(isDark ? 0.15 : 0.22);
    final accentGlow = Colors.indigo.shade400.withOpacity(isDark ? 0.12 : 0.18);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Solid background base
          Positioned.fill(
            child: Container(
              color: context.colorScheme.surface,
            ),
          ),
          
          // 2. Top-Right primary mesh glow spot
          Positioned(
            top: -100,
            right: -100,
            width: 320,
            height: 320,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primaryGlow,
                    primaryGlow.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          // 3. Bottom-Left accent mesh glow spot
          Positioned(
            bottom: -80,
            left: -80,
            width: 360,
            height: 360,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accentGlow,
                    accentGlow.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          // 4. Center-Right secondary mesh glow spot (helps light mode feel dynamic)
          Positioned(
            top: context.screenHeight * 0.35,
            right: -150,
            width: 300,
            height: 300,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accentGlow.withOpacity(0.7),
                    accentGlow.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          // 5. App Page content overlay
          Positioned.fill(
            child: child,
          ),
        ],
      ),
    );
  }
}
