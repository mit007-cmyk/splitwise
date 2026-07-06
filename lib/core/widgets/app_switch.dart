import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../utils/context_extension.dart';

/// Splitwise-style toggle matching Security settings:
/// ON  → muted dark-teal track + bright mint thumb
/// OFF → gray track + flat white thumb (no shadow)
class AppSwitch extends StatelessWidget {
  static const double _width = 51;
  static const double _height = 31;
  static const double _thumbSize = 27;
  static const double _padding = 2;

  // Dark theme — matches Security screen reference
  static const Color _onTrackDark = Color(0xFF2A4F47);
  static const Color _onThumbDark = Color(0xFF1CC29F);
  static const Color _offTrackDark = Color(0xFF48484A);
  static const Color _offThumbDark = Color(0xFFFFFFFF);

  // Light theme
  static const Color _onTrackLight = Color(0xFFB8E6D5);
  static const Color _offTrackLight = Color(0xFFE9E9EA);

  final bool value;
  final ValueChanged<bool>? onChanged;

  const AppSwitch({
    super.key,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.theme.brightness == Brightness.dark;

    final Color trackColor;
    final Color thumbColor;

    if (value) {
      trackColor = isDark ? _onTrackDark : _onTrackLight;
      thumbColor = isDark ? _onThumbDark : AppColors.primaryLight;
    } else {
      trackColor = isDark ? _offTrackDark : _offTrackLight;
      thumbColor = isDark ? _offThumbDark : Colors.white;
    }

    return Semantics(
      toggled: value,
      enabled: onChanged != null,
      button: true,
      label: 'Toggle',
      child: GestureDetector(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppDurations.animQuick,
          curve: Curves.easeInOut,
          width: _width,
          height: _height,
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(AppDimensions.radiusCircular),
          ),
          child: AnimatedAlign(
            duration: AppDurations.animQuick,
            curve: Curves.easeInOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: _thumbSize,
              height: _thumbSize,
              margin: const EdgeInsets.all(_padding),
              decoration: BoxDecoration(
                color: thumbColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
