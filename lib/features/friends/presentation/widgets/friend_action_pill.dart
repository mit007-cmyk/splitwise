import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/utils/context_extension.dart';

class FriendActionPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  const FriendActionPill({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    // A pill without a tap handler is a disabled action, so dim it instead of
    // looking identical to the tappable ones.
    final isDisabled = onTap == null;
    final opacity = isDisabled ? 0.4 : 1.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(right: 8.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outline.withValues(alpha: opacity)),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16.r,
                color: scheme.secondary.withValues(alpha: opacity),
              ),
              SizedBox(width: 6.w),
            ],
            Text(
              label,
              style: context.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: opacity),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
