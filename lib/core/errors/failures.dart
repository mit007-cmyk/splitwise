import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  final String? code;

  const ServerFailure(super.message, {this.code});

  @override
  List<Object?> get props => [message, code];
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class AuthFailure extends Failure {
  final String? code;

  const AuthFailure(super.message, {this.code});

  @override
  List<Object?> get props => [message, code];
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

class StorageFailure extends Failure {
  final String? code;

  const StorageFailure(super.message, {this.code});

  @override
  List<Object?> get props => [message, code];
}

class NotificationFailure extends Failure {
  const NotificationFailure(super.message);
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}
