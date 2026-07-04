import 'package:equatable/equatable.dart';
import '../../domain/entities/home_summary.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLoaded extends HomeState {
  final HomeSummary summary;
  final bool isOffline;

  const HomeLoaded({
    required this.summary,
    this.isOffline = false,
  });

  @override
  List<Object?> get props => [summary, isOffline];
}

class HomeRefreshing extends HomeLoaded {
  const HomeRefreshing({
    required super.summary,
    super.isOffline,
  });
}

class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}
