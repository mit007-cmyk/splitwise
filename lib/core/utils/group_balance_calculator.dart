import '../../features/expenses/domain/entities/expense.dart';
import '../../features/home/domain/entities/balance_summary.dart';
import '../../features/home/domain/entities/group_summary.dart';
import 'debt_settlement.dart';
import 'user_display_names.dart';

/// Derives pairwise balances for the current user from a group's expenses.
/// Shared by the home summary datasource and group detail header so both
/// surfaces stay consistent.
class GroupBalanceCalculator {
  GroupBalanceCalculator._();

  static List<MemberBalance> computeMemberBalances({
    required List<Expense> expenses,
    required String currentUserId,
    required Map<String, String> memberNames,
    required List<String> memberIds,
  }) {
    final netBalances = <String, double>{};

    for (final expense in expenses) {
      if (expense.isDeleted) continue;

      final owedByUser = <String, double>{};
      if (expense.splits.isNotEmpty) {
        expense.splits.forEach((id, amount) {
          final trimmed = id.trim();
          if (trimmed.isEmpty) return;
          owedByUser[trimmed] = amount;
        });
      } else if (memberIds.isNotEmpty) {
        final equalShare = expense.amount / memberIds.length;
        for (final mId in memberIds) {
          owedByUser[mId] = equalShare;
        }
      }

      final paidByUser = <String, double>{};
      expense.paidBy.forEach((id, amount) {
        final trimmed = id.trim();
        if (trimmed.isEmpty) return;
        paidByUser[trimmed] = amount;
      });

      final involvedIds = {...paidByUser.keys, ...owedByUser.keys};
      final netForExpense = <String, double>{
        for (final id in involvedIds)
          id: (paidByUser[id] ?? 0.0) - (owedByUser[id] ?? 0.0),
      };

      for (final transfer in DebtSettlement.reduceToTransfers(netForExpense)) {
        if (transfer.fromUserId == currentUserId) {
          netBalances[transfer.toUserId] =
              (netBalances[transfer.toUserId] ?? 0.0) - transfer.amount;
        } else if (transfer.toUserId == currentUserId) {
          netBalances[transfer.fromUserId] =
              (netBalances[transfer.fromUserId] ?? 0.0) + transfer.amount;
        }
      }
    }

    final memberBalances = <MemberBalance>[];
    netBalances.forEach((otherId, balance) {
      if (otherId.trim().isEmpty) return;
      if (balance.abs() > DebtSettlement.epsilon) {
        memberBalances.add(MemberBalance(
          userId: otherId,
          userName: UserDisplayNames.resolve(memberNames, otherId),
          amount: balance.abs(),
          type: balance > 0 ? BalanceType.owed : BalanceType.owe,
        ));
      }
    });

    return memberBalances;
  }
}
