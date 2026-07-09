import '../../../home/domain/entities/group_summary.dart';

/// A synthetic 1:1 "non-group expenses" context, mirroring Splitwise's
/// behaviour of letting two friends split an expense directly without
/// picking (or creating) a real trip/group first.
///
/// Both members always resolve to the same deterministic group id, so every
/// direct expense between the same pair lands under one shared bucket that
/// the Friends/Friend detail balance math can pick up like any other group.
class DirectGroup {
  DirectGroup._();

  static const String type = GroupSummary.directGroupType;
  static const String defaultName = 'Non-group expenses';

  /// Deterministic id for the direct expense context between two users,
  /// independent of who initiated it.
  static String idFor(String userAId, String userBId) {
    final sorted = [userAId, userBId]..sort();
    return 'direct_${sorted[0]}_${sorted[1]}';
  }
}
