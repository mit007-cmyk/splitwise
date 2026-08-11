import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/di.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/group_detail_cubit.dart';
import 'package:splitwise/features/home/presentation/bloc/home_bloc.dart';
import 'package:splitwise/features/home/presentation/bloc/home_state.dart';

class GroupChartsPage extends StatefulWidget {
  final String groupId;

  const GroupChartsPage({super.key, required this.groupId});

  @override
  State<GroupChartsPage> createState() => _GroupChartsPageState();
}

class _GroupChartsPageState extends State<GroupChartsPage> {
  late final GroupDetailCubit _cubit;

  String get _currentUserId {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      return authState.user.id;
    }
    return '';
  }

  @override
  void initState() {
    super.initState();
    _cubit = GroupDetailCubit(getIt(), getIt());
    _cubit.loadExpenses(widget.groupId);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  // Predefined category colors for the chart
  Color _colorForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'general':
        return const Color(0xFF4A90E2); // Blue
      case 'food & dining':
      case 'food':
      case 'dining out':
      case 'restaurant':
      case 'meal':
        return const Color(0xFFF5A623); // Orange
      case 'groceries':
        return const Color(0xFF7ED321); // Green
      case 'home':
      case 'household supplies':
        return const Color(0xFF9013FE); // Purple
      case 'utilities':
        return const Color(0xFFF8E71C); // Yellow
      case 'transportation':
      case 'travel':
      case 'trip':
      case 'auto/travel':
        return const Color(0xFFD0021B); // Red
      case 'entertainment':
        return const Color(0xFFBD10E0); // Magenta
      case 'health':
        return const Color(0xFF50E3C2); // Teal
      case 'shopping':
        return const Color(0xFFE2849C); // Pink
      case 'rent':
        return const Color(0xFFB8E986); // Light Green
      default:
        return const Color(0xFF8B949E); // Grey
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, homeState) {
          if (homeState is! HomeLoaded) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          final groupIndex =
              homeState.summary.groups.indexWhere((g) => g.groupId == widget.groupId);
          if (groupIndex == -1) {
            return const Scaffold(body: Center(child: Text('Group not found.')));
          }

          final group = homeState.summary.groups[groupIndex];

          return Scaffold(
            appBar: AppBar(
              title: Text('${group.groupName} - Charts'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
            ),
            body: BlocBuilder<GroupDetailCubit, GroupDetailState>(
              builder: (context, state) {
                if (state.isLoadingExpenses) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.expenseError != null) {
                  return Center(child: Text(state.expenseError!));
                }

                // Filter out deleted and settlement expenses
                final validExpenses = state.expenses.where((e) =>
                    !e.isDeleted && e.category.toLowerCase() != 'settlement').toList();

                if (validExpenses.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.pie_chart_outline_rounded,
                              size: 72.r, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                          SizedBox(height: 16.h),
                          Text(
                            'No spending data in this group yet.',
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Add some expenses with categories to view spending analysis.',
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Group expenses by category
                final categoryTotals = <String, double>{};
                final userPaidMap = <String, double>{};
                final userShareMap = <String, double>{};

                for (final exp in validExpenses) {
                  final cat = exp.category;
                  categoryTotals[cat] = (categoryTotals[cat] ?? 0.0) + exp.amount;

                  // Compute "You paid for"
                  final youPaid = exp.paidBy[_currentUserId] ?? 0.0;
                  userPaidMap[cat] = (userPaidMap[cat] ?? 0.0) + youPaid;

                  // Compute "Your share"
                  final yourShare = exp.splits[_currentUserId] ?? 0.0;
                  userShareMap[cat] = (userShareMap[cat] ?? 0.0) + yourShare;
                }

                final totalSpending = categoryTotals.values.fold(0.0, (sum, val) => sum + val);

                // Sort categories by spending amount descending
                final sortedCategories = categoryTotals.keys.toList()
                  ..sort((a, b) => categoryTotals[b]!.compareTo(categoryTotals[a]!));

                return SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: 40.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 16.h),
                      // Pie Chart visualizer
                      Center(
                        child: Container(
                          width: 220.w,
                          height: 220.w,
                          margin: EdgeInsets.symmetric(vertical: 16.h),
                          child: CustomPaint(
                            painter: _PieChartPainter(
                              categoryTotals: categoryTotals,
                              total: totalSpending,
                              categoryColors: {
                                for (final cat in categoryTotals.keys)
                                  cat: _colorForCategory(cat)
                              },
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // Chart Legend
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Wrap(
                          spacing: 12.w,
                          runSpacing: 8.h,
                          alignment: WrapAlignment.center,
                          children: sortedCategories.map((cat) {
                            final amount = categoryTotals[cat] ?? 0.0;
                            final percent = totalSpending > 0 ? (amount / totalSpending * 100) : 0.0;
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 12.w,
                                  height: 12.w,
                                  decoration: BoxDecoration(
                                    color: _colorForCategory(cat),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  '$cat (${percent.toStringAsFixed(1)}%)',
                                  style: context.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // Spending summary table header
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Text(
                          'Category Spending Summary',
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),

                      // Summary Table matching requested mock layout
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: GlassCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              // Table Header Row
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(12.r),
                                    topRight: Radius.circular(12.r),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        'Category',
                                        style: context.textTheme.labelMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.onSurfaceVariant),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'You Paid',
                                        textAlign: TextAlign.end,
                                        style: context.textTheme.labelMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.onSurfaceVariant),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Your Share',
                                        textAlign: TextAlign.end,
                                        style: context.textTheme.labelMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.onSurfaceVariant),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Net Balance',
                                        textAlign: TextAlign.end,
                                        style: context.textTheme.labelMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.onSurfaceVariant),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Table Rows for each Category
                              ...sortedCategories.map((cat) {
                                final youPaid = userPaidMap[cat] ?? 0.0;
                                final yourShare = userShareMap[cat] ?? 0.0;
                                final netBalance = youPaid - yourShare;
                                final isPositive = netBalance >= -0.01;

                                return InkWell(
                                  onTap: () {
                                    context.push('/group-detail/${widget.groupId}/charts/category/$cat');
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                                          width: 0.5,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // Category Name with color indicator
                                        Expanded(
                                          flex: 3,
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 8.w,
                                                height: 8.w,
                                                decoration: BoxDecoration(
                                                  color: _colorForCategory(cat),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              SizedBox(width: 8.w),
                                              Expanded(
                                                child: Text(
                                                  cat,
                                                  style: context.textTheme.bodyMedium?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // You Paid Column
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            '₹${youPaid.toStringAsFixed(2)}',
                                            textAlign: TextAlign.end,
                                            style: context.textTheme.bodyMedium,
                                          ),
                                        ),
                                        // Your Share Column
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            '₹${yourShare.toStringAsFixed(2)}',
                                            textAlign: TextAlign.end,
                                            style: context.textTheme.bodyMedium,
                                          ),
                                        ),
                                        // Net Balance Column
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            '₹${netBalance.toStringAsFixed(2)}',
                                            textAlign: TextAlign.end,
                                            style: context.textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: isPositive
                                                  ? context.appColors.positiveBalanceColor
                                                  : context.appColors.negativeBalanceColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),

                              // Overall Total Summary row
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainer.withOpacity(0.2),
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(12.r),
                                    bottomRight: Radius.circular(12.r),
                                  ),
                                ),
                                child: Builder(builder: (ctx) {
                                  final totalPaid = userPaidMap.values.fold(0.0, (a, b) => a + b);
                                  final totalShare = userShareMap.values.fold(0.0, (a, b) => a + b);
                                  final totalNet = totalPaid - totalShare;

                                  return Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          'Overall Balance',
                                          style: context.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 6,
                                        child: Text(
                                          totalNet >= 0
                                              ? 'You are owed ₹${totalNet.toStringAsFixed(2)} overall'
                                              : 'You owe ₹${totalNet.abs().toStringAsFixed(2)} overall',
                                          textAlign: TextAlign.end,
                                          style: context.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: totalNet >= 0
                                                ? context.appColors.positiveBalanceColor
                                                : context.appColors.negativeBalanceColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final Map<String, double> categoryTotals;
  final double total;
  final Map<String, Color> categoryColors;

  _PieChartPainter({
    required this.categoryTotals,
    required this.total,
    required this.categoryColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;

    // Background circle shadow/border
    final borderPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..color = const Color(0x1F000000)
      ..strokeWidth = 1;

    double startAngle = -math.pi / 2;

    for (final entry in categoryTotals.entries) {
      final sweepAngle = total > 0 ? (entry.value / total) * 2 * math.pi : 0.0;
      paint.color = categoryColors[entry.key] ?? const Color(0xFF8B949E);

      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
      canvas.drawArc(rect, startAngle, sweepAngle, true, borderPaint);

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.total != total ||
        oldDelegate.categoryTotals.length != categoryTotals.length;
  }
}
