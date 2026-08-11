import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/di.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../expenses/presentation/pages/expense_detail_page.dart';
import '../bloc/group_detail_cubit.dart';
import 'package:splitwise/features/home/presentation/bloc/home_bloc.dart';
import 'package:splitwise/features/home/presentation/bloc/home_state.dart';

class GroupCategoryExpensesPage extends StatefulWidget {
  final String groupId;
  final String category;

  const GroupCategoryExpensesPage({
    super.key,
    required this.groupId,
    required this.category,
  });

  @override
  State<GroupCategoryExpensesPage> createState() => _GroupCategoryExpensesPageState();
}

class _GroupCategoryExpensesPageState extends State<GroupCategoryExpensesPage> {
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

  Future<void> _refreshData() async {
    await _cubit.loadExpenses(widget.groupId);
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

  IconData _iconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'food & dining':
      case 'dining out':
      case 'restaurant':
      case 'meal':
        return Icons.restaurant_rounded;
      case 'travel':
      case 'trip':
      case 'transport':
      case 'auto/travel':
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
      case 'food & dining':
      case 'dining out':
      case 'restaurant':
      case 'meal':
        return scheme.primaryContainer;
      case 'travel':
      case 'trip':
      case 'transport':
      case 'auto/travel':
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

  Widget _buildExpenseTile(
    BuildContext context,
    Expense expense,
    Map<String, String> memberNames,
    String groupName,
  ) {
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
              groupName: groupName,
            ),
          ),
        );
        if (deleted == true && mounted) {
          await _refreshData();
        }
      },
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
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
                  color: isSettlement
                      ? appColors.positiveBalanceColor
                      : _iconBackgroundForCategory(expense.category, scheme),
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
          isSettlement
              ? '$payerName paid $receiverName ${expense.currencySymbol}${expense.amount.toStringAsFixed(2)}'
              : expense.title,
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
              title: Text(widget.category),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
            ),
            body: RefreshIndicator(
              onRefresh: _refreshData,
              child: BlocBuilder<GroupDetailCubit, GroupDetailState>(
                builder: (context, state) {
                  if (state.isLoadingExpenses) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.expenseError != null) {
                    return Center(child: Text(state.expenseError!));
                  }

                  // Filter expenses by category
                  final filteredExpenses = state.expenses
                      .where((e) =>
                          !e.isDeleted &&
                          e.category.toLowerCase() == widget.category.toLowerCase())
                      .toList();

                  if (filteredExpenses.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.sizeOf(context).height * 0.3),
                        Center(
                          child: Text(
                            'No expenses in this category.',
                            style: context.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    itemCount: filteredExpenses.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                    ),
                    itemBuilder: (context, index) {
                      final expense = filteredExpenses[index];
                      return _buildExpenseTile(
                        context,
                        expense,
                        state.memberNames,
                        group.groupName,
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
