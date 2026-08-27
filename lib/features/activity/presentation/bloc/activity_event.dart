import 'package:equatable/equatable.dart';

abstract class ActivityTimelineEvent extends Equatable {
  const ActivityTimelineEvent();

  @override
  List<Object?> get props => [];
}

class LoadActivity extends ActivityTimelineEvent {
  const LoadActivity();
}

class RefreshActivity extends ActivityTimelineEvent {
  const RefreshActivity();
}

class LoadMoreActivity extends ActivityTimelineEvent {
  const LoadMoreActivity();
}

class LoadAllActivity extends ActivityTimelineEvent {
  const LoadAllActivity();
}

class MarkActivityRead extends ActivityTimelineEvent {
  const MarkActivityRead(this.eventId);

  final String eventId;

  @override
  List<Object?> get props => [eventId];
}

