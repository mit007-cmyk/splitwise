import 'package:flutter/foundation.dart';
import '../../core/errors/exception_mapper.dart';
import '../../core/errors/result.dart';

abstract class BaseRepository {
  /// Safely executes an operation, catching exceptions and mapping them to [Failure]s.
  @protected
  Future<Result<T>> safeCall<T>(Future<T> Function() action) async {
    try {
      final data = await action();
      return Result.success(data);
    } catch (e) {
      return Result.failure(ExceptionMapper.map(e));
    }
  }
}
