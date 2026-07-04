import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/bloc/base_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/watch_auth_status_usecase.dart';
import '../../domain/usecases/login_with_google_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

// Internal event to handle stream transitions safely within BLoC architecture
class _AuthStatusChanged extends AuthEvent {
  final UserEntity user;
  const _AuthStatusChanged(this.user);

  @override
  List<Object?> get props => [user];
}

@injectable
class AuthBloc extends BaseBloc<AuthEvent, AuthState> {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final WatchAuthStatusUseCase _watchAuthStatusUseCase;
  final LoginWithGoogleUseCase _loginWithGoogleUseCase;

  StreamSubscription<UserEntity>? _authStatusSubscription;

  AuthBloc(
    this._loginUseCase,
    this._registerUseCase,
    this._logoutUseCase,
    this._getCurrentUserUseCase,
    this._watchAuthStatusUseCase,
    this._loginWithGoogleUseCase,
  ) : super(const AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LoginWithEmail>(_onLoginWithEmail);
    on<RegisterWithEmail>(_onRegisterWithEmail);
    on<LogoutRequested>(_onLogoutRequested);
    on<LoginWithGoogle>(_onLoginWithGoogle);
    on<_AuthStatusChanged>(_onAuthStatusChanged);

    // Subscribe to auth status changes
    _authStatusSubscription = _watchAuthStatusUseCase().listen((user) {
      add(_AuthStatusChanged(user));
    });
  }

  Future<void> _onCheckAuthStatus(CheckAuthStatus event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await _getCurrentUserUseCase();
    
    result.isSuccess; // force evaluation or check type
    if (result.isSuccess) {
      final user = result.dataOrThrow;
      if (user.isNotEmpty) {
        emit(Authenticated(user));
      } else {
        emit(const Unauthenticated());
      }
    } else {
      emit(const Unauthenticated());
    }
  }

  Future<void> _onLoginWithEmail(LoginWithEmail event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await _loginUseCase(email: event.email, password: event.password);
    
    if (result.isSuccess) {
      emit(Authenticated(result.dataOrThrow));
    } else {
      try {
        result.dataOrThrow;
      } catch (failure) {
        final message = failure is Failure ? failure.message : failure.toString();
        emit(AuthError(message));
      }
    }
  }

  Future<void> _onRegisterWithEmail(RegisterWithEmail event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await _registerUseCase(
      name: event.name,
      email: event.email,
      password: event.password,
    );

    if (result.isSuccess) {
      emit(Authenticated(result.dataOrThrow));
    } else {
      try {
        result.dataOrThrow;
      } catch (failure) {
        final message = failure is Failure ? failure.message : failure.toString();
        emit(AuthError(message));
      }
    }
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await _logoutUseCase();
    if (result.isSuccess) {
      emit(const Unauthenticated());
    } else {
      emit(const Unauthenticated()); // Force unauthenticated state even if server logout logs warning
    }
  }

  void _onAuthStatusChanged(_AuthStatusChanged event, Emitter<AuthState> emit) {
    if (event.user.isNotEmpty) {
      emit(Authenticated(event.user));
    } else {
      emit(const Unauthenticated());
    }
  }

  Future<void> _onLoginWithGoogle(LoginWithGoogle event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await _loginWithGoogleUseCase();

    if (result.isSuccess) {
      emit(Authenticated(result.dataOrThrow));
    } else {
      try {
        result.dataOrThrow;
      } catch (failure) {
        final message = failure is Failure ? failure.message : failure.toString();
        emit(AuthError(message));
      }
    }
  }

  @override
  Future<void> close() {
    _authStatusSubscription?.cancel();
    return super.close();
  }
}
