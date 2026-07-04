import '../../domain/entities/home_summary.dart';
import 'balance_summary_model.dart';
import 'group_summary_model.dart';

class HomeSummaryModel extends HomeSummary {
  const HomeSummaryModel({
    required BalanceSummaryModel super.overallBalance,
    required List<GroupSummaryModel> super.groups,
  });

  factory HomeSummaryModel.fromJson(Map<String, dynamic> json) {
    return HomeSummaryModel(
      overallBalance: BalanceSummaryModel.fromJson(
        json['overallBalance'] as Map<String, dynamic>? ?? {},
      ),
      groups: (json['groups'] as List<dynamic>?)
              ?.map((e) => GroupSummaryModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overallBalance': BalanceSummaryModel.fromEntity(overallBalance).toJson(),
      'groups': groups
          .map((e) => GroupSummaryModel.fromEntity(e).toJson())
          .toList(),
    };
  }

  factory HomeSummaryModel.fromEntity(HomeSummary entity) {
    return HomeSummaryModel(
      overallBalance: BalanceSummaryModel.fromEntity(entity.overallBalance),
      groups: entity.groups
          .map((e) => GroupSummaryModel.fromEntity(e))
          .toList(),
    );
  }
}
