import 'dart:async';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/result.dart';
import '../../../../shared/repositories/base_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl extends BaseRepository implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  AuthRepositoryImpl(this._remoteDataSource, this._localDataSource);

  @override
  Future<Result<UserEntity>> login({
    required String email,
    required String password,
  }) async {
    return safeCall(() async {
      final userModel = await _remoteDataSource.login(email: email, password: password);
      await _localDataSource.cacheUser(userModel);
      return userModel;
    });
  }

  @override
  Future<Result<UserEntity>> loginWithGoogle() async {
    return safeCall(() async {
      final userModel = await _remoteDataSource.loginWithGoogle();
      await _localDataSource.cacheUser(userModel);
      return userModel;
    });
  }

  @override
  Future<Result<UserEntity>> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    return safeCall(() async {
      final userModel = await _remoteDataSource.signUp(name: name, email: email, password: password);
      await _localDataSource.cacheUser(userModel);
      return userModel;
    });
  }

  @override
  Future<Result<void>> logout() async {
    return safeCall(() async {
      await _remoteDataSource.logout();
      await _localDataSource.clearCache();
    });
  }

  @override
  Future<Result<UserEntity>> getCurrentUser() async {
    return safeCall(() async {
      final remoteUser = await _remoteDataSource.getCurrentUser();
      if (remoteUser != null) {
        await _localDataSource.cacheUser(remoteUser);
        return remoteUser;
      }

      // Stale Hive session must not count as logged-in: Firestore rules
      // require Firebase Auth, so a cache-only user gets permission-denied.
      await _localDataSource.clearCache();
      return UserEntity.empty;
    });
  }

  @override
  Stream<UserEntity> watchAuthStatus() {
    return _remoteDataSource.watchAuthState().map((userModel) {
      if (userModel == null) {
        _localDataSource.clearCache();
        return UserEntity.empty;
      }
      
      _localDataSource.cacheUser(userModel);
      return userModel;
    });
  }
}
