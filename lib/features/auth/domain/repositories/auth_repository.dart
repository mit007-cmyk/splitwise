import '../../../../core/errors/result.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  /// Sign in user using email and password
  Future<Result<UserEntity>> login({
    required String email,
    required String password,
  });

  /// Sign in user using Google
  Future<Result<UserEntity>> loginWithGoogle();

  /// Sign up user using name, email, and password
  Future<Result<UserEntity>> signUp({
    required String name,
    required String email,
    required String password,
  });

  /// Sign out current user
  Future<Result<void>> logout();

  /// Retrieve current authenticated user session details
  Future<Result<UserEntity>> getCurrentUser();

  /// Watch real-time changes in authentication status
  Stream<UserEntity> watchAuthStatus();
}
