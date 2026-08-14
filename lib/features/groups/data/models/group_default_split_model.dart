import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../expenses/domain/entities/split_type.dart';
import '../../domain/entities/group_default_split.dart';

class GroupDefaultSplitModel extends GroupDefaultSplit {
  const GroupDefaultSplitModel({
    required super.groupId,
    required super.userId,
    required super.paidByUserId,
    required super.splitType,
    required super.selectedParticipantIds,
    super.splitValueTexts,
  });

  factory GroupDefaultSplitModel.fromMap(
    String key,
    Map<String, dynamic> map,
  ) {
    final groupId = map['groupId'] as String? ?? key.split('|').first;
    final userId = map['userId'] as String? ??
        (key.contains('|') ? key.split('|').sublist(1).join('|') : '');

    final splitTypeName = map['splitType'] as String? ?? SplitType.equally.name;
    final splitType = SplitType.values.firstWhere(
      (type) => type.name == splitTypeName,
      orElse: () => SplitType.equally,
    );

    final rawParticipants = map['selectedParticipantIds'];
    final selectedParticipantIds = rawParticipants is List
        ? rawParticipants.map((e) => e.toString()).toSet()
        : <String>{};

    final rawValues = map['splitValueTexts'];
    final splitValueTexts = rawValues is Map
        ? rawValues.map((key, value) => MapEntry(key.toString(), value.toString()))
        : const <String, String>{};

    return GroupDefaultSplitModel(
      groupId: groupId,
      userId: userId,
      paidByUserId: map['paidByUserId'] as String? ?? userId,
      splitType: splitType,
      selectedParticipantIds: selectedParticipantIds,
      splitValueTexts: splitValueTexts,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'userId': userId,
      'paidByUserId': paidByUserId,
      'splitType': splitType.name,
      'selectedParticipantIds': selectedParticipantIds.toList(),
      'splitValueTexts': splitValueTexts,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory GroupDefaultSplitModel.fromEntity(GroupDefaultSplit entity) {
    return GroupDefaultSplitModel(
      groupId: entity.groupId,
      userId: entity.userId,
      paidByUserId: entity.paidByUserId,
      splitType: entity.splitType,
      selectedParticipantIds: entity.selectedParticipantIds,
      splitValueTexts: entity.splitValueTexts,
    );
  }
}
