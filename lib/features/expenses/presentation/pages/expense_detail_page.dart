import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/di.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../expenses/domain/repositories/expense_repository.dart';
import 'add_expense_page.dart';

/// Full-screen expense detail page.
///
/// Displays the expense amount, payer/split breakdown, a simple monthly
/// spending-trend bar chart, and provides edit/delete actions.
class ExpenseDetailPage extends StatefulWidget {
  final Expense expense;

  /// Maps userId → display name for every participant.
  final Map<String, String> memberNames;

  /// The current user's id, used to compute "You" labels.
  final String currentUserId;

  /// The group name for this expense, used in charts title.
  final String? groupName;

  const ExpenseDetailPage({
    super.key,
    required this.expense,
    required this.memberNames,
    required this.currentUserId,
    this.groupName,
  });

  @override
  State<ExpenseDetailPage> createState() => _ExpenseDetailPageState();
}

class _ExpenseDetailPageState extends State<ExpenseDetailPage> {
  final ExpenseRepository _expenseRepository = getIt<ExpenseRepository>();
  final TextEditingController _commentController = TextEditingController();
  final ValueNotifier<bool> _isDeleting = ValueNotifier(false);

  @override
  void dispose() {
    _commentController.dispose();
    _isDeleting.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _displayName(String userId) {
    if (userId == widget.currentUserId) return 'You';
    return widget.memberNames[userId] ?? 'Unknown';
  }

  /// Primary payer name + amount string, e.g. "You paid ₹210.00"
  String get _payerLine {
    final e = widget.expense;
    if (e.paidBy.isEmpty) return '';
    final topPayerId =
        e.paidBy.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    final topAmount = e.paidBy[topPayerId]!;
    final name = _displayName(topPayerId);
    return '$name paid ${e.currencySymbol}${topAmount.toStringAsFixed(2)}';
  }

  /// Per-user share lines, e.g. ["You owe ₹105.00", "Vishal B. owes ₹105.00"]
  List<String> get _splitLines {
    final e = widget.expense;
    return e.splits.entries.map((entry) {
      final name = _displayName(entry.key);
      final owes = entry.value;
      return '$name owes ${e.currencySymbol}${owes.toStringAsFixed(2)}';
    }).toList();
  }

  Color _heroColor(String name) => AppColors
      .avatarPlaceholders[name.length % AppColors.avatarPlaceholders.length];

  // ── Delete ─────────────────────────────────────────────────────────────────

  Future<void> _confirmDelete() async {
    if (widget.expense.createdBy != widget.currentUserId) {
      AppToast.show(context, 'Only the creator can delete this expense.', type: ToastType.warning);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete expense?'),
        content: const Text(
          'This will permanently delete the expense for all members. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _isDeleting.value = true;
    final Result<void> result = await _expenseRepository.deleteExpense(
      expenseId: widget.expense.id,
      actorUserId: widget.currentUserId,
    );
    if (!mounted) return;
    _isDeleting.value = false;
    if (result.isSuccess) {
      AppToast.show(context, 'Expense deleted', type: ToastType.success);
      Navigator.of(context).pop(true);
    } else {
      AppToast.show(context, 'Could not delete expense. Try again.', type: ToastType.error);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final e = widget.expense;
    final heroColor = _heroColor(e.category);
    final dateStr =
        'Added by ${_displayName(e.createdBy)} on ${DateFormat('dd-MMM-yyyy').format(e.date)}';

    return Scaffold(
      backgroundColor: scheme.surface,
      // ── AppBar ──────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        actions: [
          // Receipt / attachment placeholder
          IconButton(
            icon: const Icon(Icons.receipt_outlined),
            tooltip: 'Attach receipt',
            onPressed: () {
              AppToast.show(context, 'Receipt attachment coming soon', type: ToastType.info);
            },
          ),
          // Delete
          ValueListenableBuilder<bool>(
            valueListenable: _isDeleting,
            builder: (context, deleting, child) => IconButton(
              icon: deleting
                  ? SizedBox(
                      width: 20.r,
                      height: 20.r,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.error,
                      ),
                    )
                  : const Icon(Icons.delete_outline),
              tooltip: 'Delete expense',
              color: scheme.error,
              onPressed: deleting || widget.expense.createdBy != widget.currentUserId
                  ? null
                  : _confirmDelete,
            ),
          ),
          // Edit
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit expense',
            onPressed: () async {
              if (widget.expense.createdBy != widget.currentUserId) {
                AppToast.show(context, 'Only the creator can edit this expense.', type: ToastType.warning);
                return;
              }
              final changed = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => AddExpensePage(existingExpense: widget.expense),
                ),
              );
              if (changed == true && context.mounted) {
                Navigator.of(context).pop(true);
              }
            },
          ),
        ],
      ),

      // ── Body ─────────────────────────────────────────────────────────────
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Hero section ─────────────────────────────────────────
                  _HeroSection(
                    expense: e,
                    heroColor: heroColor,
                    dateStr: dateStr,
                  ),

                  SizedBox(height: AppDimensions.lg.h),

                  // ── Payer / split breakdown ──────────────────────────────
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PayerRow(
                          payerLine: _payerLine,
                          photoUrl: null,
                          payerId: e.paidBy.isNotEmpty
                              ? e.paidBy.entries
                                  .reduce(
                                      (a, b) => a.value >= b.value ? a : b)
                                  .key
                              : '',
                          currentUserId: widget.currentUserId,
                          memberNames: widget.memberNames,
                        ),
                        ..._splitLines.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final line = entry.value;
                          final isLast = idx == _splitLines.length - 1;
                          return IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                CustomPaint(
                                  size: Size(36.w, double.infinity),
                                  painter: TreeLinePainter(
                                    isPayer: false,
                                    isLast: isLast,
                                    color: scheme.outlineVariant.withValues(alpha: 0.5),
                                  ),
                                ),
                                SizedBox(width: AppDimensions.sm.w),
                                Expanded(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(vertical: 6.h),
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      line,
                                      style: context.textTheme.bodyMedium?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  SizedBox(height: AppDimensions.lg.h),

                  // ── Spending trend ───────────────────────────────────────
                  _SpendingTrendSection(
                    expense: e,
                    expenseRepository: _expenseRepository,
                    currentUserId: widget.currentUserId,
                    groupName: widget.groupName,
                  ),
                ],
              ),
            ),
          ),

          // ── Comment bar ─────────────────────────────────────────────────
          _CommentBar(controller: _commentController),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final Expense expense;
  final Color heroColor;
  final String dateStr;

  const _HeroSection({
    required this.expense,
    required this.heroColor,
    required this.dateStr,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.lg.w,
        vertical: AppDimensions.md.h,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category icon box dropdown selector
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _iconForCategory(expense.category),
                  color: scheme.onSurface,
                  size: 24.r,
                ),
                SizedBox(width: 2.w),
                Icon(
                  Icons.arrow_drop_down,
                  color: scheme.onSurfaceVariant,
                  size: 16.r,
                ),
              ],
            ),
          ),
          SizedBox(width: AppDimensions.md.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '${expense.currencySymbol}${expense.amount.toStringAsFixed(2)}',
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.primary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  dateStr,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'restaurant':
      case 'meal':
        return Icons.restaurant_rounded;
      case 'travel':
      case 'trip':
      case 'transport':
        return Icons.directions_car_filled_rounded;
      case 'shopping':
      case 'groceries':
        return Icons.shopping_bag_rounded;
      case 'entertainment':
        return Icons.movie_rounded;
      case 'utilities':
        return Icons.bolt_rounded;
      case 'settlement':
        return Icons.handshake_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }
}

class _PayerRow extends StatelessWidget {
  final String payerLine;
  final String? photoUrl;
  final String payerId;
  final String currentUserId;
  final Map<String, String> memberNames;

  const _PayerRow({
    required this.payerLine,
    required this.photoUrl,
    required this.payerId,
    required this.currentUserId,
    required this.memberNames,
  });

  String get _displayName {
    if (payerId == currentUserId) return 'You';
    return memberNames[payerId] ?? 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomPaint(
            size: Size(36.w, double.infinity),
            painter: TreeLinePainter(
              isPayer: true,
              isLast: false,
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: AvatarWidget(name: _displayName, imageUrl: photoUrl, size: 36.w),
            ),
          ),
          SizedBox(width: AppDimensions.sm.w),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              alignment: Alignment.centerLeft,
              child: Text(
                payerLine,
                style: context.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppDimensions.lg.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(AppDimensions.md.w),
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd.r),
        ),
        child: child,
      ),
    );
  }
}

// ── Spending Trend ─────────────────────────────────────────────────────────

class _SpendingTrendSection extends StatefulWidget {
  final Expense expense;
  final ExpenseRepository expenseRepository;
  final String currentUserId;

  final String? groupName;

  const _SpendingTrendSection({
    required this.expense,
    required this.expenseRepository,
    required this.currentUserId,
    this.groupName,
  });

  @override
  State<_SpendingTrendSection> createState() => _SpendingTrendSectionState();
}

class _SpendingTrendSectionState extends State<_SpendingTrendSection> {
  List<_MonthStat>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTrend();
  }

  Future<void> _loadTrend() async {
    final result = await widget.expenseRepository
        .getGroupExpenses(widget.expense.groupId);
    if (!mounted) return;
    if (result.isSuccess) {
      final expenses = result.dataOrThrow;
      final now = DateTime.now();
      // Build last 3 months of data
      final months = [
        DateTime(now.year, now.month - 2),
        DateTime(now.year, now.month - 1),
        now,
      ];
      final stats = months.map((m) {
        final total = expenses
            .where((e) => e.date.year == m.year && e.date.month == m.month)
            .fold<double>(0, (sum, e) => sum + e.amount);
        return _MonthStat(
          label: DateFormat('MMM').format(m),
          amount: total,
        );
      }).toList();
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, size: 18.r, color: scheme.primary),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  'Spending trends for ${widget.groupName ?? 'group'} :: ${widget.expense.category}',
                  style: context.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppDimensions.md.h),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_stats == null || _stats!.every((s) => s.amount == 0))
            Text(
              'No spending data available.',
              style: context.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            )
          else
            _TrendChart(stats: _stats!),
          SizedBox(height: AppDimensions.md.h),
          // "View more charts" button styled purple
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: Icon(Icons.diamond_rounded,
                  size: 16.r, color: scheme.onPrimary),
              label: const Text('View more charts'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8A3CF6),
                foregroundColor: scheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              onPressed: () {
              AppToast.show(context, 'Charts coming soon', type: ToastType.info);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthStat {
  final String label;
  final double amount;

  const _MonthStat({required this.label, required this.amount});
}

class _TrendChart extends StatelessWidget {
  final List<_MonthStat> stats;

  const _TrendChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final maxVal = stats.map((s) => s.amount).reduce(math.max);

    return Column(
      children: stats.map((stat) {
        final fraction = maxVal > 0 ? stat.amount / maxVal : 0.0;
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 4.h),
          child: Row(
            children: [
              SizedBox(
                width: 32.w,
                child: Text(
                  stat.label,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(4.r),
                      child: Stack(
                        children: [
                          Container(
                            height: 16.h,
                            color: scheme.surfaceContainerHighest,
                          ),
                          FractionallySizedBox(
                            widthFactor: fraction,
                            child: Container(
                              height: 16.h,
                              decoration: BoxDecoration(
                                color: scheme.primary.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SizedBox(width: 8.w),
              SizedBox(
                width: 72.w,
                child: Text(
                  'INR${stat.amount.toStringAsFixed(2)}',
                  textAlign: TextAlign.end,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Comment Bar ────────────────────────────────────────────────────────────

class _CommentBar extends StatelessWidget {
  final TextEditingController controller;

  const _CommentBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.md.w,
        AppDimensions.sm.h,
        AppDimensions.sm.w,
        AppDimensions.md.h + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Add a comment',
                border: InputBorder.none,
                hintStyle: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send_rounded, color: scheme.primary),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                AppToast.show(context, 'Comments coming soon', type: ToastType.info);
                controller.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}

class TreeLinePainter extends CustomPainter {
  final bool isPayer;
  final bool isLast;
  final Color color;

  TreeLinePainter({
    required this.isPayer,
    required this.isLast,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;

    if (isPayer) {
      // Line starts below the avatar (which has size 36.w and is aligned topCenter)
      canvas.drawLine(
        Offset(centerX, 36.w),
        Offset(centerX, size.height),
        paint,
      );
    } else {
      // Split row tree line
      final centerY = size.height / 2;
      if (isLast) {
        // Vertical line from top to center
        canvas.drawLine(
          Offset(centerX, 0),
          Offset(centerX, centerY),
          paint,
        );
      } else {
        // Vertical line from top to bottom
        canvas.drawLine(
          Offset(centerX, 0),
          Offset(centerX, size.height),
          paint,
        );
      }
      // Horizontal branch to the right
      canvas.drawLine(
        Offset(centerX, centerY),
        Offset(size.width, centerY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant TreeLinePainter oldDelegate) {
    return oldDelegate.isPayer != isPayer ||
        oldDelegate.isLast != isLast ||
        oldDelegate.color != color;
  }
}

