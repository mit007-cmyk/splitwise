import 'failures.dart';

sealed class Result<T> {
  const Result();

  /// Utility constructor for success state
  factory Result.success(T data) = SuccessResult<T>;

  /// Utility constructor for failure state
  factory Result.failure(Failure failure) = FailureResult<T>;

  bool get isSuccess => this is SuccessResult<T>;
  bool get isFailure => this is FailureResult<T>;

  T get dataOrThrow {
    if (this is SuccessResult<T>) {
      return (this as SuccessResult<T>).data;
    }
    throw (this as FailureResult<T>).failure;
  }
}

class SuccessResult<T> extends Result<T> {
  final T data;
  const SuccessResult(this.data);
}

class FailureResult<T> extends Result<T> {
  final Failure failure;
  const FailureResult(this.failure);
}
