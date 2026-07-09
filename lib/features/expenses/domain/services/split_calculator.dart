/// Pure calculation helpers for every Splitwise-style split mode. Kept free
/// of Flutter/Firebase dependencies so it can be unit tested in isolation
/// and reused from the bloc without any UI coupling.
class SplitCalculator {
  SplitCalculator._();

  static const double epsilon = 0.01;

  static bool isCloseTo(double a, double b, [double tolerance = epsilon]) =>
      (a - b).abs() < tolerance;

  static double sumOf(Map<String, double> values) =>
      values.values.fold(0.0, (a, b) => a + b);

  /// Divides [amount] equally across [participantIds], distributing the
  /// leftover cent(s) to the first participants so the total always adds
  /// back up exactly (e.g. ₹100 / 3 => 33.34, 33.33, 33.33).
  static Map<String, double> equally(double amount, List<String> participantIds) {
    if (participantIds.isEmpty) return {};

    final totalCents = (amount * 100).round();
    final baseCents = totalCents ~/ participantIds.length;
    final remainderCents = totalCents - (baseCents * participantIds.length);

    final result = <String, double>{};
    for (var i = 0; i < participantIds.length; i++) {
      final cents = baseCents + (i < remainderCents ? 1 : 0);
      result[participantIds[i]] = cents / 100;
    }
    return result;
  }

  /// Unequally: the caller enters exact amounts directly, this just
  /// normalizes the map and reports whether it adds up to [amount].
  static bool isValidUnequally(double amount, Map<String, double> enteredAmounts) {
    return isCloseTo(sumOf(enteredAmounts), amount);
  }

  /// Converts a percentage-per-participant map into owed amounts.
  static Map<String, double> byPercentage(double amount, Map<String, double> percentages) {
    return {
      for (final entry in percentages.entries) entry.key: amount * entry.value / 100,
    };
  }

  static bool isValidPercentage(Map<String, double> percentages) {
    return isCloseTo(percentages.values.fold(0.0, (a, b) => a + b), 100, 0.1);
  }

  /// Converts a shares-per-participant map into owed amounts, proportional
  /// to each participant's share of the total shares.
  static Map<String, double> byShares(double amount, Map<String, int> shares) {
    final totalShares = shares.values.fold<int>(0, (a, b) => a + b);
    if (totalShares <= 0) {
      return {for (final id in shares.keys) id: 0.0};
    }
    return {
      for (final entry in shares.entries) entry.key: amount * entry.value / totalShares,
    };
  }

  static bool isValidShares(Map<String, int> shares) {
    return shares.values.fold<int>(0, (a, b) => a + b) > 0;
  }

  /// Splits [amount] equally among [participantIds], then nudges each
  /// participant's share by their entry in [adjustments] (defaulting to 0).
  /// The remaining (non-adjusted) base is spread equally across everyone so
  /// the total always still equals [amount].
  static Map<String, double> byAdjustment(
    double amount,
    List<String> participantIds,
    Map<String, double> adjustments,
  ) {
    if (participantIds.isEmpty) return {};

    final totalAdjustments = participantIds.fold<double>(
      0.0,
      (sum, id) => sum + (adjustments[id] ?? 0.0),
    );
    final base = (amount - totalAdjustments) / participantIds.length;

    return {
      for (final id in participantIds) id: base + (adjustments[id] ?? 0.0),
    };
  }

  /// The adjustment split is only valid if the equal base share (after
  /// subtracting adjustments) doesn't go negative.
  static bool isValidAdjustment(
    double amount,
    List<String> participantIds,
    Map<String, double> adjustments,
  ) {
    if (participantIds.isEmpty) return false;
    final totalAdjustments = participantIds.fold<double>(
      0.0,
      (sum, id) => sum + (adjustments[id] ?? 0.0),
    );
    final base = (amount - totalAdjustments) / participantIds.length;
    return base >= -epsilon;
  }
}
