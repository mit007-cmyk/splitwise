import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:splitwise/core/services/connectivity_service.dart';
import 'package:splitwise/core/services/app_logger.dart';
import 'package:splitwise/core/errors/result.dart';
import 'package:splitwise/features/auth/domain/entities/user_entity.dart';
import 'package:splitwise/features/auth/domain/repositories/auth_repository.dart';
import 'package:splitwise/features/auth/domain/usecases/login_usecase.dart';
import 'package:splitwise/features/auth/domain/usecases/register_usecase.dart';
import 'package:splitwise/features/auth/domain/usecases/logout_usecase.dart';
import 'package:splitwise/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:splitwise/features/auth/domain/usecases/watch_auth_status_usecase.dart';
import 'package:splitwise/features/auth/domain/usecases/login_with_google_usecase.dart';
import 'package:splitwise/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:splitwise/main.dart';

class MockLogger extends AppLogger {
  @override
  void d(String message) {}
  @override
  void i(String message) {}
  @override
  void w(String message) {}
  @override
  void e(String message, [dynamic error, StackTrace? stackTrace]) {}
}

class MockConnectivity extends ConnectivityService {
  MockConnectivity() : super(MockLogger());

  @override
  Stream<bool> get onConnectionChanged => Stream.value(true);

  @override
  Future<bool> get isConnected => Future.value(true);
}

class MockAuthRepository implements AuthRepository {
  @override
  Future<Result<UserEntity>> getCurrentUser() async => Result.success(UserEntity.empty);

  @override
  Future<Result<UserEntity>> login({required String email, required String password}) async =>
      Result.success(UserEntity.empty);

  @override
  Future<Result<UserEntity>> signUp({required String name, required String email, required String password}) async =>
      Result.success(UserEntity.empty);

  @override
  Future<Result<void>> logout() async => Result.success(null);

  @override
  Future<Result<UserEntity>> loginWithGoogle() async => Result.success(UserEntity.empty);

  @override
  Stream<UserEntity> watchAuthStatus() => Stream.value(UserEntity.empty);
}

void main() {
  setUpAll(() {
    final getIt = GetIt.instance;
    if (!getIt.isRegistered<AppLogger>()) {
      getIt.registerSingleton<AppLogger>(MockLogger());
    }
    if (!getIt.isRegistered<ConnectivityService>()) {
      getIt.registerSingleton<ConnectivityService>(MockConnectivity());
    }
    if (!getIt.isRegistered<AuthRepository>()) {
      final authRepo = MockAuthRepository();
      getIt.registerSingleton<AuthRepository>(authRepo);
      
      final loginUseCase = LoginUseCase(authRepo);
      final registerUseCase = RegisterUseCase(authRepo);
      final logoutUseCase = LogoutUseCase(authRepo);
      final getCurrentUserUseCase = GetCurrentUserUseCase(authRepo);
      final watchAuthStatusUseCase = WatchAuthStatusUseCase(authRepo);
      final loginWithGoogleUseCase = LoginWithGoogleUseCase(authRepo);
      
      getIt.registerSingleton<AuthBloc>(AuthBloc(
        loginUseCase,
        registerUseCase,
        logoutUseCase,
        getCurrentUserUseCase,
        watchAuthStatusUseCase,
        loginWithGoogleUseCase,
      ));
    }
  });

  testWidgets('App boots and redirects to login screen successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Settle GoRouter navigation redirects completely
    await tester.pumpAndSettle();

    // Verify that we successfully land on the LoginPage
    expect(find.text('Sign In'), findsOneWidget);
  });
}
