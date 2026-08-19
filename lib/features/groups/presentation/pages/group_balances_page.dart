import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/di.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../../core/utils/currency_amount.dart';
import '../../../../core/utils/debt_settlement.dart';
import '../../../../core/utils/group_balance_calculator.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../expenses/presentation/utils/currency_conversion_action.dart';
import '../../../home/domain/entities/balance_summary.dart';
import '../../../home/domain/entities/group_summary.dart';
import '../../../home/presentation/bloc/home_bloc.dart';
import '../../../home/presentation/bloc/home_state.dart';
import '../bloc/group_detail_cubit.dart';
import 'group_settle_balances_page.dart';

class GroupBalancesPage extends StatefulWidget {
  final String groupId;

  const GroupBalancesPage({super.key, required this.groupId});

  @override
  State<GroupBalancesPage> createState() => _GroupBalancesPageState();
}

class _GroupBalancesPageState extends State<GroupBalancesPage> {
  late final GroupDetailCubit _cubit;
  final Set<String> _expandedMemberIds = {};
  String? _defaultCurrencyCode;

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDefaultCurrency());
  }

  Future<void> _loadDefaultCurrency() async {
    if (_currentUserId.isEmpty) return;
    final code = await CurrencyConversionAction.defaultCode(_currentUserId);
    if (mounted) setState(() => _defaultCurrencyCode = code);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  List<SettlementTransfer> _calculateRepayments({
    required List<Expense> expenses,
    required List<String> memberIds,
    required bool simplify,
  }) {
    return GroupBalanceCalculator.computeTransfers(
      expenses: expenses,
      memberIds: memberIds,
      simplifyDebts: simplify,
    );
  }

  void _triggerRemind(String fromName, String toName, double amount, String symbol) {
    final text = 'Hey! Just a reminder that $fromName owes $toName $symbol${amount.toStringAsFixed(2)} on Splitwise.';
    Clipboard.setData(ClipboardData(text: text));
    AppToast.show(context, 'Reminder copied to clipboard!', type: ToastType.success);
  }

  Future<void> _triggerSettleUp(
    String fromId,
    String toId,
    double amount,
    Map<String, String> memberNameMap, {
    String currencyCode = 'INR',
    String currencySymbol = '₹',
  }) async {
    final isFromMe = fromId == _currentUserId;
    final otherId = isFromMe ? toId : fromId;
    final balance = MemberBalance(
      userId: otherId,
      userName: memberNameMap[otherId] ?? otherId,
      amount: amount,
      type: isFromMe ? BalanceType.owe : BalanceType.owed,
      currencyCode: currencyCode,
      currencySymbol: currencySymbol,
    );

    final recorded = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => GroupSettleBalancesPage(
          groupId: widget.groupId,
          currentUserId: _currentUserId,
          balances: [balance],
          expenses: _cubit.state.expenses,
          defaultCurrencyCode: _defaultCurrencyCode,
        ),
      ),
    );

    if (recorded == true && mounted) {
      _cubit.loadExpenses(widget.groupId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, homeState) {
        return BlocBuilder<GroupDetailCubit, GroupDetailState>(
      bloc: _cubit,
      builder: (context, detailState) {
        if (detailState.isLoadingExpenses) {
          return Scaffold(
            appBar: AppBar(title: const Text('Balances')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (detailState.expenseError != null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Balances')),
            body: Center(child: Text(detailState.expenseError!)),
          );
        }

        final memberNameMap = detailState.memberNames;
        final expenses = detailState.expenses;

          List<String> memberIds = [];
          var simplifyDebts = true;

          if (homeState is HomeLoaded) {
            final groupIndex = homeState.summary.groups.indexWhere((g) => g.groupId == widget.groupId);
            if (groupIndex != -1) {
              final g = homeState.summary.groups[groupIndex];
              memberIds = g.memberIds;
              simplifyDebts = g.simplifyDebts;
            }
          }

          if (memberIds.isEmpty) {
            memberIds = memberNameMap.keys.toList();
          }

          final shares = expenses
              .where((e) => !e.isDeleted)
              .map((e) => ExpenseShare.fromExpense(e, memberIds: memberIds))
              .toList();
          final netsByMember = <String, List<CurrencyAmount>>{};
          final byCurrency = <String, List<ExpenseShare>>{};
          for (final share in shares) {
            final code = share.currencyCode.trim().isEmpty ? 'INR' : share.currencyCode;
            byCurrency.putIfAbsent(code, () => []).add(share);
          }
          byCurrency.forEach((code, currencyShares) {
            final symbol = currencyShares.first.currencySymbol.trim().isEmpty
                ? '₹'
                : currencyShares.first.currencySymbol;
            final nets = GroupBalanceCalculator.netByUser(
              expenses: currencyShares,
              memberIds: memberIds,
            );
            nets.forEach((memberId, net) {
              if (net.abs() <= DebtSettlement.epsilon) return;
              netsByMember.putIfAbsent(memberId, () => []).add(
                    CurrencyAmount(
                      amount: net,
                      currencyCode: code,
                      currencySymbol: symbol,
                    ),
                  );
            });
          });

          final activeTransfers = _calculateRepayments(
            expenses: expenses,
            memberIds: memberIds,
            simplify: simplifyDebts,
          );

          return Scaffold(
            appBar: AppBar(
              title: const Text('Balances'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
            ),
            body: SafeArea(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                itemCount: memberIds.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildSimplifyBanner(context, simplifyDebts);
                  }

                  final memberId = memberIds[index - 1];
                  final name = memberNameMap[memberId] ?? memberId;
                  final memberNets = MultiCurrency.sort(netsByMember[memberId] ?? const []);
                  final isExpanded = _expandedMemberIds.contains(memberId);

                  final memberTransfers = activeTransfers
                      .where((t) =>
                          t.fromUserId == memberId || t.toUserId == memberId)
                      .toList();

                  final getsBack = memberNets.where((item) => item.isOwed).toList();
                  final owes = memberNets.where((item) => item.isOwe).toList();
              
                  // Text display format
                  final Widget balanceText;
                  if (getsBack.isNotEmpty && owes.isNotEmpty) {
                    balanceText = RichText(
                      text: TextSpan(
                        style: context.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                        children: [
                          TextSpan(
                            text: name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(text: ' gets back '),
                          TextSpan(
                            text: MultiCurrency.join(getsBack),
                            style: const TextStyle(
                              color: Color(0xFF2FB285),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const TextSpan(text: ' and owes '),
                          TextSpan(
                            text: MultiCurrency.join(owes),
                            style: const TextStyle(
                              color: Color(0xFFFF8A65),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  } else if (getsBack.isNotEmpty) {
                    balanceText = RichText(
                      text: TextSpan(
                        style: context.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                        children: [
                          TextSpan(
                            text: name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(text: ' gets back '),
                          TextSpan(
                            text: MultiCurrency.join(getsBack),
                            style: const TextStyle(
                              color: Color(0xFF2FB285),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const TextSpan(text: ' in total'),
                        ],
                      ),
                    );
                  } else if (owes.isNotEmpty) {
                    balanceText = RichText(
                      text: TextSpan(
                        style: context.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                        children: [
                          TextSpan(
                            text: name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(text: ' owes '),
                          TextSpan(
                            text: MultiCurrency.join(owes),
                            style: const TextStyle(
                              color: Color(0xFFFF8A65),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const TextSpan(text: ' in total'),
                        ],
                      ),
                    );
                  } else {
                    balanceText = RichText(
                      text: TextSpan(
                        style: context.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                        children: [
                          TextSpan(
                            text: name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(text: ' is settled up'),
                        ],
                      ),
                    );
                  }
              
                  return Card(
                    margin: EdgeInsets.only(bottom: 12.h),
                    color: theme.colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                    child: Column(
                      children: [
                        // Expansion Header
                        InkWell(
                          onTap: () {
                            setState(() {
                              if (isExpanded) {
                                _expandedMemberIds.remove(memberId);
                              } else {
                                _expandedMemberIds.add(memberId);
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(12.r),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                            child: Row(
                              children: [
                                AvatarWidget(name: name, size: 44.w),
                                SizedBox(width: 16.w),
                                Expanded(child: balanceText),
                                Icon(
                                  isExpanded
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        ),
              
                        // Expansion Content
                        if (isExpanded && memberTransfers.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(left: 60.w, right: 16.w, bottom: 8.h, top: 4.h),
                            child: Column(
                              children: memberTransfers.map((transfer) {
                                final tFromName = memberNameMap[transfer.fromUserId] ?? transfer.fromUserId;
                                final tToName = memberNameMap[transfer.toUserId] ?? transfer.toUserId;
              
                                return Padding(
                                  padding: EdgeInsets.only(bottom: 12.h),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      AvatarWidget(name: tFromName, size: 32.w),
                                      SizedBox(width: 12.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            RichText(
                                              text: TextSpan(
                                                style: context.textTheme.bodyMedium?.copyWith(
                                                  color: theme.colorScheme.onSurface,
                                                  height: 1.3,
                                                ),
                                                children: [
                                                  TextSpan(
                                                    text: tFromName,
                                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                                  ),
                                                  const TextSpan(text: ' owes '),
                                                  TextSpan(
                                                    text: transfer.formattedAmount,
                                                    style: const TextStyle(
                                                      color: Color(0xFF2FB285),
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const TextSpan(text: ' to '),
                                                  TextSpan(
                                                    text: tToName,
                                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(height: 8.h),
                                            Row(
                                              children: [
                                                OutlinedButton(
                                                  onPressed: () => _triggerRemind(
                                                    tFromName,
                                                    tToName,
                                                    transfer.amount,
                                                    transfer.currencySymbol,
                                                  ),
                                                  style: OutlinedButton.styleFrom(
                                                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                                                    minimumSize: Size(0, 32.h),
                                                    side: BorderSide(color: theme.colorScheme.outline),
                                                    shape: const StadiumBorder(),
                                                  ),
                                                  child: Text(
                                                    'Remind...',
                                                    style: TextStyle(
                                                      color: theme.colorScheme.onSurface,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 12.sp,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 8.w),
                                                OutlinedButton(
                                                  onPressed: () => _triggerSettleUp(
                                                    transfer.fromUserId,
                                                    transfer.toUserId,
                                                    transfer.amount,
                                                    memberNameMap,
                                                    currencyCode: transfer.currencyCode,
                                                    currencySymbol: transfer.currencySymbol,
                                                  ),
                                                  style: OutlinedButton.styleFrom(
                                                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                                                    minimumSize: Size(0, 32.h),
                                                    side: const BorderSide(color: Color(0xFF2FB285)),
                                                    shape: const StadiumBorder(),
                                                  ),
                                                  child: Text(
                                                    'Settle up',
                                                    style: TextStyle(
                                                      color: const Color(0xFF2FB285),
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 12.sp,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
      },
    );
      },
    );
  }

  Widget _buildSimplifyBanner(BuildContext context, bool simplifyDebts) {
    final theme = context.theme;
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              simplifyDebts ? Icons.auto_fix_high_rounded : Icons.account_tree_outlined,
              size: 18.sp,
              color: theme.colorScheme.primary,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                simplifyDebts
                    ? 'Simplify debts is on. These repayments are combined so the group can settle with the fewest payments. Totals owed do not change.'
                    : 'Simplify debts is off. These are the original pairwise debts from each expense.',
                style: context.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
