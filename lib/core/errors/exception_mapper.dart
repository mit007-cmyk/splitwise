import 'package:firebase_core/firebase_core.dart';
import 'exceptions.dart';
import 'failures.dart';

class ExceptionMapper {
  static Failure map(dynamic exception) {
    if (exception is ServerException) {
      return ServerFailure(exception.message, code: exception.code);
    } else if (exception is CacheException) {
      return CacheFailure(exception.message);
    } else if (exception is NetworkException) {
      return NetworkFailure(exception.message);
    } else if (exception is AuthException) {
      return AuthFailure(exception.message, code: exception.code);
    } else if (exception is PermissionException) {
      return PermissionFailure(exception.message);
    } else if (exception is StorageException) {
      return StorageFailure(exception.message, code: exception.code);
    } else if (exception is NotificationException) {
      return NotificationFailure(exception.message);
    } else if (exception is FirebaseException) {
      // Map FirebaseExceptions specifically (Auth, Firestore, Storage)
      final message = exception.message ?? 'Firebase execution failed';
      if (exception.code == 'permission-denied') {
        return PermissionFailure(message);
      }
      return ServerFailure(message, code: exception.code);
    } else if (exception is Exception) {
      return UnknownFailure(exception.toString());
    } else {
      return UnknownFailure(exception?.toString() ?? 'An unexpected error occurred');
    }
  }
}
