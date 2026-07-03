import 'package:injectable/injectable.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/hive_service.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  /// Cache authenticated user session info locally
  Future<void> cacheUser(UserModel user);

  /// Fetch cached user info from local storage
  Future<UserModel?> getCachedUser();

  /// Erase local user session data (during logouts)
  Future<void> clearCache();
}

@LazySingleton(as: AuthLocalDataSource)
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final HiveService _hiveService;
  static const String _userCacheKey = 'current_user';

  AuthLocalDataSourceImpl(this._hiveService);

  @override
  Future<void> cacheUser(UserModel user) async {
    // Save user details map to user box
    await _hiveService.put(
      AppConstants.hiveUserBox,
      _userCacheKey,
      user.toJson(),
    );
  }

  @override
  Future<UserModel?> getCachedUser() async {
    final rawData = _hiveService.get(AppConstants.hiveUserBox, _userCacheKey);
    if (rawData == null) return null;
    
    // Convert generic map to typed Map<String, dynamic> safely
    final userMap = Map<String, dynamic>.from(rawData as Map);
    return UserModel.fromJson(userMap);
  }

  @override
  Future<void> clearCache() async {
    await _hiveService.delete(AppConstants.hiveUserBox, _userCacheKey);
  }
}
