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
  final String selectedFilter;
  final bool isFabExtended;

  const HomeLoaded({
    required this.summary,
    this.isOffline = false,
    this.selectedFilter = 'all',
    this.isFabExtended = true,
  });

  HomeLoaded copyWith({
    HomeSummary? summary,
    bool? isOffline,
    String? selectedFilter,
    bool? isFabExtended,
  }) {
    return HomeLoaded(
      summary: summary ?? this.summary,
      isOffline: isOffline ?? this.isOffline,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      isFabExtended: isFabExtended ?? this.isFabExtended,
    );
  }

  @override
  List<Object?> get props => [summary, isOffline, selectedFilter, isFabExtended];
}

class HomeRefreshing extends HomeLoaded {
  const HomeRefreshing({
    required super.summary,
    super.isOffline,
    super.selectedFilter,
    super.isFabExtended,
  });
}

class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}
