import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/di.dart';
import '../../../../core/routing/route_constants.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../expenses/data/datasources/currency_catalog.dart';
import '../../domain/services/group_spending_calculator.dart';
import '../bloc/group_detail_cubit.dart';
import '../widgets/group_month_picker_dialog.dart';
import '../widgets/group_spending_chart.dart';
import 'package:splitwise/features/home/presentation/bloc/home_bloc.dart';
import 'package:splitwise/features/home/presentation/bloc/home_state.dart';

/// Splitwise-style group reports: spending over time, and spending by category.
class GroupSpendingReportsPage extends StatefulWidget {
  final String groupId;
  final String? initialCurrencyCode;

  const GroupSpendingReportsPage({
    super.key,
    required this.groupId,
    this.initialCurrencyCode,
  });

  @override
  State<GroupSpendingReportsPage> createState() =>
      _GroupSpendingReportsPageState();
}

class _GroupSpendingReportsPageState extends State<GroupSpendingReportsPage> {
  late final GroupDetailCubit _cubit;
  String? _currencyCode;
  DateTime? _selectedMonth;
  bool _isAllTime = true;

  @override
  void initState() {
    super.initState();
    _currencyCode = widget.initialCurrencyCode;
    _cubit = GroupDetailCubit(getIt(), getIt());
    _cubit.loadExpenses(widget.groupId);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, homeState) {
          if (homeState is! HomeLoaded) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final groupIndex = homeState.summary.groups.indexWhere(
            (g) => g.groupId == widget.groupId,
          );
          final groupName = groupIndex == -1
              ? 'Group'
              : homeState.summary.groups[groupIndex].groupName;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Charts'),
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
                return _buildContent(context, state, groupName);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    GroupDetailState state,
    String groupName,
  ) {
    final currencyCodes = GroupSpendingCalculator.currencyCodes(state.expenses);
    if (currencyCodes.isEmpty) return _buildEmptyState(context);

    final currencyCode = currencyCodes.contains(_currencyCode)
        ? _currencyCode!
        : currencyCodes.first;
    final months = GroupSpendingCalculator.months(state.expenses, currencyCode);
    final selectedMonth = _resolveMonth(months);
    final summary = GroupSpendingCalculator.summarize(
      expenses: state.expenses,
      currencyCode: currencyCode,
      userId: '',
      month: _isAllTime ? null : selectedMonth,
    );

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppDimensions.xl.w,
              AppDimensions.sm.h,
              AppDimensions.xl.w,
              AppDimensions.xxl.h,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(groupName, style: context.textTheme.headlineSmall),
                SizedBox(height: AppDimensions.xs.h),
                Text(
                  _isAllTime
                      ? 'All time spending'
                      : DateFormat('MMMM yyyy').format(selectedMonth),
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: AppDimensions.lg.h),
                _buildCurrencyChip(context, currencyCode, currencyCodes),
                SizedBox(height: AppDimensions.xl.h),
                GroupSpendingTrendChart(
                  points: GroupSpendingCalculator.spendingOverTime(
                    expenses: state.expenses,
                    currencyCode: currencyCode,
                    month: _isAllTime ? null : selectedMonth,
                  ),
                  currencySymbol: summary.currencySymbol,
                  daily: !_isAllTime,
                ),
                SizedBox(height: AppDimensions.xl.h),
                GroupCategoryBreakdown(
                  categories: GroupSpendingCalculator.spendingByCategory(
                    expenses: state.expenses,
                    currencyCode: currencyCode,
                    month: _isAllTime ? null : selectedMonth,
                  ),
                  currencySymbol: summary.currencySymbol,
                  onCategoryTap: (category) {
                    context.pushNamed(
                      RouteConstants.groupCategoryExpensesName,
                      pathParameters: {
                        'groupId': widget.groupId,
                        'category': category,
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        _buildTimeFilter(context, months, selectedMonth),
      ],
    );
  }

  DateTime _resolveMonth(List<DateTime> months) {
    if (_selectedMonth != null) return _selectedMonth!;
    if (months.isNotEmpty) return months.last;
    return GroupSpendingCalculator.monthOf(DateTime.now());
  }

  Widget _buildCurrencyChip(
    BuildContext context,
    String currencyCode,
    List<String> currencyCodes,
  ) {
    final scheme = context.colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd.r),
      onTap: currencyCodes.length < 2
          ? null
          : () => _pickCurrency(currencyCodes, currencyCode),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.md.w,
          vertical: AppDimensions.sm.h,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outline),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currencyCode,
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: AppDimensions.xs.w),
            Icon(Icons.arrow_drop_down, size: 20.r, color: scheme.onSurface),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeFilter(
    BuildContext context,
    List<DateTime> months,
    DateTime selectedMonth,
  ) {
    final scheme = context.colorScheme;
    final earliest = months.isEmpty ? selectedMonth : months.first;
    final latest = months.isEmpty ? selectedMonth : months.last;
    final canGoBack = selectedMonth.isAfter(earliest);
    final canGoForward = selectedMonth.isBefore(latest);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppDimensions.lg.w,
          AppDimensions.sm.h,
          AppDimensions.lg.w,
          AppDimensions.md.h,
        ),
        child: Container(
          padding: EdgeInsets.all(AppDimensions.xs.r),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppDimensions.radiusCircular.r),
          ),
          child: Row(
            children: [
              _segment(
                context,
                isSelected: _isAllTime,
                onTap: () => setState(() => _isAllTime = true),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppDimensions.md.w),
                  child: Text(
                    'All time',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: _isAllTime
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _segment(
                  context,
                  isSelected: !_isAllTime,
                  onTap: () => setState(() => _isAllTime = false),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.chevron_left),
                        color: scheme.onSurfaceVariant,
                        disabledColor: scheme.onSurfaceVariant.withValues(
                          alpha: 0.3,
                        ),
                        onPressed: canGoBack
                            ? () => _stepMonth(selectedMonth, -1)
                            : null,
                      ),
                      Flexible(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMd.r,
                          ),
                          onTap: months.isEmpty
                              ? null
                              : () => _pickMonth(months, selectedMonth),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  DateFormat('MMMM yyyy').format(selectedMonth),
                                  overflow: TextOverflow.ellipsis,
                                  style: context.textTheme.bodyMedium?.copyWith(
                                    color: _isAllTime
                                        ? scheme.onSurfaceVariant
                                        : scheme.onSurface,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                size: 20.r,
                                color: scheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.chevron_right),
                        color: scheme.onSurfaceVariant,
                        disabledColor: scheme.onSurfaceVariant.withValues(
                          alpha: 0.3,
                        ),
                        onPressed: canGoForward
                            ? () => _stepMonth(selectedMonth, 1)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _segment(
    BuildContext context, {
    required bool isSelected,
    required VoidCallback onTap,
    required Widget child,
  }) {
    final radius = BorderRadius.circular(AppDimensions.radiusCircular.r);
    return InkWell(
      borderRadius: radius,
      onTap: onTap,
      child: Container(
        height: 40.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? context.colorScheme.surfaceContainerHighest
              : Colors.transparent,
          borderRadius: radius,
        ),
        child: child,
      ),
    );
  }

  void _stepMonth(DateTime from, int delta) {
    setState(() {
      _isAllTime = false;
      _selectedMonth = DateTime(from.year, from.month + delta);
    });
  }

  Future<void> _pickCurrency(List<String> codes, String selected) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl.r),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final code in codes)
              ListTile(
                title: Text(
                  '$code · ${CurrencyCatalog.byCode(code).name}',
                  style: sheetContext.textTheme.bodyLarge,
                ),
                trailing: code == selected
                    ? Icon(
                        Icons.check,
                        color: sheetContext.colorScheme.primary,
                      )
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(code),
              ),
          ],
        ),
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _currencyCode = picked;
        _selectedMonth = null;
      });
    }
  }

  Future<void> _pickMonth(List<DateTime> months, DateTime selected) async {
    final now = GroupSpendingCalculator.monthOf(DateTime.now());
    final picked = await GroupMonthPickerDialog.show(
      context: context,
      selectedMonth: selected,
      minMonth: months.isEmpty ? null : DateTime(months.first.year),
      maxMonth: now,
    );
    if (picked != null && mounted) {
      setState(() {
        _isAllTime = false;
        _selectedMonth = picked;
      });
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    final scheme = context.colorScheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppDimensions.xl.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 72.r,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            SizedBox(height: AppDimensions.lg.h),
            Text(
              'No spending to chart yet.',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppDimensions.sm.h),
            Text(
              'Add an expense to this group to see spending over time and by category.',
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
