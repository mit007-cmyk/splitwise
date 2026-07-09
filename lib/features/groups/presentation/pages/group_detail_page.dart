import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/di.dart';
import '../../../../core/routing/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../expenses/presentation/pages/expense_detail_page.dart';
import '../../../home/domain/entities/balance_summary.dart';
import '../../../home/domain/entities/group_summary.dart';
import '../bloc/group_detail_cubit.dart';
import 'group_settle_balances_page.dart';
import 'package:splitwise/features/home/presentation/bloc/home_bloc.dart';
import 'package:splitwise/features/home/presentation/bloc/home_event.dart';
import 'package:splitwise/features/home/presentation/bloc/home_state.dart';

class GroupDetailPage extends StatefulWidget {
  final String groupId;

  const GroupDetailPage({super.key, required this.groupId});

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshData());
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _refreshData() async {
    context.read<HomeBloc>().add(const RefreshHome());
    await _cubit.loadExpenses(widget.groupId);
  }

  Color _heroColor(String name) =>
      AppColors.avatarPlaceholders[name.length % AppColors.avatarPlaceholders.length];

  Color _heroColorDark(String name) =>
      Color.lerp(_heroColor(name), AppColors.shadow, 0.35)!;

  Future<void> _openAddExpense(BuildContext context) async {
    await context.pushNamed(
      RouteConstants.addExpenseName,
      queryParameters: {'groupId': widget.groupId},
    );
    if (!mounted) return;
    await _refreshData();
  }

  Future<void> _openSettings(BuildContext context) async {
    await context.push('/group-detail/${widget.groupId}/settings');
    if (!mounted) return;
    await _refreshData();
  }

  Future<void> _openSettleUp(BuildContext context, GroupSummary group) async {
    final recorded = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => GroupSettleBalancesPage(
          groupId: widget.groupId,
          currentUserId: _currentUserId,
          balances: group.memberBalances,
        ),
      ),
    );
    if (recorded == true && mounted) {
      await _refreshData();
    }
  }

  void _showAddExpenseDialog(BuildContext context) {
    final theme = context.theme;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          contentPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'You are the only person in this group.',
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              Text(
                'Do you need to add anyone to your group before you start adding expenses?',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              ElevatedButton(
                style: theme.elevatedButtonTheme.style,
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _openAddExpense(context);
                },
                child: Text(
                  'Start adding expenses',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp),
                ),
              ),
              SizedBox(height: 12.h),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  context.push('/group-detail/${widget.groupId}/add-members');
                },
                child: Text(
                  'Add group members',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15.sp,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionPill(
    BuildContext context,
    String label, {
    IconData? icon,
    VoidCallback? onTap,
  }) {
    final scheme = context.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        margin: EdgeInsets.only(right: 8.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outline),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16.r, color: scheme.secondary),
              SizedBox(width: 6.w),
            ],
            Text(
              label,
              style: context.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<MemberBalance> _unsettledBalances(GroupSummary group) {
    return group.memberBalances
        .where((b) => b.userId.trim().isNotEmpty && b.amount.abs() > 0.01)
        .toList();
  }

  String _overallText(GroupSummary group) {
    final unsettled = _unsettledBalances(group);
    if (unsettled.isEmpty) {
      return 'You are all settled up in this group.';
    }
    if (unsettled.length == 1) {
      final balance = unsettled.first;
      final value = '₹${balance.amount.toStringAsFixed(2)}';
      return balance.type == BalanceType.owed
          ? '${balance.userName} owes you $value'
          : 'You owe ${balance.userName} $value';
    }

    double owedTotal = 0.0;
    double oweTotal = 0.0;
    for (final balance in unsettled) {
      if (balance.type == BalanceType.owed) {
        owedTotal += balance.amount;
      } else if (balance.type == BalanceType.owe) {
        oweTotal += balance.amount;
      }
    }

    if (owedTotal > 0.01 && oweTotal > 0.01) {
      return 'You are owed ₹${owedTotal.toStringAsFixed(2)} and owe ₹${oweTotal.toStringAsFixed(2)}';
    }
    if (owedTotal > 0.01) {
      return 'You are owed ₹${owedTotal.toStringAsFixed(2)} overall';
    }
    return 'You owe ₹${oweTotal.toStringAsFixed(2)} overall';
  }

  Color _overallColor(BuildContext context, GroupSummary group) {
    final unsettled = _unsettledBalances(group);
    if (unsettled.isEmpty) {
      return context.colorScheme.onSurfaceVariant;
    }
    if (unsettled.length == 1) {
      return unsettled.first.type == BalanceType.owed
          ? context.appColors.positiveBalanceColor
          : context.appColors.negativeBalanceColor;
    }
    final hasOwed = unsettled.any((b) => b.type == BalanceType.owed);
    final hasOwe = unsettled.any((b) => b.type == BalanceType.owe);
    if (hasOwed && hasOwe) {
      return context.colorScheme.onSurface;
    }
    return hasOwed ? context.appColors.positiveBalanceColor : context.appColors.negativeBalanceColor;
  }

  Widget _buildOverallStatus(BuildContext context, GroupSummary group) {
    final unsettled = _unsettledBalances(group);
    final textStyle = context.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
      color: _overallColor(context, group),
    );

    if (unsettled.isEmpty) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.celebration_rounded,
            size: 20.r,
            color: context.appColors.positiveBalanceColor,
          ),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              'You are all settled up in this group.',
              style: textStyle,
            ),
          ),
        ],
      );
    }

    return Text(_overallText(group), style: textStyle);
  }

  List<String> _balanceBreakdown(GroupSummary group) {
    final lines = <String>[];
    for (final balance in _unsettledBalances(group)) {
      final amount = '₹${balance.amount.toStringAsFixed(2)}';
      lines.add(
        balance.type == BalanceType.owed
            ? '${balance.userName} owes you $amount'
            : 'You owe ${balance.userName} $amount',
      );
    }
    return lines;
  }

  String _displayName(String userId, Map<String, String> memberNames) {
    if (userId == _currentUserId) return 'You';
    return memberNames[userId] ?? 'Unknown';
  }

  String _leadingSubtitle(Expense expense, Map<String, String> memberNames) {
    final paidByMe = expense.paidBy[_currentUserId] ?? 0.0;
    final owedByMe = expense.splits[_currentUserId] ?? 0.0;
    final net = paidByMe - owedByMe;
    if (net > 0.01) {
      return 'You paid ${expense.currencySymbol}${paidByMe.toStringAsFixed(2)}';
    }
    if (net < -0.01) {
      var topPayerId = '';
      var topPayerAmount = 0.0;
      expense.paidBy.forEach((id, amount) {
        if (amount > topPayerAmount) {
          topPayerId = id;
          topPayerAmount = amount;
        }
      });
      final payerName = memberNames[topPayerId] ?? 'Someone';
      return '$payerName paid ${expense.currencySymbol}${topPayerAmount.toStringAsFixed(2)}';
    }
    return 'You are not involved';
  }

  Widget _buildExpenseTile(BuildContext context, Expense expense, Map<String, String> memberNames) {
    final scheme = context.colorScheme;
    final appColors = context.appColors;

    final isSettlement = expense.category.toLowerCase() == 'settlement';
    final payerId = expense.paidBy.isNotEmpty ? expense.paidBy.keys.first : '';
    final receiverId = expense.splits.isNotEmpty ? expense.splits.keys.first : '';
    final payerName = _displayName(payerId, memberNames);
    final receiverName = _displayName(receiverId, memberNames);

    final net = (expense.paidBy[_currentUserId] ?? 0.0) - (expense.splits[_currentUserId] ?? 0.0);

    return InkWell(
      onTap: () async {
        final deleted = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => ExpenseDetailPage(
              expense: expense,
              memberNames: memberNames,
              currentUserId: _currentUserId,
            ),
          ),
        );
        if (deleted == true && mounted) {
          await _refreshData();
        }
      },
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
        leading: SizedBox(
          width: 74.w,
          child: Row(
            children: [
              SizedBox(
                width: 28.w,
                child: Text(
                  DateFormat('d\nMMM').format(expense.date),
                  textAlign: TextAlign.center,
                  style: context.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  color: isSettlement ? appColors.positiveBalanceColor : _iconBackgroundForCategory(expense.category, scheme),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  isSettlement ? Icons.payments_rounded : _iconForCategory(expense.category),
                  size: 18.r,
                  color: isSettlement ? scheme.onPrimary : scheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
        title: Text(
          isSettlement ? '$payerName paid $receiverName ${expense.currencySymbol}${expense.amount.toStringAsFixed(2)}' : expense.title,
          style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
        ),
        subtitle: isSettlement
            ? null
            : Text(
                _leadingSubtitle(expense, memberNames),
                style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
        trailing: isSettlement || net.abs() < 0.01
            ? null
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    net > 0 ? 'you lent' : 'you borrowed',
                    style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  Text(
                    '${expense.currencySymbol}${net.abs().toStringAsFixed(2)}',
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: net > 0 ? appColors.positiveBalanceColor : appColors.negativeBalanceColor,
                    ),
                  ),
                ],
              ),
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
      default:
        return Icons.receipt_long_rounded;
    }
  }

  Color _iconBackgroundForCategory(String category, ColorScheme scheme) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'restaurant':
      case 'meal':
        return scheme.primaryContainer;
      case 'travel':
      case 'trip':
      case 'transport':
        return scheme.tertiaryContainer;
      case 'shopping':
      case 'groceries':
        return scheme.secondaryContainer;
      case 'entertainment':
        return scheme.errorContainer;
      default:
        return scheme.surfaceContainerHighest;
    }
  }

  List<Widget> _buildExpenseFeed(
    BuildContext context,
    List<Expense> expenses,
    Map<String, String> memberNames,
  ) {
    final widgets = <Widget>[];
    int? lastMonthKey;
    for (final expense in expenses) {
      final monthKey = expense.date.year * 12 + expense.date.month;
      if (lastMonthKey != null && monthKey != lastMonthKey) {
        widgets.add(
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 2.h),
            child: Text(
              DateFormat('MMMM yyyy').format(expense.date),
              style: context.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        );
      }
      widgets.add(_buildExpenseTile(context, expense, memberNames));
      lastMonthKey = monthKey;
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
        if (state is! HomeLoaded) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final groupIndex = state.summary.groups.indexWhere((g) => g.groupId == widget.groupId);
        if (groupIndex == -1) {
          return const Scaffold(body: Center(child: Text('Group details not found.')));
        }

        final group = state.summary.groups[groupIndex];
        final colors = context.appColors;
        final heroColor = _heroColor(group.groupName);
        final heroColorDark = _heroColorDark(group.groupName);
        final memberCount = group.memberIds.length;
        final isSingleMember = memberCount <= 1;

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: _refreshData,
            child: BlocBuilder<GroupDetailCubit, GroupDetailState>(
              builder: (context, detailState) {
                final memberNameMap = detailState.memberNames;

                return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 180.h,
                    backgroundColor: heroColor,
                    elevation: 0,
                    leading: Padding(
                      padding: EdgeInsets.only(left: 8.w, top: 4.h, bottom: 4.h),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: colors.onImageColor),
                        style: IconButton.styleFrom(
                          backgroundColor: colors.overlayColor.withValues(alpha: 0.3),
                          shape: const CircleBorder(),
                        ),
                        onPressed: () => context.pop(),
                      ),
                    ),
                    actions: [
                      Padding(
                        padding: EdgeInsets.only(right: 8.w, top: 4.h, bottom: 4.h),
                        child: IconButton(
                          icon: Icon(Icons.settings_outlined, color: colors.onImageColor),
                          style: IconButton.styleFrom(
                            backgroundColor: colors.overlayColor.withValues(alpha: 0.3),
                            shape: const CircleBorder(),
                          ),
                          onPressed: () => _openSettings(context),
                        ),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      collapseMode: CollapseMode.pin,
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [heroColor, heroColorDark],
                          ),
                        ),
                        padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 16.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              group.groupName,
                              style: context.textTheme.headlineMedium?.copyWith(
                                color: colors.onImageColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (!isSingleMember) ...[
                              SizedBox(height: 8.h),
                              InkWell(
                                onTap: () => _openSettings(context),
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                                  decoration: BoxDecoration(
                                    color: colors.overlayColor.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.people_outline_rounded,
                                        size: 16.r,
                                        color: colors.onImageColor.withValues(alpha: 0.9),
                                      ),
                                      SizedBox(width: 6.w),
                                      Text(
                                        '$memberCount people',
                                        style: TextStyle(
                                          color: colors.onImageColor.withValues(alpha: 0.9),
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ];
              },
              body: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(bottom: 96.h),
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
                    child: _buildOverallStatus(context, group),
                  ),
                  if (_unsettledBalances(group).isNotEmpty)
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 0),
                      child: Builder(
                        builder: (context) {
                          final lines = _balanceBreakdown(group);
                          if (lines.length <= 2) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: lines
                                  .map((line) => Padding(
                                        padding: EdgeInsets.only(bottom: 4.h),
                                        child: Text(line),
                                      ))
                                  .toList(),
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(lines[0]),
                              SizedBox(height: 4.h),
                              Text(lines[1]),
                              SizedBox(height: 4.h),
                              Text('Plus ${lines.length - 2} other balances'),
                            ],
                          );
                        },
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildActionPill(
                            context,
                            'Settle up',
                            onTap: () => _openSettleUp(context, group),
                          ),
                          _buildActionPill(context, 'Convert to USD', icon: Icons.diamond_rounded),
                          _buildActionPill(context, 'Charts', icon: Icons.diamond_rounded),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 6.h),
                    child: Text(
                      'History',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (detailState.isLoadingExpenses)
                    const Padding(
                      padding: EdgeInsets.only(top: 32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (detailState.expenseError != null)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      child: Text(
                        detailState.expenseError!,
                        style: context.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                      ),
                    )
                  else if (detailState.expenses.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 16.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isSingleMember ? "You're the only one here!" : 'No expenses here yet.',
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            isSingleMember
                                ? 'Add group members to start splitting expenses.'
                                : 'Add an expense to get this party started.',
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: Column(
                        key: ValueKey(
                          detailState.expenses
                              .map((e) => '${e.id}:${e.date.millisecondsSinceEpoch}')
                              .join('|'),
                        ),
                        children: _buildExpenseFeed(context, detailState.expenses, memberNameMap),
                      ),
                    ),
                ],
              ),
            );
              },
            ),
          ),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FloatingActionButton(
                heroTag: 'scan_group_fab_${widget.groupId}',
                elevation: 4,
                backgroundColor: colors.elevatedSurface,
                hoverColor: colors.elevatedSurfaceHover,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Receipt scanning coming soon!')),
                  );
                },
                child: Icon(Icons.photo_camera_outlined, color: colors.onImageColor),
              ),
              SizedBox(height: 12.h),
              FloatingActionButton.extended(
                heroTag: 'add_group_expense_fab_${widget.groupId}',
                elevation: 4,
                backgroundColor: theme.colorScheme.primary,
                hoverColor: AppColors.primaryHoverDark,
                onPressed: () {
                  if (isSingleMember) {
                    _showAddExpenseDialog(context);
                  } else {
                    _openAddExpense(context);
                  }
                },
                icon: const Icon(Icons.receipt),
                label: const Text('Add expense'),
              ),
            ],
          ),
        );
      },
      ),
    );
  }
}
