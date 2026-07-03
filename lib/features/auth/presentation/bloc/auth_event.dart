import '../../../../shared/bloc/base_event.dart';

abstract class AuthEvent extends BaseEvent {
  const AuthEvent();
}

class CheckAuthStatus extends AuthEvent {
  const CheckAuthStatus();
}

class LoginWithEmail extends AuthEvent {
  final String email;
  final String password;

  const LoginWithEmail({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class RegisterWithEmail extends AuthEvent {
  final String name;
  final String email;
  final String password;

  const RegisterWithEmail({
    required this.name,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [name, email, password];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}
