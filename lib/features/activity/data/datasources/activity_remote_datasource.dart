import 'package:injectable/injectable.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/firestore_service.dart';
import '../models/activity_event_model.dart';

class ActivityPageRemoteResult {
  final List<ActivityEventModel> items;
  final DateTime? nextCursor;
  final bool hasMore;

  const ActivityPageRemoteResult({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
  });
}

abstract class ActivityRemoteDataSource {
  Future<ActivityPageRemoteResult> getActivityPage({
    required String userId,
    DateTime? before,
    int limit = 20,
  });
}

@LazySingleton(as: ActivityRemoteDataSource)
class ActivityRemoteDataSourceImpl implements ActivityRemoteDataSource {
  final FirestoreService _firestoreService;

  ActivityRemoteDataSourceImpl(this._firestoreService);

  bool _isVisibleToUser(Map<String, dynamic> map, String userId) {
    final visibility = map['visibilityUserIds'];
    if (visibility is! List) return false;
    return visibility.map((id) => id.toString()).contains(userId);
  }

  Future<List<ActivityEventModel>> _loadSplitwiseDocumentEvents(
    String userId,
  ) async {
    final doc = await _firestoreService.getDocument(
      FirestorePaths.root,
      FirestorePaths.events,
    );
    final data = doc.data();
    if (data == null) return [];

    final items = <ActivityEventModel>[];
    for (final entry in data.entries) {
      if (entry.value is! Map) continue;
      final map = Map<String, dynamic>.from(entry.value as Map);
      if (!_isVisibleToUser(map, userId)) continue;
      items.add(ActivityEventModel.fromFirestore(entry.key, map));
    }
    return items;
  }

  Future<List<ActivityEventModel>> _loadLegacyCollectionEvents(
    String userId,
  ) async {
    try {
      final snapshot = await _firestoreService.getCollection(
        FirestorePaths.events,
        queryBuilder: (query) =>
            query.where('visibilityUserIds', arrayContains: userId),
      );
      return snapshot.docs
          .map((doc) => ActivityEventModel.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<ActivityPageRemoteResult> getActivityPage({
    required String userId,
    DateTime? before,
    int limit = 20,
  }) async {
    if (userId.trim().isEmpty) {
      return const ActivityPageRemoteResult(
        items: [],
        nextCursor: null,
        hasMore: false,
      );
    }

    final byId = <String, ActivityEventModel>{};
    for (final event in await _loadSplitwiseDocumentEvents(userId)) {
      byId[event.id] = event;
    }
    for (final event in await _loadLegacyCollectionEvents(userId)) {
      byId.putIfAbsent(event.id, () => event);
    }

    var items = byId.values.toList()
      ..sort((a, b) => b.performedAt.compareTo(a.performedAt));

    if (before != null) {
      items = items
          .where((event) => event.performedAt.isBefore(before))
          .toList();
    }

    final hasMore = items.length > limit;
    if (hasMore) {
      items = items.take(limit).toList();
    }

    return ActivityPageRemoteResult(
      items: items,
      nextCursor: items.isEmpty ? null : items.last.performedAt,
      hasMore: hasMore,
    );
  }
}
