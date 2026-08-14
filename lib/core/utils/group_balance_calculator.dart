import '../../features/expenses/domain/entities/expense.dart';
import '../../features/home/domain/entities/balance_summary.dart';
import '../../features/home/domain/entities/group_summary.dart';
import 'debt_settlement.dart';
import 'user_display_names.dart';

/// Paid vs owed amounts for a single expense, used by the group debt graph.
class ExpenseShare {
  final Map<String, double> paidBy;
  final Map<String, double> owedBy;

  const ExpenseShare({
    required this.paidBy,
    required this.owedBy,
  });

  factory ExpenseShare.fromExpense(
    Expense expense, {
    required List<String> memberIds,
  }) {
    return ExpenseShare(
      paidBy: Map<String, double>.from(expense.paidBy),
      owedBy: _owedBy(
        splits: expense.splits,
        amount: expense.amount,
        memberIds: memberIds,
      ),
    );
  }
}

Map<String, double> _owedBy({
  required Map<String, double> splits,
  required double amount,
  required List<String> memberIds,
}) {
  if (splits.isNotEmpty) {
    final owed = <String, double>{};
    splits.forEach((id, value) {
      final trimmed = id.trim();
      if (trimmed.isEmpty) return;
      owed[trimmed] = value;
    });
    return owed;
  }
  if (memberIds.isEmpty) return const {};
  final equalShare = amount / memberIds.length;
  return {for (final id in memberIds) id: equalShare};
}

/// Derives pairwise or simplified group debts from expenses.
///
/// **Simplify on** (Splitwise default): collapse everyone's net (paid − owed)
/// into the fewest repayments that settle the group.
///
/// **Simplify off**: keep the original pairwise IOUs from each expense
/// (still netting A↔B in both directions). Totals owed never change —
/// only who pays whom.
class GroupBalanceCalculator {
  GroupBalanceCalculator._();

  static Map<String, double> netByUser({
    required List<ExpenseShare> expenses,
    required List<String> memberIds,
  }) {
    final net = <String, double>{
      for (final id in memberIds) id: 0.0,
    };

    for (final expense in expenses) {
      final involved = {...expense.paidBy.keys, ...expense.owedBy.keys};
      for (final id in involved) {
        net[id] = (net[id] ?? 0.0) +
            (expense.paidBy[id] ?? 0.0) -
            (expense.owedBy[id] ?? 0.0);
      }
    }

    return net;
  }

  static List<SettlementTransfer> computeTransfersFromShares({
    required List<ExpenseShare> expenses,
    required List<String> memberIds,
    required bool simplifyDebts,
  }) {
    if (simplifyDebts) {
      return DebtSettlement.reduceToTransfers(
        netByUser(expenses: expenses, memberIds: memberIds),
      );
    }
    return _pairwiseTransfers(expenses, memberIds);
  }

  static List<SettlementTransfer> computeTransfers({
    required List<Expense> expenses,
    required List<String> memberIds,
    required bool simplifyDebts,
  }) {
    final shares = expenses
        .where((expense) => !expense.isDeleted)
        .map((expense) => ExpenseShare.fromExpense(expense, memberIds: memberIds))
        .toList();
    return computeTransfersFromShares(
      expenses: shares,
      memberIds: memberIds,
      simplifyDebts: simplifyDebts,
    );
  }

  static List<MemberBalance> computeMemberBalances({
    required List<Expense> expenses,
    required String currentUserId,
    required Map<String, String> memberNames,
    required List<String> memberIds,
    bool simplifyDebts = true,
  }) {
    final transfers = computeTransfers(
      expenses: expenses,
      memberIds: memberIds,
      simplifyDebts: simplifyDebts,
    );
    return memberBalancesFromTransfers(
      transfers: transfers,
      currentUserId: currentUserId,
      memberNames: memberNames,
    );
  }

  static List<MemberBalance> memberBalancesFromTransfers({
    required List<SettlementTransfer> transfers,
    required String currentUserId,
    required Map<String, String> memberNames,
    Set<String> excludedUserIds = const {},
  }) {
    final netBalances = <String, double>{};

    for (final transfer in transfers) {
      if (excludedUserIds.contains(transfer.fromUserId) ||
          excludedUserIds.contains(transfer.toUserId)) {
        continue;
      }
      if (transfer.fromUserId == currentUserId) {
        netBalances[transfer.toUserId] =
            (netBalances[transfer.toUserId] ?? 0.0) - transfer.amount;
      } else if (transfer.toUserId == currentUserId) {
        netBalances[transfer.fromUserId] =
            (netBalances[transfer.fromUserId] ?? 0.0) + transfer.amount;
      }
    }

    final memberBalances = <MemberBalance>[];
    netBalances.forEach((otherId, balance) {
      if (otherId.trim().isEmpty) return;
      if (excludedUserIds.contains(otherId)) return;
      if (balance.abs() <= DebtSettlement.epsilon) return;
      memberBalances.add(MemberBalance(
        userId: otherId,
        userName: UserDisplayNames.resolve(memberNames, otherId),
        amount: balance.abs(),
        type: balance > 0 ? BalanceType.owed : BalanceType.owe,
      ));
    });

    return memberBalances;
  }

  /// Signed from [currentUserId]'s perspective: positive = [otherUserId] owes
  /// the current user, negative = current user owes them.
  static double signedBalanceBetween({
    required List<SettlementTransfer> transfers,
    required String currentUserId,
    required String otherUserId,
  }) {
    var amount = 0.0;
    for (final transfer in transfers) {
      if (transfer.fromUserId == currentUserId &&
          transfer.toUserId == otherUserId) {
        amount -= transfer.amount;
      } else if (transfer.fromUserId == otherUserId &&
          transfer.toUserId == currentUserId) {
        amount += transfer.amount;
      }
    }
    return amount;
  }

  static List<SettlementTransfer> _pairwiseTransfers(
    List<ExpenseShare> expenses,
    List<String> memberIds,
  ) {
    final aggregated = <String, Map<String, double>>{};

    for (final expense in expenses) {
      final involved = {...expense.paidBy.keys, ...expense.owedBy.keys};
      if (involved.isEmpty && memberIds.isNotEmpty) {
        continue;
      }
      final netForExpense = <String, double>{
        for (final id in involved)
          id: (expense.paidBy[id] ?? 0.0) - (expense.owedBy[id] ?? 0.0),
      };
      for (final transfer in DebtSettlement.reduceToTransfers(netForExpense)) {
        _addPairwise(
          aggregated,
          transfer.fromUserId,
          transfer.toUserId,
          transfer.amount,
        );
      }
    }

    final result = <SettlementTransfer>[];
    aggregated.forEach((from, toMap) {
      toMap.forEach((to, amount) {
        if (amount > DebtSettlement.epsilon) {
          result.add(SettlementTransfer(
            fromUserId: from,
            toUserId: to,
            amount: amount,
          ));
        }
      });
    });
    return result;
  }

  static void _addPairwise(
    Map<String, Map<String, double>> aggregated,
    String from,
    String to,
    double amount,
  ) {
    if (from == to || amount <= DebtSettlement.epsilon) return;

    final reverse = aggregated[to]?[from] ?? 0.0;
    if (reverse > DebtSettlement.epsilon) {
      if (reverse >= amount) {
        final leftover = reverse - amount;
        if (leftover > DebtSettlement.epsilon) {
          aggregated[to]![from] = leftover;
        } else {
          aggregated[to]!.remove(from);
        }
        return;
      }
      aggregated[to]!.remove(from);
      amount -= reverse;
    }

    aggregated.putIfAbsent(from, () => {});
    aggregated[from]![to] = (aggregated[from]![to] ?? 0.0) + amount;
  }
}
