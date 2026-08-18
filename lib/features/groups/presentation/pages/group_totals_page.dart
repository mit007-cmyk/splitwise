import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/di.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../expenses/data/datasources/currency_catalog.dart';
import '../../domain/services/group_spending_calculator.dart';
import '../bloc/group_detail_cubit.dart';
import '../widgets/group_spending_chart.dart';
import '../widgets/spending_terms_sheet.dart';
import 'package:splitwise/features/home/presentation/bloc/home_bloc.dart';
import 'package:splitwise/features/home/presentation/bloc/home_state.dart';

/// Group spending summary ("Totals"): a ring for all-time spending or a
/// per-month bar chart, always scoped to one of the currencies the group has
/// actually used so converted and unconverted amounts are never added up.
class GroupTotalsPage extends StatefulWidget {
  final String groupId;

  const GroupTotalsPage({super.key, required this.groupId});

  @override
  State<GroupTotalsPage> createState() => _GroupTotalsPageState();
}

class _GroupTotalsPageState extends State<GroupTotalsPage> {
  late final GroupDetailCubit _cubit;
  String? _currencyCode;
  DateTime? _selectedMonth;
  bool _isAllTime = true;

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
          if (groupIndex == -1) {
            return const Scaffold(body: Center(child: Text('Group not found.')));
          }

          final group = homeState.summary.groups[groupIndex];

          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.help_outline),
                  onPressed: () => SpendingTermsSheet.show(context),
                ),
              ],
            ),
            body: BlocBuilder<GroupDetailCubit, GroupDetailState>(
              builder: (context, state) {
                if (state.isLoadingExpenses) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.expenseError != null) {
                  return Center(child: Text(state.expenseError!));
                }

                return _buildContent(context, state, group.groupName);
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
    final window = _monthWindow(selectedMonth);

    final summary = GroupSpendingCalculator.summarize(
      expenses: state.expenses,
      currencyCode: currencyCode,
      userId: _currentUserId,
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
              AppDimensions.xl.h,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  groupName,
                  style: context.textTheme.headlineSmall,
                ),
                SizedBox(height: AppDimensions.xs.h),
                Text(
                  _isAllTime
                      ? 'All time spending'
                      : '${DateFormat('MMMM yyyy').format(selectedMonth)} group spending',
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: AppDimensions.lg.h),
                _buildCurrencyChip(context, currencyCode, currencyCodes),
                SizedBox(height: AppDimensions.xl.h),
                if (_isAllTime)
                  Center(
                    child: GroupSpendingDonut(
                      totalSpent: summary.totalSpent,
                      yourShare: summary.yourShare,
                      centerLabel: 'Total',
                      centerAmount: summary.formatted(summary.totalSpent),
                    ),
                  )
                else
                  GroupSpendingBars(
                    bars: _buildBars(state, currencyCode, window, selectedMonth),
                    onSelect: (index) =>
                        setState(() => _selectedMonth = window[index]),
                  ),
                SizedBox(height: AppDimensions.xl.h),
                _buildMetric(
                  context,
                  label: 'Total spent',
                  amount: summary.formatted(summary.totalSpent),
                  color: AppColors.chartTotalSpent,
                ),
                SizedBox(height: AppDimensions.xl.h),
                _buildMetric(
                  context,
                  label: 'Your share',
                  amount: summary.formatted(summary.yourShare),
                  color: AppColors.chartYourShare,
                  footnote: summary.isEmpty
                      ? null
                      : '${summary.yourSharePercent}% of total group spending',
                ),
                SizedBox(height: AppDimensions.xl.h),
                _buildProBanner(context),
              ],
            ),
          ),
        ),
        _buildTimeFilter(context, months, selectedMonth),
      ],
    );
  }

  List<GroupSpendingBar> _buildBars(
    GroupDetailState state,
    String currencyCode,
    List<DateTime> window,
    DateTime selectedMonth,
  ) {
    return [
      for (final month in window)
        () {
          final summary = GroupSpendingCalculator.summarize(
            expenses: state.expenses,
            currencyCode: currencyCode,
            userId: _currentUserId,
            month: month,
          );
          return GroupSpendingBar(
            label: DateFormat('MMM').format(month).toUpperCase(),
            totalSpent: summary.totalSpent,
            yourShare: summary.yourShare,
            isSelected: month == selectedMonth,
          );
        }(),
    ];
  }

  /// The selected month plus the two before it, matching the window Splitwise
  /// keeps on screen while you step through a group's history.
  List<DateTime> _monthWindow(DateTime month) => [
        DateTime(month.year, month.month - 2),
        DateTime(month.year, month.month - 1),
        month,
      ];

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

  Widget _buildMetric(
    BuildContext context, {
    required String label,
    required String amount,
    required Color color,
    String? footnote,
  }) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: context.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: AppDimensions.xs.w),
            InkWell(
              customBorder: const CircleBorder(),
              onTap: () => SpendingTermsSheet.show(context),
              child: Padding(
                padding: EdgeInsets.all(2.r),
                child: Icon(
                  Icons.help_outline,
                  size: 16.r,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppDimensions.sm.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 5.w,
              height: 30.h,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm.r),
              ),
            ),
            SizedBox(width: AppDimensions.md.w),
            Expanded(
              child: Text(
                amount,
                style: context.textTheme.headlineSmall?.copyWith(color: color),
              ),
            ),
          ],
        ),
        if (footnote != null) ...[
          SizedBox(height: AppDimensions.sm.h),
          Padding(
            padding: EdgeInsets.only(left: 5.w + AppDimensions.md.w),
            child: Text(
              footnote,
              style: context.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.lg.w,
        vertical: AppDimensions.xl.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.proBannerBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg.r),
      ),
      child: Column(
        children: [
          Text(
            'Pro users get more',
            style: context.textTheme.titleLarge?.copyWith(
              color: context.appColors.onImageColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppDimensions.sm.h),
          Text(
            'More insights. More features. More!',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.appColors.onImageColor.withValues(alpha: 0.85),
            ),
          ),
          SizedBox(height: AppDimensions.lg.h),
          SizedBox(
            width: double.infinity,
            height: AppDimensions.buttonHeight.h,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.proBannerButton,
                foregroundColor: context.appColors.onImageColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusCircular.r,
                  ),
                ),
              ),
              onPressed: () =>
                  AppToast.show(context, 'Coming soon!', type: ToastType.info),
              child: Text(
                'Get Splitwise Pro',
                style: context.textTheme.titleSmall?.copyWith(
                  color: context.appColors.onImageColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
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
              _buildSegment(
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
                child: _buildSegment(
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
                                  DateFormat(
                                    'MMMM yyyy',
                                  ).format(selectedMonth),
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

  Widget _buildSegment(
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
    final picked = await showModalBottomSheet<DateTime>(
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
            for (final month in months.reversed)
              ListTile(
                title: Text(
                  DateFormat('MMMM yyyy').format(month),
                  style: sheetContext.textTheme.bodyLarge,
                ),
                trailing: month == selected
                    ? Icon(
                        Icons.check,
                        color: sheetContext.colorScheme.primary,
                      )
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(month),
              ),
          ],
        ),
      ),
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
              Icons.donut_large_rounded,
              size: 72.r,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            SizedBox(height: AppDimensions.lg.h),
            Text(
              'No totals to show yet.',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
            SizedBox(height: AppDimensions.sm.h),
            Text(
              'Add an expense to this group to see the spending summary.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
