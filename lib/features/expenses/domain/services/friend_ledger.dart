import '../../../../core/utils/debt_settlement.dart';
import '../../../../core/utils/group_balance_calculator.dart';
import '../entities/expense.dart';

/// A single expense's contribution to the running balance between the
/// current user and one specific friend.
///
/// [amount] is signed from the current user's perspective: positive means
/// the friend owes the current user that much *from this expense*,
/// negative means the current user owes the friend.
class FriendExpenseEntry {
  final Expense expense;
  final double amount;

  const FriendExpenseEntry({required this.expense, required this.amount});
}

/// The current user's net balance with a friend inside a single group,
/// aggregated across every expense they share in that group.
///
/// [amount] is signed the same way as [FriendExpenseEntry.amount]: positive
/// means the friend owes the current user, negative means the current user
/// owes the friend.
class FriendGroupBalance {
  final String groupId;
  final String groupName;
  final double amount;
  final String currencyCode;
  final String currencySymbol;
  final DateTime lastActivityDate;
  final int expenseCount;

  const FriendGroupBalance({
    required this.groupId,
    required this.groupName,
    required this.amount,
    this.currencyCode = 'INR',
    required this.currencySymbol,
    required this.lastActivityDate,
    required this.expenseCount,
  });
}

/// Reduces a set of (possibly multi-payer, multi-participant) group
/// expenses down to a 1:1 ledger between the current user and a single
/// friend, reusing the same [DebtSettlement] algorithm the group balance
/// calculator uses — so totals here always agree with what the group/home
/// screens show for that same pair of people.
class FriendLedger {
  FriendLedger._();

  static List<FriendExpenseEntry> build({
    required List<Expense> expenses,
    required String currentUserId,
    required String friendId,
  }) {
    final entries = <FriendExpenseEntry>[];

    for (final expense in expenses) {
      final involvedIds = {...expense.paidBy.keys, ...expense.splits.keys};
      if (!involvedIds.contains(currentUserId) || !involvedIds.contains(friendId)) {
        continue;
      }

      final netForExpense = <String, double>{
        for (final id in involvedIds)
          id: (expense.paidBy[id] ?? 0.0) - (expense.splits[id] ?? 0.0),
      };

      var amount = 0.0;
      for (final transfer in DebtSettlement.reduceToTransfers(netForExpense)) {
        if (transfer.fromUserId == currentUserId && transfer.toUserId == friendId) {
          amount -= transfer.amount;
        } else if (transfer.fromUserId == friendId && transfer.toUserId == currentUserId) {
          amount += transfer.amount;
        }
      }

      entries.add(FriendExpenseEntry(expense: expense, amount: amount));
    }

    entries.sort((a, b) => b.expense.date.compareTo(a.expense.date));
    return entries;
  }

  static double totalBalance(List<FriendExpenseEntry> entries) =>
      entries.fold(0.0, (sum, entry) => sum + entry.amount);

  /// Net between [currentUserId] and [friendId] inside one group, using that
  /// group's simplify-debts setting so friend totals match group balances.
  /// Returns one row per currency — USD and INR are never combined.
  static List<FriendGroupBalance> balancesInGroup({
    required String groupId,
    required String groupName,
    required List<Expense> expenses,
    required List<String> memberIds,
    required bool simplifyDebts,
    required String currentUserId,
    required String friendId,
  }) {
    final valid = expenses.where((expense) => !expense.isDeleted).toList();
    if (valid.isEmpty) return const [];

    final transfers = GroupBalanceCalculator.computeTransfers(
      expenses: valid,
      memberIds: memberIds,
      simplifyDebts: simplifyDebts,
    );
    final byCurrency = GroupBalanceCalculator.signedBalancesByCurrency(
      transfers: transfers,
      currentUserId: currentUserId,
      otherUserId: friendId,
    );
    if (byCurrency.isEmpty) return const [];

    final lastActivityDate = valid
        .map((expense) => expense.date)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    return byCurrency
        .map(
          (row) => FriendGroupBalance(
            groupId: groupId,
            groupName: groupName,
            amount: row.amount,
            currencyCode: row.currencyCode,
            currencySymbol: row.currencySymbol,
            lastActivityDate: lastActivityDate,
            expenseCount: valid
                .where((expense) => expense.currencyCode == row.currencyCode)
                .length,
          ),
        )
        .toList();
  }

  static FriendGroupBalance? balanceInGroup({
    required String groupId,
    required String groupName,
    required List<Expense> expenses,
    required List<String> memberIds,
    required bool simplifyDebts,
    required String currentUserId,
    required String friendId,
  }) {
    final rows = balancesInGroup(
      groupId: groupId,
      groupName: groupName,
      expenses: expenses,
      memberIds: memberIds,
      simplifyDebts: simplifyDebts,
      currentUserId: currentUserId,
      friendId: friendId,
    );
    if (rows.isEmpty) return null;
    if (rows.length == 1) return rows.first;
    return null;
  }

  /// Collapses [entries] into one row per group, the same way Splitwise's
  /// friend detail screen breaks a total balance down "for {group}". Groups
  /// that are fully settled between the pair (net ~0) are dropped.
  static List<FriendGroupBalance> groupBalances({
    required List<FriendExpenseEntry> entries,
    required Map<String, String> groupNames,
  }) {
    final byGroup = <String, List<FriendExpenseEntry>>{};
    for (final entry in entries) {
      byGroup.putIfAbsent(entry.expense.groupId, () => []).add(entry);
    }

    final balances = <FriendGroupBalance>[];
    byGroup.forEach((groupId, groupEntries) {
      final lastActivityDate = groupEntries
          .map((entry) => entry.expense.date)
          .reduce((a, b) => a.isAfter(b) ? a : b);

      final byCurrency = <String, List<FriendExpenseEntry>>{};
      for (final entry in groupEntries) {
        final code = entry.expense.currencyCode.trim().isEmpty
            ? 'INR'
            : entry.expense.currencyCode;
        byCurrency.putIfAbsent(code, () => []).add(entry);
      }

      byCurrency.forEach((code, currencyEntries) {
        final amount =
            currencyEntries.fold(0.0, (sum, entry) => sum + entry.amount);
        if (amount.abs() < 0.01) return;
        final latestEntry = currencyEntries.reduce(
          (a, b) => b.expense.date.isAfter(a.expense.date) ? b : a,
        );
        balances.add(FriendGroupBalance(
          groupId: groupId,
          groupName: groupNames[groupId] ?? 'Other',
          amount: amount,
          currencyCode: code,
          currencySymbol: latestEntry.expense.currencySymbol,
          lastActivityDate: lastActivityDate,
          expenseCount: currencyEntries.length,
        ));
      });
    });

    return balances;
  }
}
