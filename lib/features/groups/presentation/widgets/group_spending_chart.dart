import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/context_extension.dart';

/// All-time spending ring: the full circle is what the group spent, the darker
/// arc is the slice of it that is yours.
///
/// The circle is drawn straight away; only the share arc sweeps in from zero
/// once the data lands.
class GroupSpendingDonut extends StatefulWidget {
  final double totalSpent;
  final double yourShare;
  final String centerLabel;
  final String currencySymbol;

  const GroupSpendingDonut({
    super.key,
    required this.totalSpent,
    required this.yourShare,
    required this.centerLabel,
    required this.currencySymbol,
  });

  @override
  State<GroupSpendingDonut> createState() => _GroupSpendingDonutState();
}

class _GroupSpendingDonutState extends State<GroupSpendingDonut>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.chartReveal,
    );
    _progress = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant GroupSpendingDonut oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Switching currency or period is new data, so redraw it the same way.
    if (oldWidget.totalSpent != widget.totalSpent ||
        oldWidget.yourShare != widget.yourShare) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shareFraction = widget.totalSpent <= 0
        ? 0.0
        : (widget.yourShare / widget.totalSpent).clamp(0.0, 1.0).toDouble();

    return SizedBox(
      width: 220.w,
      height: 220.w,
      child: AnimatedBuilder(
        animation: _progress,
        builder: (context, child) {
          return CustomPaint(
            painter: _DonutPainter(
              shareProgress: _progress.value,
              shareFraction: shareFraction,
              hasSpending: widget.totalSpent > 0,
              trackColor: context.colorScheme.outlineVariant,
            ),
            child: child,
          );
        },
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.centerLabel,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: AppColors.chartTotalSpent,
                ),
              ),
              SizedBox(height: AppDimensions.xs.h),
              Text(
                '${widget.currencySymbol}'
                '${widget.totalSpent.toStringAsFixed(2)}',
                style: context.textTheme.titleLarge?.copyWith(
                  color: AppColors.chartTotalSpent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double shareProgress;
  final double shareFraction;
  final bool hasSpending;
  final Color trackColor;

  _DonutPainter({
    required this.shareProgress,
    required this.shareFraction,
    required this.hasSpending,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.13;
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: radius,
    );

    canvas.drawCircle(
      rect.center,
      radius,
      Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = hasSpending ? AppColors.chartTotalSpent : trackColor,
    );

    if (!hasSpending || shareFraction <= 0 || shareProgress <= 0) return;

    final share = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = AppColors.chartYourShare;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      shareProgress * shareFraction * 2 * math.pi,
      false,
      share,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.shareProgress != shareProgress ||
        oldDelegate.shareFraction != shareFraction ||
        oldDelegate.hasSpending != hasSpending ||
        oldDelegate.trackColor != trackColor;
  }
}

/// One bar per month. Bar height is the month's total spending relative to the
/// tallest month on screen; the darker foot of each bar is your share.
class GroupSpendingBar {
  final String label;
  final double totalSpent;
  final double yourShare;
  final bool isSelected;

  const GroupSpendingBar({
    required this.label,
    required this.totalSpent,
    required this.yourShare,
    required this.isSelected,
  });
}

class GroupSpendingBars extends StatelessWidget {
  final List<GroupSpendingBar> bars;
  final ValueChanged<int> onSelect;

  const GroupSpendingBars({
    super.key,
    required this.bars,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final maxTotal = bars.fold<double>(
      0,
      (highest, bar) => math.max(highest, bar.totalSpent),
    );

    return SizedBox(
      height: 220.h,
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _DashedGridPainter(
                          color: scheme.outlineVariant.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Row(
                        children: [
                          for (var index = 0; index < bars.length; index++)
                            Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => onSelect(index),
                                child: _buildBar(
                                  context,
                                  bars[index],
                                  maxTotal: maxTotal,
                                  maxHeight: constraints.maxHeight * 0.92,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Container(height: 1, color: scheme.outlineVariant),
          SizedBox(height: AppDimensions.sm.h),
          Row(
            children: [
              for (final bar in bars)
                Expanded(
                  child: Text(
                    bar.label,
                    textAlign: TextAlign.center,
                    style: context.textTheme.labelSmall?.copyWith(
                      fontWeight:
                          bar.isSelected ? FontWeight.bold : FontWeight.w500,
                      color: bar.isSelected
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBar(
    BuildContext context,
    GroupSpendingBar bar, {
    required double maxTotal,
    required double maxHeight,
  }) {
    final scheme = context.colorScheme;
    final fraction = maxTotal <= 0
        ? 0.0
        : (bar.totalSpent / maxTotal).clamp(0.0, 1.0).toDouble();
    // Months with nothing spent still get a stub so the axis reads as a
    // timeline rather than a gap.
    final height = math.max(3.h, maxHeight * fraction);
    final shareHeight = bar.totalSpent <= 0
        ? 0.0
        : height * (bar.yourShare / bar.totalSpent).clamp(0.0, 1.0).toDouble();
    final width = 26.w;
    final radius = BorderRadius.circular(width / 2);

    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: bar.totalSpent > 0
                      ? AppColors.chartTotalSpent
                      : scheme.outlineVariant,
                  borderRadius: radius,
                ),
              ),
            ),
            if (shareHeight > 0)
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: width,
                  height: shareHeight,
                  decoration: BoxDecoration(
                    color: AppColors.chartYourShare,
                    borderRadius: radius,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DashedGridPainter extends CustomPainter {
  final Color color;

  _DashedGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const lines = 4;
    const dash = 6.0;
    const gap = 6.0;

    for (var line = 0; line < lines; line++) {
      final y = size.height * (line / lines);
      var x = 0.0;
      while (x < size.width) {
        canvas.drawLine(
          Offset(x, y),
          Offset(math.min(x + dash, size.width), y),
          paint,
        );
        x += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedGridPainter oldDelegate) =>
      oldDelegate.color != color;
}
