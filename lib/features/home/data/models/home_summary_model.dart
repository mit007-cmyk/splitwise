import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/home_summary.dart';
import 'balance_summary_model.dart';
import 'group_summary_model.dart';

part 'home_summary_model.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class HomeSummaryModel extends HomeSummary {
  @override
  final BalanceSummaryModel overallBalance;
  @override
  final List<GroupSummaryModel> groups;

  const HomeSummaryModel({
    required this.overallBalance,
    required this.groups,
  }) : super(
          overallBalance: overallBalance,
          groups: groups,
        );

  factory HomeSummaryModel.fromJson(Map<String, dynamic> json) => _$HomeSummaryModelFromJson(json);

  Map<String, dynamic> toJson() => _$HomeSummaryModelToJson(this);

  @override
  String toString() => jsonEncode(toJson());

  factory HomeSummaryModel.fromEntity(HomeSummary entity) {
    return HomeSummaryModel(
      overallBalance: BalanceSummaryModel.fromEntity(entity.overallBalance),
      groups: entity.groups
          .map((e) => GroupSummaryModel.fromEntity(e))
          .toList(),
    );
  }
}
