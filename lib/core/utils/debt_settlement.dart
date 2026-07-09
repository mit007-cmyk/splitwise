/// Generic ledger utility shared by any feature that needs to turn a set of
/// per-person net balances (paid - owed) into the minimal set of pairwise
/// IOUs. Used to fold multi-payer expenses into the same pairwise balance
/// model the app already uses for single-payer expenses — a single-payer
/// expense collapses to exactly the same pairwise result as before, so this
/// is a safe, backward-compatible generalization.
class DebtSettlement {
  DebtSettlement._();

  static const double epsilon = 0.01;

  static List<SettlementTransfer> reduceToTransfers(Map<String, double> netByUser) {
    final creditors = <MapEntry<String, double>>[];
    final debtors = <MapEntry<String, double>>[];

    netByUser.forEach((userId, net) {
      if (net > epsilon) {
        creditors.add(MapEntry(userId, net));
      } else if (net < -epsilon) {
        debtors.add(MapEntry(userId, -net));
      }
    });

    final transfers = <SettlementTransfer>[];
    var ci = 0;
    var di = 0;

    while (ci < creditors.length && di < debtors.length) {
      final creditor = creditors[ci];
      final debtor = debtors[di];
      final amount = creditor.value < debtor.value ? creditor.value : debtor.value;

      if (amount > epsilon) {
        transfers.add(SettlementTransfer(
          fromUserId: debtor.key,
          toUserId: creditor.key,
          amount: amount,
        ));
      }

      creditors[ci] = MapEntry(creditor.key, creditor.value - amount);
      debtors[di] = MapEntry(debtor.key, debtor.value - amount);

      if (creditors[ci].value <= epsilon) ci++;
      if (debtors[di].value <= epsilon) di++;
    }

    return transfers;
  }
}

class SettlementTransfer {
  final String fromUserId;
  final String toUserId;
  final double amount;

  const SettlementTransfer({
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
  });
}
