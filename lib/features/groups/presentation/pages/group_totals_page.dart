import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/di.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../bloc/group_detail_cubit.dart';
import 'package:splitwise/features/home/presentation/bloc/home_bloc.dart';
import 'package:splitwise/features/home/presentation/bloc/home_state.dart';

/// Group spending summary ("Totals"), broken down per currency so converted
/// and unconverted expenses are never added together.
class GroupTotalsPage extends StatefulWidget {
  final String groupId;

  const GroupTotalsPage({super.key, required this.groupId});

  @override
  State<GroupTotalsPage> createState() => _GroupTotalsPageState();
}

class _GroupTotalsPageState extends State<GroupTotalsPage> {
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

  List<_CurrencyTotals> _buildTotals(List<Expense> expenses) {
    final byCurrency = <String, _CurrencyTotals>{};
    final userId = _currentUserId;

    for (final expense in expenses) {
      if (expense.isDeleted) continue;

      final code = expense.currencyCode.trim().isEmpty
          ? 'INR'
          : expense.currencyCode.trim();
      final totals = byCurrency.putIfAbsent(
        code,
        () => _CurrencyTotals(
          code: code,
          symbol: expense.currencySymbol.trim().isEmpty
              ? code
              : expense.currencySymbol.trim(),
        ),
      );

      final paidByYou = expense.paidBy[userId] ?? 0.0;
      final owedByYou = expense.splits[userId] ?? 0.0;

      if (expense.category.toLowerCase() == 'settlement') {
        totals.paymentsMade += paidByYou;
        totals.paymentsReceived += owedByYou;
      } else {
        totals.groupSpending += expense.amount;
        totals.youPaidFor += paidByYou;
        totals.yourShare += owedByYou;
      }
    }

    final result = byCurrency.values.toList()
      ..sort((a, b) => b.groupSpending.compareTo(a.groupSpending));
    return result;
  }

  @override
  Widget build(BuildContext context) {
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
              title: Text('${group.groupName} - Totals'),
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

                final totals = _buildTotals(state.expenses);
                if (totals.isEmpty) {
                  return _buildEmptyState(context);
                }

                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    AppDimensions.lg.w,
                    AppDimensions.lg.h,
                    AppDimensions.lg.w,
                    40.h,
                  ),
                  itemCount: totals.length,
                  separatorBuilder: (_, _) => SizedBox(height: AppDimensions.lg.h),
                  itemBuilder: (context, index) =>
                      _buildTotalsCard(context, totals[index]),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = context.theme;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppDimensions.xl.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.summarize_outlined,
              size: 72.r,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            SizedBox(height: AppDimensions.lg.h),
            Text(
              'No totals to show yet.',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: AppDimensions.sm.h),
            Text(
              'Add an expense to this group to see the spending summary.',
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

  Widget _buildTotalsCard(BuildContext context, _CurrencyTotals totals) {
    final theme = context.theme;

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: AppDimensions.lg.w,
              vertical: AppDimensions.md.h,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppDimensions.radiusLg.r),
                topRight: Radius.circular(AppDimensions.radiusLg.r),
              ),
            ),
            child: Text(
              'Group spending summary (${totals.code})',
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppDimensions.lg.w,
              vertical: AppDimensions.sm.h,
            ),
            child: Column(
              children: [
                _buildRow(context, 'Total group spending', totals.groupSpending, totals.symbol),
                _buildRow(context, 'Total you paid for', totals.youPaidFor, totals.symbol),
                _buildRow(context, 'Your total share', totals.yourShare, totals.symbol),
                _buildRow(context, 'Your total payments made', totals.paymentsMade, totals.symbol),
                const Divider(height: 1),
                _buildRow(
                  context,
                  'Your total change in balance',
                  totals.changeInBalance,
                  totals.symbol,
                  emphasized: true,
                  signed: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    String label,
    double amount,
    String symbol, {
    bool emphasized = false,
    bool signed = false,
  }) {
    final theme = context.theme;
    final appColors = context.appColors;

    final Color amountColor;
    if (!signed) {
      amountColor = theme.colorScheme.onSurface;
    } else if (amount > 0.01) {
      amountColor = appColors.positiveBalanceColor;
    } else if (amount < -0.01) {
      amountColor = appColors.negativeBalanceColor;
    } else {
      amountColor = theme.colorScheme.onSurfaceVariant;
    }

    final prefix = signed && amount > 0.01 ? '+' : (signed && amount < -0.01 ? '-' : '');
    final value = '$prefix$symbol${amount.abs().toStringAsFixed(2)}';

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppDimensions.md.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: context.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: emphasized ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          SizedBox(width: AppDimensions.md.w),
          Text(
            value,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: emphasized ? FontWeight.bold : FontWeight.w600,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrencyTotals {
  final String code;
  final String symbol;
  double groupSpending = 0.0;
  double youPaidFor = 0.0;
  double yourShare = 0.0;
  double paymentsMade = 0.0;
  double paymentsReceived = 0.0;

  _CurrencyTotals({required this.code, required this.symbol});

  double get changeInBalance =>
      (youPaidFor - yourShare) + (paymentsMade - paymentsReceived);
}
