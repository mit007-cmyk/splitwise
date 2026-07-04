import '../../domain/entities/balance_summary.dart';

class BalanceSummaryModel extends BalanceSummary {
  const BalanceSummaryModel({
    required super.amount,
    required super.type,
  });

  factory BalanceSummaryModel.fromJson(Map<String, dynamic> json) {
    return BalanceSummaryModel(
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: BalanceType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => BalanceType.settled,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'type': type.toString(),
    };
  }

  factory BalanceSummaryModel.fromEntity(BalanceSummary entity) {
    return BalanceSummaryModel(
      amount: entity.amount,
      type: entity.type,
    );
  }
}
