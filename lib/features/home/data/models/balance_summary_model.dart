import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';
import '../../../../core/utils/currency_amount.dart';
import '../../domain/entities/balance_summary.dart';

part 'balance_summary_model.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class BalanceSummaryModel extends BalanceSummary {
  @override
  final double amount;
  
  @override
  @JsonKey(fromJson: _typeFromJson, toJson: _typeToJson)
  final BalanceType type;

  @override
  @JsonKey(fromJson: _amountsFromJson, toJson: _amountsToJson)
  final List<CurrencyAmount> amounts;

  const BalanceSummaryModel({
    required this.amount,
    required this.type,
    this.amounts = const [],
  }) : super(amount: amount, type: type, amounts: amounts);

  factory BalanceSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$BalanceSummaryModelFromJson(json);

  Map<String, dynamic> toJson() => _$BalanceSummaryModelToJson(this);

  @override
  String toString() => jsonEncode(toJson());

  factory BalanceSummaryModel.fromEntity(BalanceSummary entity) {
    return BalanceSummaryModel(
      amount: entity.amount,
      type: entity.type,
      amounts: entity.amounts,
    );
  }

  static BalanceType _typeFromJson(dynamic jsonVal) {
    final String val = jsonVal?.toString() ?? '';
    return BalanceType.values.firstWhere(
      (e) => e.toString() == val,
      orElse: () => BalanceType.settled,
    );
  }

  static String _typeToJson(BalanceType type) => type.toString();

  static List<CurrencyAmount> _amountsFromJson(dynamic jsonVal) {
    if (jsonVal is! List) return const [];
    return jsonVal
        .whereType<Map>()
        .map((item) => CurrencyAmount.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static List<Map<String, dynamic>> _amountsToJson(List<CurrencyAmount> amounts) {
    return amounts.map((item) => item.toJson()).toList();
  }
}
