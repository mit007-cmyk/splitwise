import 'package:injectable/injectable.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/firestore_service.dart';
import '../models/group_default_split_model.dart';

/// Firestore: `Splitwise/group_user_settings` — one entry per user+group.
/// Stores a split *template* only; expenses keep their own final split.
abstract class GroupUserSettingsRemoteDataSource {
  Future<GroupDefaultSplitModel?> getDefaultSplit({
    required String groupId,
    required String userId,
  });

  Future<void> saveDefaultSplit(GroupDefaultSplitModel split);
}

@LazySingleton(as: GroupUserSettingsRemoteDataSource)
class GroupUserSettingsRemoteDataSourceImpl
    implements GroupUserSettingsRemoteDataSource {
  final FirestoreService _firestoreService;

  GroupUserSettingsRemoteDataSourceImpl(this._firestoreService);

  String _docKey(String groupId, String userId) => '$groupId|$userId';

  @override
  Future<GroupDefaultSplitModel?> getDefaultSplit({
    required String groupId,
    required String userId,
  }) async {
    final doc = await _firestoreService.getDocument(
      FirestorePaths.root,
      FirestorePaths.groupUserSettings,
    );
    final data = doc.data();
    if (data == null) return null;

    final key = _docKey(groupId, userId);
    final raw = data[key];
    if (raw is! Map) return null;

    return GroupDefaultSplitModel.fromMap(key, Map<String, dynamic>.from(raw));
  }

  @override
  Future<void> saveDefaultSplit(GroupDefaultSplitModel split) async {
    final key = _docKey(split.groupId, split.userId);
    await _firestoreService.setDocument(
      FirestorePaths.root,
      FirestorePaths.groupUserSettings,
      {key: split.toMap()},
      merge: true,
    );
  }
}
