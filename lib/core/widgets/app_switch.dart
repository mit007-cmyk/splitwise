import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../utils/context_extension.dart';

/// Splitwise-style toggle matching Security settings:
/// ON  → muted dark-teal track + bright mint thumb
/// OFF → gray track + flat white thumb (no shadow)
class AppSwitch extends StatelessWidget {
  static const double _width = 51;
  static const double _height = 31;
  static const double _thumbSize = 27;
  static const double _padding = 2;

  final bool value;
  final ValueChanged<bool>? onChanged;

  const AppSwitch({
    super.key,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final Color trackColor;
    final Color thumbColor;

    if (value) {
      trackColor = colors.switchOnTrack;
      thumbColor = colors.switchOnThumb;
    } else {
      trackColor = colors.switchOffTrack;
      thumbColor = colors.switchOffThumb;
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
