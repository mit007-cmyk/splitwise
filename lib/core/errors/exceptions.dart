class ServerException implements Exception {
  final String message;
  final String? code;

  const ServerException({
    required this.message,
    this.code,
  });

  @override
  String toString() => 'ServerException: $message (code: $code)';
}

class CacheException implements Exception {
  final String message;

  const CacheException({required this.message});

  @override
  String toString() => 'CacheException: $message';
}

class NetworkException implements Exception {
  final String message;

  const NetworkException({required this.message});

  @override
  String toString() => 'NetworkException: $message';
}

class AuthException implements Exception {
  final String message;
  final String? code;

  const AuthException({
    required this.message,
    this.code,
  });

  @override
  String toString() => 'AuthException: $message (code: $code)';
}

class PermissionException implements Exception {
  final String message;

  const PermissionException({required this.message});

  @override
  String toString() => 'PermissionException: $message';
}

class StorageException implements Exception {
  final String message;
  final String? code;

  const StorageException({
    required this.message,
    this.code,
  });

  @override
  String toString() => 'StorageException: $message (code: $code)';
}

class NotificationException implements Exception {
  final String message;

  const NotificationException({required this.message});

  @override
  String toString() => 'NotificationException: $message';
}

class UnknownException implements Exception {
  final String message;

  const UnknownException({required this.message});

  @override
  String toString() => 'UnknownException: $message';
}
