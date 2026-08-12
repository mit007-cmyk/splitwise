import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/di.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../../core/utils/debt_settlement.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../expenses/domain/entities/expense.dart';
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
  bool _isSimplifyDebtsEnabled = false;

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

  Color _avatarColorForName(String name) {
    final hash = name.codeUnits.fold(0, (prev, elem) => prev + elem);
    final list = [
      const Color(0xFFE57373),
      const Color(0xFFF06292),
      const Color(0xFFBA68C8),
      const Color(0xFF9575CD),
      const Color(0xFF7986CB),
      const Color(0xFF64B5F6),
      const Color(0xFF4FC3F7),
      const Color(0xFF4DD0E1),
      const Color(0xFF4DB6AC),
      const Color(0xFF81C784),
      const Color(0xFFAED581),
      const Color(0xFFFFD54F),
      const Color(0xFFFFB74D),
      const Color(0xFFFF8A65),
    ];
    return list[hash % list.length];
  }

  List<SettlementTransfer> _calculateRepayments({
    required List<Expense> expenses,
    required List<String> memberIds,
    required bool simplify,
  }) {
    final validExpenses = expenses.where((e) => !e.isDeleted).toList();

    // 1. Calculate overall net balance for each member
    final netByUser = <String, double>{
      for (final mId in memberIds) mId: 0.0,
    };

    for (final exp in validExpenses) {
      final owedByUser = <String, double>{};
      if (exp.splits.isNotEmpty) {
        exp.splits.forEach((id, val) => owedByUser[id] = val);
      } else {
        final equal = exp.amount / memberIds.length;
        for (final id in memberIds) {
          owedByUser[id] = equal;
        }
      }
      final paidByUser = exp.paidBy;
      final involved = {...paidByUser.keys, ...owedByUser.keys};

      for (final id in involved) {
        final net = (paidByUser[id] ?? 0.0) - (owedByUser[id] ?? 0.0);
        netByUser[id] = (netByUser[id] ?? 0.0) + net;
      }
    }

    if (simplify) {
      return DebtSettlement.reduceToTransfers(netByUser);
    } else {
      // Aggregate pairwise transfers of each expense
      final aggregated = <String, Map<String, double>>{}; // fromUserId -> {toUserId -> amount}
      for (final exp in validExpenses) {
        final owedByUser = <String, double>{};
        if (exp.splits.isNotEmpty) {
          exp.splits.forEach((id, val) => owedByUser[id] = val);
        } else {
          final equal = exp.amount / memberIds.length;
          for (final id in memberIds) {
            owedByUser[id] = equal;
          }
        }
        final paidByUser = exp.paidBy;
        final involved = {...paidByUser.keys, ...owedByUser.keys};
        final netForExpense = <String, double>{
          for (final id in involved)
            id: (paidByUser[id] ?? 0.0) - (owedByUser[id] ?? 0.0),
        };
        final transfers = DebtSettlement.reduceToTransfers(netForExpense);
        for (final t in transfers) {
          final from = t.fromUserId;
          final to = t.toUserId;
          aggregated.putIfAbsent(from, () => {})[to] =
              (aggregated[from]?[to] ?? 0.0) + t.amount;
        }
      }

      final List<SettlementTransfer> result = [];
      aggregated.forEach((from, toMap) {
        toMap.forEach((to, amount) {
          if (amount > 0.01) {
            result.add(SettlementTransfer(fromUserId: from, toUserId: to, amount: amount));
          }
        });
      });
      return result;
    }
  }

  void _triggerRemind(String fromName, String toName, double amount) {
    final text = 'Hey! Just a reminder that $fromName owes $toName ₹${amount.toStringAsFixed(2)} on Splitwise.';
    Clipboard.setData(ClipboardData(text: text));
    AppToast.show(context, 'Reminder copied to clipboard!', type: ToastType.success);
  }

  Future<void> _triggerSettleUp(String fromId, String toId, double amount, Map<String, String> memberNameMap) async {
    final isFromMe = fromId == _currentUserId;
    final otherId = isFromMe ? toId : fromId;
    final balance = MemberBalance(
      userId: otherId,
      userName: memberNameMap[otherId] ?? otherId,
      amount: amount,
      type: isFromMe ? BalanceType.owe : BalanceType.owed,
    );

    final recorded = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => GroupSettleBalancesPage(
          groupId: widget.groupId,
          currentUserId: _currentUserId,
          balances: [balance],
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

          // Find current group info
          List<String> memberIds = [];

          final homeState = context.read<HomeBloc>().state;
          if (homeState is HomeLoaded) {
            final groupIndex = homeState.summary.groups.indexWhere((g) => g.groupId == widget.groupId);
            if (groupIndex != -1) {
              final g = homeState.summary.groups[groupIndex];
              memberIds = g.memberIds;
            }
          }

          if (memberIds.isEmpty) {
            memberIds = memberNameMap.keys.toList();
          }

          // Calculate dynamic overall net balance for each user
          final netBalances = <String, double>{
            for (final mId in memberIds) mId: 0.0,
          };
          for (final exp in expenses.where((e) => !e.isDeleted)) {
            final owedByUser = <String, double>{};
            if (exp.splits.isNotEmpty) {
              exp.splits.forEach((id, val) => owedByUser[id] = val);
            } else {
              final equal = exp.amount / memberIds.length;
              for (final id in memberIds) {
                owedByUser[id] = equal;
              }
            }
            final paidByUser = exp.paidBy;
            final involved = {...paidByUser.keys, ...owedByUser.keys};

            for (final id in involved) {
              final net = (paidByUser[id] ?? 0.0) - (owedByUser[id] ?? 0.0);
              netBalances[id] = (netBalances[id] ?? 0.0) + net;
            }
          }

          // Calculate simplified vs non-simplified counts
          final simplifiedTransfers = _calculateRepayments(
            expenses: expenses,
            memberIds: memberIds,
            simplify: true,
          );
          final nonSimplifiedTransfers = _calculateRepayments(
            expenses: expenses,
            memberIds: memberIds,
            simplify: false,
          );

          final activeTransfers = _calculateRepayments(
            expenses: expenses,
            memberIds: memberIds,
            simplify: _isSimplifyDebtsEnabled,
          );

          final int savedCount = math.max(3, nonSimplifiedTransfers.length - simplifiedTransfers.length);

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
                itemCount: memberIds.length,
                itemBuilder: (context, index) {
                  final memberId = memberIds[index];
                  final name = memberNameMap[memberId] ?? memberId;
                  final net = netBalances[memberId] ?? 0.0;
                  final isExpanded = _expandedMemberIds.contains(memberId);
              
                  // Filters transfers related to this member
                  final List<SettlementTransfer> memberTransfers = [];
                  if (net > 0.01) {
                    memberTransfers.addAll(activeTransfers.where((t) => t.toUserId == memberId));
                  } else if (net < -0.01) {
                    memberTransfers.addAll(activeTransfers.where((t) => t.fromUserId == memberId));
                  }
              
                  // Text display format
                  final Widget balanceText;
                  if (net > 0.01) {
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
                            text: '₹${net.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Color(0xFF2FB285),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const TextSpan(text: ' in total'),
                        ],
                      ),
                    );
                  } else if (net < -0.01) {
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
                            text: '₹${net.abs().toStringAsFixed(2)}',
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
                                CircleAvatar(
                                  radius: 22.r,
                                  backgroundColor: _avatarColorForName(name),
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : '',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
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
                                      CircleAvatar(
                                        radius: 16.r,
                                        backgroundColor: _avatarColorForName(tFromName),
                                        child: Text(
                                          tFromName.isNotEmpty ? tFromName[0].toUpperCase() : '',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
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
                                                    text: '₹${transfer.amount.toStringAsFixed(2)}',
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
                                                  onPressed: () => _triggerRemind(tFromName, tToName, transfer.amount),
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
  }
}
