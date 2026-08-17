import '../../features/expenses/domain/entities/expense.dart';
import '../../features/home/domain/entities/balance_summary.dart';
import '../../features/home/domain/entities/group_summary.dart';
import 'debt_settlement.dart';
import 'user_display_names.dart';

/// Paid vs owed amounts for a single expense, used by the group debt graph.
class ExpenseShare {
  final Map<String, double> paidBy;
  final Map<String, double> owedBy;
  final String currencyCode;
  final String currencySymbol;

  const ExpenseShare({
    required this.paidBy,
    required this.owedBy,
    this.currencyCode = 'INR',
    this.currencySymbol = '₹',
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
      currencyCode: expense.currencyCode,
      currencySymbol: expense.currencySymbol,
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
    final byCurrency = <String, List<ExpenseShare>>{};
    for (final expense in expenses) {
      final code = expense.currencyCode.trim().isEmpty ? 'INR' : expense.currencyCode;
      byCurrency.putIfAbsent(code, () => []).add(expense);
    }

    final transfers = <SettlementTransfer>[];
    byCurrency.forEach((code, shares) {
      final symbol = shares.first.currencySymbol.trim().isEmpty
          ? '₹'
          : shares.first.currencySymbol;
      final inner = simplifyDebts
          ? DebtSettlement.reduceToTransfers(
              netByUser(expenses: shares, memberIds: memberIds),
            )
          : _pairwiseTransfers(shares, memberIds);
      transfers.addAll(
        inner.map(
          (transfer) => transfer.withCurrency(
            currencyCode: code,
            currencySymbol: symbol,
          ),
        ),
      );
    });
    return transfers;
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
    final netBalances = <String, Map<String, double>>{};
    final currencyMeta = <String, ({String code, String symbol})>{};

    for (final transfer in transfers) {
      if (excludedUserIds.contains(transfer.fromUserId) ||
          excludedUserIds.contains(transfer.toUserId)) {
        continue;
      }
      final code = transfer.currencyCode.trim().isEmpty ? 'INR' : transfer.currencyCode;
      currencyMeta[code] = (
        code: code,
        symbol: transfer.currencySymbol.trim().isEmpty ? '₹' : transfer.currencySymbol,
      );
      double signedFor(String otherId) {
        if (transfer.fromUserId == currentUserId && transfer.toUserId == otherId) {
          return -transfer.amount;
        }
        if (transfer.toUserId == currentUserId && transfer.fromUserId == otherId) {
          return transfer.amount;
        }
        return 0.0;
      }

      void add(String otherId, double delta) {
        if (otherId.trim().isEmpty || delta.abs() <= 0) return;
        netBalances.putIfAbsent(otherId, () => {});
        netBalances[otherId]![code] = (netBalances[otherId]![code] ?? 0.0) + delta;
      }

      if (transfer.fromUserId == currentUserId) {
        add(transfer.toUserId, signedFor(transfer.toUserId));
      } else if (transfer.toUserId == currentUserId) {
        add(transfer.fromUserId, signedFor(transfer.fromUserId));
      }
    }

    final memberBalances = <MemberBalance>[];
    netBalances.forEach((otherId, byCurrency) {
      if (otherId.trim().isEmpty) return;
      if (excludedUserIds.contains(otherId)) return;
      byCurrency.forEach((code, balance) {
        if (balance.abs() <= DebtSettlement.epsilon) return;
        final meta = currencyMeta[code];
        memberBalances.add(MemberBalance(
          userId: otherId,
          userName: UserDisplayNames.resolve(memberNames, otherId),
          amount: balance.abs(),
          type: balance > 0 ? BalanceType.owed : BalanceType.owe,
          currencyCode: meta?.code ?? code,
          currencySymbol: meta?.symbol ?? '₹',
        ));
      });
    });

    return memberBalances;
  }

  /// Signed from [currentUserId]'s perspective: positive = [otherUserId] owes
  /// the current user, negative = current user owes them.
  static double signedBalanceBetween({
    required List<SettlementTransfer> transfers,
    required String currentUserId,
    required String otherUserId,
    String? currencyCode,
  }) {
    var amount = 0.0;
    for (final transfer in transfers) {
      if (currencyCode != null &&
          currencyCode.isNotEmpty &&
          transfer.currencyCode != currencyCode) {
        continue;
      }
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

  static List<({double amount, String currencyCode, String currencySymbol})>
      signedBalancesByCurrency({
    required List<SettlementTransfer> transfers,
    required String currentUserId,
    required String otherUserId,
  }) {
    final byCode = <String, ({double amount, String symbol})>{};
    for (final transfer in transfers) {
      final code = transfer.currencyCode.trim().isEmpty ? 'INR' : transfer.currencyCode;
      var delta = 0.0;
      if (transfer.fromUserId == currentUserId &&
          transfer.toUserId == otherUserId) {
        delta = -transfer.amount;
      } else if (transfer.fromUserId == otherUserId &&
          transfer.toUserId == currentUserId) {
        delta = transfer.amount;
      } else {
        continue;
      }
      final existing = byCode[code];
      byCode[code] = (
        amount: (existing?.amount ?? 0.0) + delta,
        symbol: transfer.currencySymbol.trim().isEmpty ? '₹' : transfer.currencySymbol,
      );
    }
    return byCode.entries
        .where((entry) => entry.value.amount.abs() > DebtSettlement.epsilon)
        .map(
          (entry) => (
            amount: entry.value.amount,
            currencyCode: entry.key,
            currencySymbol: entry.value.symbol,
          ),
        )
        .toList();
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
