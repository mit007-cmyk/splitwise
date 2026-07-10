import 'activity_event.dart';

class ActivityPageResult {
  final List<ActivityEvent> items;
  final DateTime? nextCursor;
  final bool hasMore;

  const ActivityPageResult({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
  });
}

