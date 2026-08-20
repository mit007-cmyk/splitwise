import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../expenses/presentation/widgets/category_picker_sheet.dart';
import '../../domain/services/group_spending_calculator.dart';

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
    final hasSpending = bar.totalSpent > 0;
    // Empty months sit on the axis as a squat pill, not a hairline.
    final height = math.max(8.h, maxHeight * fraction);
    final shareFraction = hasSpending
        ? (bar.yourShare / bar.totalSpent).clamp(0.0, 1.0).toDouble()
        : 0.0;
    final width = 28.w;

    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: _StackedCapsulePainter(
            shareFraction: shareFraction,
            hasSpending: hasSpending,
            gap: 5,
            totalColor: AppColors.chartTotalSpent,
            shareColor: AppColors.chartYourShare,
            emptyColor: scheme.outlineVariant,
          ),
        ),
      ),
    );
  }
}

/// Lighter remainder of the group total sits on top with a round peak; its
/// base is cut in a frown that follows the darker share pill, leaving a curved
/// gap of chart background — Splitwise Totals, not two facing capsules.
class _StackedCapsulePainter extends CustomPainter {
  final double shareFraction;
  final bool hasSpending;
  final double gap;
  final Color totalColor;
  final Color shareColor;
  final Color emptyColor;

  _StackedCapsulePainter({
    required this.shareFraction,
    required this.hasSpending,
    required this.gap,
    required this.totalColor,
    required this.shareColor,
    required this.emptyColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final corner = math.min(8.0, w / 2);
    final cap = Radius.circular(corner);
    final totalPaint = Paint()
      ..isAntiAlias = true
      ..color = totalColor;
    final sharePaint = Paint()
      ..isAntiAlias = true
      ..color = shareColor;
    final emptyPaint = Paint()
      ..isAntiAlias = true
      ..color = emptyColor;

    if (!hasSpending) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Offset.zero & size, cap),
        emptyPaint,
      );
      return;
    }

    final shareHeight = size.height * shareFraction;
    final remainderHeight = size.height - shareHeight;
    final split = shareHeight > 0.5 && remainderHeight > 0.5 && shareFraction < 1;

    if (!split) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Offset.zero & size, cap),
        shareHeight > remainderHeight ? sharePaint : totalPaint,
      );
      return;
    }

    final shareTop = size.height - shareHeight;
    final shareRect = Rect.fromLTWH(0, shareTop, w, shareHeight);

    var remainder = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(0, 0, w, shareTop),
          topLeft: cap,
          topRight: cap,
        ),
      );
    final cut = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          shareRect.inflate(gap),
          Radius.circular(corner + gap),
        ),
      );
    remainder = Path.combine(PathOperation.difference, remainder, cut);
    canvas.drawPath(remainder, totalPaint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(shareRect, cap),
      sharePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _StackedCapsulePainter oldDelegate) {
    return oldDelegate.shareFraction != shareFraction ||
        oldDelegate.hasSpending != hasSpending ||
        oldDelegate.gap != gap ||
        oldDelegate.totalColor != totalColor ||
        oldDelegate.shareColor != shareColor ||
        oldDelegate.emptyColor != emptyColor;
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

/// Line chart of group spending: months for all time, days when a month is
/// selected.
class GroupSpendingTrendChart extends StatelessWidget {
  final List<SpendPoint> points;
  final String currencySymbol;
  final bool daily;

  const GroupSpendingTrendChart({
    super.key,
    required this.points,
    required this.currencySymbol,
    this.daily = false,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    final scheme = context.colorScheme;
    final maxAmount = points.fold<double>(
      0,
      (highest, point) => math.max(highest, point.amount),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Spending over time',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: AppDimensions.lg.h),
        SizedBox(
          height: 180.h,
          child: Column(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 44.w,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$currencySymbol${_axisAmount(maxAmount)}',
                            style: context.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '$currencySymbol${_axisAmount(maxAmount / 2)}',
                            style: context.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '${currencySymbol}0',
                            style: context.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: AppDimensions.sm.w),
                    Expanded(
                      child: CustomPaint(
                        painter: _TrendLinePainter(
                          amounts: [for (final point in points) point.amount],
                          maxAmount: maxAmount,
                          lineColor: AppColors.chartTotalSpent,
                          axisColor: scheme.outlineVariant,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 44.w + AppDimensions.sm.w),
                child: Container(height: 1, color: scheme.outlineVariant),
              ),
              SizedBox(height: AppDimensions.sm.h),
              Padding(
                padding: EdgeInsets.only(left: 44.w + AppDimensions.sm.w),
                child: daily
                    ? _buildDailyLabels(context)
                    : _buildMonthLabels(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _axisAmount(double value) {
    if (value <= 0) return '0';
    if (value >= 1000) {
      final thousands = value / 1000;
      return thousands.truncateToDouble() == thousands
          ? '${thousands.toStringAsFixed(0)}k'
          : '${thousands.toStringAsFixed(1)}k';
    }
    return value.round().toString();
  }

  Widget _buildMonthLabels(BuildContext context) {
    return Row(
      children: [
        for (final point in points)
          Expanded(
            child: Text(
              DateFormat('MMM').format(point.date),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelSmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDailyLabels(BuildContext context) {
    final lastDay = points.last.date.day;
    final ticks = GroupSpendingCalculator.monthAxisDays(lastDay).toSet();
    final style = context.textTheme.labelSmall?.copyWith(
      color: context.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
    );

    return SizedBox(
      height: 16.h,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final n = points.length;
          const labelWidth = 48.0;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < n; i++)
                if (ticks.contains(points[i].date.day))
                  Positioned(
                    left: _labelLeft(i, n, width, labelWidth),
                    width: labelWidth,
                    child: Text(
                      DateFormat('MMM d').format(points[i].date),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: style,
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }

  static double _labelLeft(int index, int count, double width, double labelWidth) {
    final x = count == 1 ? width / 2 : width * (index / (count - 1));
    return (x - labelWidth / 2).clamp(0.0, width - labelWidth);
  }
}

class _TrendLinePainter extends CustomPainter {
  final List<double> amounts;
  final double maxAmount;
  final Color lineColor;
  final Color axisColor;

  _TrendLinePainter({
    required this.amounts,
    required this.maxAmount,
    required this.lineColor,
    required this.axisColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (amounts.isEmpty) return;

    final axis = Paint()
      ..color = axisColor
      ..strokeWidth = 1;
    canvas.drawLine(Offset.zero, Offset(0, size.height), axis);

    final n = amounts.length;
    final maxY = maxAmount <= 0 ? 1.0 : maxAmount;
    Offset pointAt(int index) {
      final x = n == 1 ? size.width / 2 : size.width * (index / (n - 1));
      final y = size.height - (amounts[index] / maxY) * size.height * 0.92;
      return Offset(x, y);
    }

    final line = Paint()
      ..isAntiAlias = true
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (n == 1) {
      final y = pointAt(0).dy;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
      return;
    }

    final path = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (var i = 1; i < n; i++) {
      path.lineTo(pointAt(i).dx, pointAt(i).dy);
    }
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _TrendLinePainter oldDelegate) {
    return oldDelegate.amounts != amounts ||
        oldDelegate.maxAmount != maxAmount ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.axisColor != axisColor;
  }
}

/// Category pie plus a named list of amounts.
class GroupCategoryBreakdown extends StatelessWidget {
  final List<CategorySpend> categories;
  final String currencySymbol;
  final ValueChanged<CategorySpend>? onCategoryTap;

  const GroupCategoryBreakdown({
    super.key,
    required this.categories,
    required this.currencySymbol,
    this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    final scheme = context.colorScheme;
    final total = categories.fold<double>(0, (sum, row) => sum + row.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Spending by category',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: AppDimensions.lg.h),
        Center(
          child: SizedBox(
            width: 180.w,
            height: 180.w,
            child: CustomPaint(
              painter: _CategoryPiePainter(
                fractions: [
                  for (final row in categories)
                    total <= 0 ? 0.0 : row.amount / total,
                ],
                colors: [
                  for (var i = 0; i < categories.length; i++)
                    AppColors.chartCategories[i % AppColors.chartCategories.length],
                ],
                emptyColor: scheme.outlineVariant,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        SizedBox(height: AppDimensions.xl.h),
        for (var i = 0; i < categories.length; i++) ...[
          if (i > 0) SizedBox(height: AppDimensions.md.h),
          _CategoryRow(
            category: categories[i].category,
            iconKey: categories[i].categoryIcon,
            amount:
                '$currencySymbol${categories[i].amount.toStringAsFixed(2)}',
            color: AppColors.chartCategories[i % AppColors.chartCategories.length],
            onTap: onCategoryTap == null
                ? null
                : () => onCategoryTap!(categories[i]),
          ),
        ],
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String category;
  final String? iconKey;
  final String amount;
  final Color color;
  final VoidCallback? onTap;

  const _CategoryRow({
    required this.category,
    this.iconKey,
    required this.amount,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        Container(
          width: 10.w,
          height: 10.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: AppDimensions.sm.w),
        Icon(
          ExpenseCategory.iconFor(category, iconKey: iconKey),
          size: 18.r,
          color: context.colorScheme.onSurfaceVariant,
        ),
        SizedBox(width: AppDimensions.sm.w),
        Expanded(
          child: Text(
            category,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          amount,
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusSm.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppDimensions.xs.h),
        child: row,
      ),
    );
  }
}

class _CategoryPiePainter extends CustomPainter {
  final List<double> fractions;
  final List<Color> colors;
  final Color emptyColor;

  _CategoryPiePainter({
    required this.fractions,
    required this.colors,
    required this.emptyColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: radius,
    );

    final total = fractions.fold<double>(0, (sum, value) => sum + value);
    if (total <= 0) {
      canvas.drawCircle(rect.center, radius, Paint()..color = emptyColor);
      return;
    }

    var start = -math.pi / 2;
    for (var i = 0; i < fractions.length; i++) {
      final sweep = fractions[i] * 2 * math.pi;
      if (sweep <= 0) continue;
      canvas.drawArc(
        rect,
        start,
        sweep,
        true,
        Paint()
          ..isAntiAlias = true
          ..style = PaintingStyle.fill
          ..color = colors[i],
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _CategoryPiePainter oldDelegate) {
    return oldDelegate.fractions != fractions ||
        oldDelegate.colors != colors ||
        oldDelegate.emptyColor != emptyColor;
  }
}
