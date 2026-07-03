import 'package:equatable/equatable.dart';

abstract class BaseState extends Equatable {
  const BaseState();

  @override
  List<Object?> get props => [];
}

class InitialState extends BaseState {
  const InitialState();
}

class LoadingState extends BaseState {
  const LoadingState();
}

class SuccessState<T> extends BaseState {
  final T data;

  const SuccessState(this.data);

  @override
  List<Object?> get props => [data];
}

class ErrorState extends BaseState {
  final String message;
  final String? code;

  const ErrorState({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

class EmptyState extends BaseState {
  const EmptyState();
}
