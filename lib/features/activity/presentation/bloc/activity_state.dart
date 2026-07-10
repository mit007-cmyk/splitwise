import 'package:equatable/equatable.dart';
import '../../domain/entities/activity_event.dart';

class ActivityState extends Equatable {
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final List<ActivityEvent> items;
  final DateTime? cursor;
  final String? error;
  final Map<String, String> userNames;

  const ActivityState({
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.items,
    required this.cursor,
    required this.error,
    required this.userNames,
  });

  factory ActivityState.initial() {
    return const ActivityState(
      isLoading: true,
      isLoadingMore: false,
      hasMore: true,
      items: [],
      cursor: null,
      error: null,
      userNames: {},
    );
  }

  ActivityState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    List<ActivityEvent>? items,
    DateTime? cursor,
    Object? error = _unset,
    Map<String, String>? userNames,
  }) {
    return ActivityState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      items: items ?? this.items,
      cursor: cursor ?? this.cursor,
      error: identical(error, _unset) ? this.error : error as String?,
      userNames: userNames ?? this.userNames,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isLoadingMore,
        hasMore,
        items,
        cursor,
        error,
        userNames,
      ];
}

class _Unset {
  const _Unset();
}

const _unset = _Unset();

