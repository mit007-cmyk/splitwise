import 'package:flutter_test/flutter_test.dart';
import 'package:splitwise/core/errors/result.dart';
import 'package:splitwise/core/errors/failures.dart';
import 'package:splitwise/features/auth/domain/entities/user_entity.dart';
import 'package:splitwise/features/auth/domain/usecases/login_usecase.dart';
import 'package:splitwise/features/auth/domain/usecases/register_usecase.dart';
import 'package:splitwise/features/auth/domain/usecases/logout_usecase.dart';
import 'package:splitwise/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:splitwise/features/auth/domain/usecases/watch_auth_status_usecase.dart';
import 'package:splitwise/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:splitwise/features/auth/presentation/bloc/auth_event.dart';
import 'package:splitwise/features/auth/presentation/bloc/auth_state.dart';
import 'package:splitwise/features/auth/domain/repositories/auth_repository.dart';

// Fake implementations of repositories and use cases to test bloc states
class FakeAuthRepository implements AuthRepository {
  @override
  Future<Result<UserEntity>> login({required String email, required String password}) async {
    if (email == 'test@example.com' && password == 'password') {
      return Result.success(const UserEntity(id: '1', email: 'test@example.com', name: 'Test User'));
    }
    return Result.failure(const AuthFailure('Invalid credentials'));
  }

  @override
  Future<Result<UserEntity>> signUp({required String name, required String email, required String password}) async {
    return Result.success(UserEntity(id: '1', email: email, name: name));
  }

  @override
  Future<Result<void>> logout() async {
    return Result.success(null);
  }

  @override
  Future<Result<UserEntity>> getCurrentUser() async {
    return Result.success(UserEntity.empty);
  }

  @override
  Stream<UserEntity> watchAuthStatus() {
    return Stream.value(UserEntity.empty);
  }
}

class FakeLoginUseCase extends LoginUseCase {
  final FakeAuthRepository repo;
  FakeLoginUseCase(this.repo) : super(repo);

  @override
  Future<Result<UserEntity>> call({required String email, required String password}) {
    return repo.login(email: email, password: password);
  }
}

class FakeRegisterUseCase extends RegisterUseCase {
  final FakeAuthRepository repo;
  FakeRegisterUseCase(this.repo) : super(repo);

  @override
  Future<Result<UserEntity>> call({required String name, required String email, required String password}) {
    return repo.signUp(name: name, email: email, password: password);
  }
}

class FakeLogoutUseCase extends LogoutUseCase {
  final FakeAuthRepository repo;
  FakeLogoutUseCase(this.repo) : super(repo);

  @override
  Future<Result<void>> call() {
    return repo.logout();
  }
}

class FakeGetCurrentUserUseCase extends GetCurrentUserUseCase {
  final FakeAuthRepository repo;
  FakeGetCurrentUserUseCase(this.repo) : super(repo);

  @override
  Future<Result<UserEntity>> call() {
    return repo.getCurrentUser();
  }
}

class FakeWatchAuthStatusUseCase extends WatchAuthStatusUseCase {
  final FakeAuthRepository repo;
  FakeWatchAuthStatusUseCase(this.repo) : super(repo);

  @override
  Stream<UserEntity> call() {
    return repo.watchAuthStatus();
  }
}

void main() {
  late FakeAuthRepository repo;
  late FakeLoginUseCase loginUseCase;
  late FakeRegisterUseCase registerUseCase;
  late FakeLogoutUseCase logoutUseCase;
  late FakeGetCurrentUserUseCase getCurrentUserUseCase;
  late FakeWatchAuthStatusUseCase watchAuthStatusUseCase;
  late AuthBloc authBloc;

  setUp(() {
    repo = FakeAuthRepository();
    loginUseCase = FakeLoginUseCase(repo);
    registerUseCase = FakeRegisterUseCase(repo);
    logoutUseCase = FakeLogoutUseCase(repo);
    getCurrentUserUseCase = FakeGetCurrentUserUseCase(repo);
    watchAuthStatusUseCase = FakeWatchAuthStatusUseCase(repo);
    
    authBloc = AuthBloc(
      loginUseCase,
      registerUseCase,
      logoutUseCase,
      getCurrentUserUseCase,
      watchAuthStatusUseCase,
    );
  });

  tearDown(() {
    authBloc.close();
  });

  test('Initial state should be AuthInitial', () {
    expect(authBloc.state, const AuthInitial());
  });

  test('Emits [Unauthenticated, AuthLoading, Authenticated] when LoginWithEmail succeeds', () async {
    final expectedStates = [
      const Unauthenticated(),
      const AuthLoading(),
      const Authenticated(UserEntity(id: '1', email: 'test@example.com', name: 'Test User')),
    ];

    expectLater(authBloc.stream, emitsInOrder(expectedStates));

    authBloc.add(const LoginWithEmail(email: 'test@example.com', password: 'password'));
  });

  test('Emits [Unauthenticated, AuthLoading, AuthError] when LoginWithEmail fails', () async {
    final expectedStates = [
      const Unauthenticated(),
      const AuthLoading(),
      const AuthError('Invalid credentials'),
    ];

    expectLater(authBloc.stream, emitsInOrder(expectedStates));

    authBloc.add(const LoginWithEmail(email: 'wrong@example.com', password: 'password'));
  });
}
