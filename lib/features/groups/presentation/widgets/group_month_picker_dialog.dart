import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/context_extension.dart';
import '../../domain/services/group_spending_calculator.dart';

/// Calendar-style month picker: year chevrons, a 3×4 month grid, Cancel / OK.
class GroupMonthPickerDialog extends StatefulWidget {
  final DateTime selectedMonth;
  final DateTime? minMonth;
  final DateTime? maxMonth;

  const GroupMonthPickerDialog({
    super.key,
    required this.selectedMonth,
    this.minMonth,
    this.maxMonth,
  });

  static Future<DateTime?> show({
    required BuildContext context,
    required DateTime selectedMonth,
    DateTime? minMonth,
    DateTime? maxMonth,
  }) {
    return showDialog<DateTime>(
      context: context,
      barrierColor: context.colorScheme.scrim.withValues(alpha: 0.46),
      builder: (context) => GroupMonthPickerDialog(
        selectedMonth: GroupSpendingCalculator.monthOf(selectedMonth),
        minMonth: minMonth == null
            ? null
            : GroupSpendingCalculator.monthOf(minMonth),
        maxMonth: maxMonth == null
            ? null
            : GroupSpendingCalculator.monthOf(maxMonth),
      ),
    );
  }

  @override
  State<GroupMonthPickerDialog> createState() => _GroupMonthPickerDialogState();
}

class _GroupMonthPickerDialogState extends State<GroupMonthPickerDialog> {
  late int _year;
  late DateTime _pending;

  @override
  void initState() {
    super.initState();
    _pending = widget.selectedMonth;
    _year = widget.selectedMonth.year;
  }

  bool get _canGoBack =>
      widget.minMonth == null || _year > widget.minMonth!.year;

  bool get _canGoForward =>
      widget.maxMonth == null || _year < widget.maxMonth!.year;

  bool _isEnabled(int month) {
    final candidate = DateTime(_year, month);
    if (widget.minMonth != null && candidate.isBefore(widget.minMonth!)) {
      return false;
    }
    if (widget.maxMonth != null && candidate.isAfter(widget.maxMonth!)) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Dialog(
      backgroundColor: scheme.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.xxl,
        vertical: AppDimensions.xl,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
      ),
      child: SizedBox(
        width: 300,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.lg,
            AppDimensions.lg,
            AppDimensions.lg,
            AppDimensions.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildYearHeader(context),
              const SizedBox(height: AppDimensions.lg),
              Table(
                children: [
                  for (var row = 0; row < 4; row++)
                    TableRow(
                      children: [
                        for (var col = 0; col < 3; col++)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppDimensions.xs,
                            ),
                            child: SizedBox(
                              height: 48,
                              child: _buildMonthCell(row * 3 + col + 1),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: AppDimensions.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: scheme.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.md,
                        vertical: AppDimensions.sm,
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      context.translate('common_cancel'),
                      style: context.textTheme.labelLarge?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.xs),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: scheme.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.md,
                        vertical: AppDimensions.sm,
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(_pending),
                    child: Text(
                      'OK',
                      style: context.textTheme.labelLarge?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildYearHeader(BuildContext context) {
    final scheme = context.colorScheme;
    final chevronColor = scheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.sm),
      child: Row(
        children: [
          _YearChevron(
            icon: Icons.chevron_left,
            color: chevronColor,
            enabled: _canGoBack,
            onPressed: () => setState(() => _year--),
          ),
          Expanded(
            child: Text(
              '$_year',
              textAlign: TextAlign.center,
              style: context.textTheme.titleMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _YearChevron(
            icon: Icons.chevron_right,
            color: chevronColor,
            enabled: _canGoForward,
            onPressed: () => setState(() => _year++),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthCell(int month) {
    final scheme = context.colorScheme;
    final enabled = _isEnabled(month);
    final selected = _pending.year == _year && _pending.month == month;
    final label = DateFormat('MMM').format(DateTime(_year, month));
    final colors = context.appColors;

    final Color textColor;
    if (selected) {
      textColor = scheme.onPrimary;
    } else if (enabled) {
      textColor = scheme.onSurface;
    } else {
      textColor = colors.disabledTextColor;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        splashColor: scheme.primary.withValues(alpha: 0.16),
        highlightColor: scheme.primary.withValues(alpha: 0.08),
        onTap: enabled
            ? () => setState(() => _pending = DateTime(_year, month))
            : null,
        child: Center(
          child: AnimatedContainer(
            duration: AppDurations.animQuick,
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? scheme.primary : Colors.transparent,
            ),
            child: Text(
              label,
              style: context.textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _YearChevron extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onPressed;

  const _YearChevron({
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(AppDimensions.sm),
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      icon: Icon(icon, size: 24),
      color: color,
      disabledColor: color.withValues(alpha: 0.28),
      onPressed: enabled ? onPressed : null,
    );
  }
}
