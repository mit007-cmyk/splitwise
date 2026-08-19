import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/di.dart';
import '../../../../core/routing/route_constants.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../../core/utils/user_display_names.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../expenses/domain/entities/expense_comment.dart';
import '../../../expenses/domain/repositories/expense_repository.dart';
import '../../../friends/domain/repositories/friends_repository.dart';
import '../widgets/category_picker_sheet.dart';
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
  final ValueNotifier<bool> _isSendingComment = ValueNotifier(false);
  late Map<String, String> _memberNames;
  late Expense _expense;
  bool _isLoadingComments = true;

  @override
  void initState() {
    super.initState();
    _expense = widget.expense;
    _memberNames = Map<String, String>.from(widget.memberNames);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveMissingNames();
      _refetchExpense();
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _isDeleting.dispose();
    _isSendingComment.dispose();
    super.dispose();
  }

  bool _isMissingName(String? name, String userId) {
    return UserDisplayNames.looksLikeRawId(name, userId) ||
        (name?.trim().toLowerCase() == 'unknown');
  }

  Future<void> _resolveMissingNames() async {
    final ids = <String>{
      ..._expense.participantIds,
      ..._expense.paidBy.keys,
      ..._expense.splits.keys,
      _expense.createdBy,
      ..._expense.comments.map((c) => c.createdBy),
    }..removeWhere((id) => id.trim().isEmpty);

    final missing = ids.where((id) {
      if (id == widget.currentUserId) return false;
      return _isMissingName(_memberNames[id], id);
    }).toList();

    if (missing.isEmpty) return;

    final resolved = <String, String>{};

    // Bulk load from users + pending contacts first.
    final directory = await UserDisplayNames.load(getIt<FirestoreService>());
    for (final id in missing) {
      final name = directory[id];
      if (name != null && !_isMissingName(name, id)) {
        resolved[id] = name;
      }
    }

    final stillMissing =
        missing.where((id) => _isMissingName(resolved[id] ?? _memberNames[id], id));
    if (stillMissing.isNotEmpty) {
      final friendsRepo = getIt<FriendsRepository>();
      await Future.wait(stillMissing.map((id) async {
        final result = await friendsRepo.getUserById(id);
        if (!result.isSuccess) return;
        final user = result.dataOrThrow;
        final name = user?.name.trim();
        if (name == null || _isMissingName(name, id)) return;
        resolved[id] = name;
      }));
    }

    // Last resort: names saved on block records (covers users blocked earlier).
    final remaining = missing
        .where((id) => _isMissingName(resolved[id] ?? _memberNames[id], id))
        .toList();
    if (remaining.isNotEmpty && widget.currentUserId.isNotEmpty) {
      final blocked =
          await getIt<FriendsRepository>().getBlockedUsers(widget.currentUserId);
      if (blocked.isSuccess) {
        for (final user in blocked.dataOrThrow) {
          if (!remaining.contains(user.id)) continue;
          final name = user.name.trim();
          if (_isMissingName(name, user.id)) continue;
          resolved[user.id] = name;
        }
      }
    }

    if (!mounted || resolved.isEmpty) return;
    setState(() => _memberNames.addAll(resolved));
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _displayName(String userId) {
    if (userId == widget.currentUserId) return 'You';
    final name = _memberNames[userId]?.trim();
    if (name == null || _isMissingName(name, userId)) return 'Unknown';
    return name;
  }

  /// Primary payer name + amount string, e.g. "You paid ₹210.00"
  String get _payerLine {
    final e = _expense;
    if (e.paidBy.isEmpty) return '';
    final topPayerId =
        e.paidBy.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    final topAmount = e.paidBy[topPayerId]!;
    final name = _displayName(topPayerId);
    return '$name paid ${e.currencySymbol}${topAmount.toStringAsFixed(2)}';
  }

  /// Per-user share lines, e.g. ["You owe ₹105.00", "Vishal B. owes ₹105.00"]
  List<String> get _splitLines {
    final e = _expense;
    return e.splits.entries.map((entry) {
      final name = _displayName(entry.key);
      final owes = entry.value;
      final verb = name == 'You' ? 'owe' : 'owes';
      return '$name $verb ${e.currencySymbol}${owes.toStringAsFixed(2)}';
    }).toList();
  }

  Color get _headerColor {
    final category = _expense.category.toLowerCase();
    if (category.contains('travel') || category.contains('transport')) {
      return AppColors.secondaryContainerLight;
    }
    if (category.contains('shop') || category.contains('entertainment')) {
      return AppColors.errorContainerLight;
    }
    return AppColors.primaryContainerLight;
  }

  Future<void> _refetchExpense({bool showCommentsLoader = false}) async {
    if (showCommentsLoader && mounted) {
      setState(() => _isLoadingComments = true);
    }
    final result = await _expenseRepository.getExpenseById(_expense.id);
    if (!mounted) return;
    if (!result.isSuccess) {
      setState(() => _isLoadingComments = false);
      return;
    }
    final fetched = result.dataOrThrow;
    setState(() {
      _isLoadingComments = false;
      if (fetched != null) _expense = fetched;
    });
    if (fetched != null) await _resolveMissingNames();
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSendingComment.value) return;
    _isSendingComment.value = true;
    final result = await _expenseRepository.addExpenseComment(
      expenseId: _expense.id,
      actorUserId: widget.currentUserId,
      text: text,
    );
    if (!mounted) return;
    _isSendingComment.value = false;
    if (result.isSuccess) {
      _commentController.clear();
      await _refetchExpense();
    } else {
      final message = result is FailureResult<void>
          ? result.failure.message
          : 'Could not save comment. Try again.';
      AppToast.show(context, message, type: ToastType.error);
    }
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  Future<void> _confirmDelete() async {
    if (_expense.createdBy != widget.currentUserId) {
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
      expenseId: _expense.id,
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
    final e = _expense;
    final headerColor = _headerColor;
    final headerIconColor = AppColors.textPrimaryLight;
    final addedStr =
        'Added by ${_displayName(e.createdBy)} on ${DateFormat('dd-MMM-yyyy').format(e.date)}';
    final updatedStr = e.updatedBy == null
        ? null
        : 'Updated by ${_displayName(e.updatedBy!)} on ${DateFormat('dd-MMM-yyyy').format(e.date)}';

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: headerColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: headerIconColor),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: _isDeleting,
            builder: (context, deleting, child) => IconButton(
              icon: deleting
                  ? SizedBox(
                      width: 20.r,
                      height: 20.r,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: headerIconColor,
                      ),
                    )
                  : const Icon(Icons.delete_outline),
              tooltip: 'Delete expense',
              onPressed: deleting ||
                      _expense.createdBy != widget.currentUserId
                  ? null
                  : _confirmDelete,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit expense',
            onPressed: () async {
              if (_expense.createdBy != widget.currentUserId) {
                AppToast.show(
                  context,
                  'Only the creator can edit this expense.',
                  type: ToastType.warning,
                );
                return;
              }
              final changed = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) =>
                      AddExpensePage(existingExpense: _expense),
                ),
              );
              if (changed == true && context.mounted) {
                Navigator.of(context).pop(true);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 36.h,
                  width: double.infinity,
                  color: headerColor,
                ),
                Expanded(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SingleChildScrollView(
                        padding: EdgeInsets.only(
                          top: 40.h,
                          bottom: AppDimensions.xl.h,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppDimensions.xl.w,
                      0,
                      AppDimensions.xl.w,
                      AppDimensions.lg.h,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.title,
                          style: context.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: AppDimensions.xs.h),
                        Text(
                          '${e.currencySymbol}${e.amount.toStringAsFixed(2)}',
                          style: context.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: AppDimensions.sm.h),
                        Text(
                          addedStr,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        if (updatedStr != null) ...[
                          SizedBox(height: 2.h),
                          Text(
                            updatedStr,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDimensions.xl.w,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PayerRow(
                          payerLine: _payerLine,
                          photoUrl: null,
                          payerId: e.paidBy.isNotEmpty
                              ? e.paidBy.entries
                                  .reduce(
                                    (a, b) => a.value >= b.value ? a : b,
                                  )
                                  .key
                              : '',
                          currentUserId: widget.currentUserId,
                          memberNames: _memberNames,
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
                                    color: scheme.outlineVariant
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                SizedBox(width: AppDimensions.sm.w),
                                Expanded(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 6.h,
                                    ),
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      line,
                                      style: context.textTheme.bodyMedium
                                          ?.copyWith(
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
                  SizedBox(height: AppDimensions.xl.h),
                  _SpendingTrendSection(
                    expense: e,
                    expenseRepository: _expenseRepository,
                    groupName: widget.groupName,
                    barColor: headerColor,
                  ),
                  SizedBox(height: AppDimensions.xl.h),
                  _CommentsSection(
                    comments: e.comments,
                    isLoading: _isLoadingComments,
                    currentUserId: widget.currentUserId,
                    displayName: _displayName,
                  ),
                ],
              ),
            ),
                      Positioned(
                        left: AppDimensions.xl.w,
                        top: -32,
                        child: _CategoryBadge(category: e.category),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _CommentBar(
            controller: _commentController,
            isSubmitting: _isSendingComment,
            onSubmit: _submitComment,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryBadge extends StatelessWidget {
  final String category;

  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceLight,
        border: Border.all(color: AppColors.textPrimaryLight, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        ExpenseCategory.iconFor(category),
        size: 28,
        color: AppColors.textPrimaryLight,
      ),
    );
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

class _SpendingTrendSection extends StatefulWidget {
  final Expense expense;
  final ExpenseRepository expenseRepository;
  final String? groupName;
  final Color barColor;

  const _SpendingTrendSection({
    required this.expense,
    required this.expenseRepository,
    this.groupName,
    required this.barColor,
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
        final category = widget.expense.category.toLowerCase();
        final total = expenses
            .where(
              (e) =>
                  !e.isDeleted &&
                  e.category.toLowerCase() != 'settlement' &&
                  e.category.toLowerCase() == category &&
                  e.date.year == m.year &&
                  e.date.month == m.month,
            )
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppDimensions.xl.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending trends for ${widget.groupName ?? 'group'} :: ${widget.expense.category}',
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppDimensions.md.h),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else
            _TrendChart(
              stats: _stats ?? const [],
              barColor: widget.barColor,
              currencyCode: widget.expense.currencyCode,
            ),
          SizedBox(height: AppDimensions.lg.h),
          SizedBox(
            width: double.infinity,
            height: AppDimensions.buttonHeight.h,
            child: FilledButton.icon(
              icon: Icon(
                Icons.diamond_rounded,
                size: 16.r,
                color: AppColors.onImageLight,
              ),
              label: const Text('View more charts'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.proBannerButton,
                foregroundColor: AppColors.onImageLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd.r),
                ),
              ),
              onPressed: () {
                final groupId = widget.expense.groupId.trim();
                if (groupId.isEmpty) {
                  AppToast.show(
                    context,
                    'Charts are available for group expenses.',
                    type: ToastType.info,
                  );
                  return;
                }
                context.pushNamed(
                  RouteConstants.groupSpendingReportsName,
                  pathParameters: {'groupId': groupId},
                  extra: widget.expense.currencyCode,
                );
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
  final Color barColor;
  final String currencyCode;

  const _TrendChart({
    required this.stats,
    required this.barColor,
    required this.currencyCode,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    if (stats.isEmpty) return const SizedBox.shrink();
    final maxVal = stats.map((s) => s.amount).fold<double>(0, math.max);

    return Column(
      children: [
        for (final stat in stats)
          Padding(
            padding: EdgeInsets.symmetric(vertical: AppDimensions.sm.h),
            child: Row(
              children: [
                SizedBox(
                  width: 36.w,
                  child: Text(
                    stat.label,
                    style: context.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: AppDimensions.sm.w),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final fraction = maxVal > 0 ? stat.amount / maxVal : 0.0;
                      final width = math.max(
                        8.0,
                        constraints.maxWidth * fraction,
                      );
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          height: 14.h,
                          width: width,
                          decoration: BoxDecoration(
                            color: stat.amount > 0
                                ? barColor
                                : scheme.outlineVariant,
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusMd.r,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: AppDimensions.sm.w),
                Text(
                  '$currencyCode${stat.amount.toStringAsFixed(2)}',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ── Comment Bar ────────────────────────────────────────────────────────────

class _CommentsSection extends StatelessWidget {
  final List<ExpenseComment> comments;
  final bool isLoading;
  final String currentUserId;
  final String Function(String userId) displayName;

  const _CommentsSection({
    required this.comments,
    required this.isLoading,
    required this.currentUserId,
    required this.displayName,
  });

  String _meta(ExpenseComment comment) {
    final name = displayName(comment.createdBy);
    return '$name · ${_timeLabel(comment.createdAt)}';
  }

  String _timeLabel(DateTime at) {
    final now = DateTime.now();
    final diff = now.difference(at);
    if (diff.inMinutes < 1) return 'Just now';
    if (at.year == now.year && at.month == now.month && at.day == now.day) {
      return DateFormat('h:mm a').format(at);
    }
    return DateFormat('dd-MMM-yyyy').format(at);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppDimensions.xl.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comments',
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppDimensions.md.h),
          if (isLoading)
            Padding(
              padding: EdgeInsets.symmetric(vertical: AppDimensions.lg.h),
              child: Center(
                child: SizedBox(
                  width: 24.r,
                  height: 24.r,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.primary,
                  ),
                ),
              ),
            )
          else if (comments.isEmpty)
            Text(
              'No comments yet.',
              style: context.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            )
          else
            for (final comment in comments) ...[
              Align(
                alignment: comment.createdBy == currentUserId
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Text(
                  _meta(comment),
                  style: context.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(height: AppDimensions.xs.h),
              Align(
                alignment: comment.createdBy == currentUserId
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 280.w),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDimensions.md.w,
                      vertical: AppDimensions.sm.h,
                    ),
                    decoration: BoxDecoration(
                      color: comment.createdBy == currentUserId
                          ? AppColors.primaryContainerDark
                          : scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusLg.r,
                      ),
                    ),
                    child: Text(
                      comment.text,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: comment.createdBy == currentUserId
                            ? AppColors.onImageLight
                            : scheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: AppDimensions.md.h),
            ],
        ],
      ),
    );
  }
}

class _CommentBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueNotifier<bool> isSubmitting;
  final VoidCallback onSubmit;

  const _CommentBar({
    required this.controller,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppDimensions.lg.w,
          AppDimensions.sm.h,
          AppDimensions.lg.w,
          AppDimensions.md.h,
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSubmit(),
                decoration: InputDecoration(
                  hintText: 'Add a comment',
                  filled: true,
                  fillColor: scheme.surfaceContainerHigh,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppDimensions.lg.w,
                    vertical: AppDimensions.sm.h,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusCircular.r,
                    ),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusCircular.r,
                    ),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusCircular.r,
                    ),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(width: AppDimensions.sm.w),
            ValueListenableBuilder<bool>(
              valueListenable: isSubmitting,
              builder: (context, submitting, _) {
                return IconButton(
                  icon: submitting
                      ? SizedBox(
                          width: 20.r,
                          height: 20.r,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.onSurfaceVariant,
                          ),
                        )
                      : Icon(
                          Icons.send_rounded,
                          color: scheme.onSurfaceVariant,
                        ),
                  onPressed: submitting ? null : onSubmit,
                );
              },
            ),
          ],
        ),
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

