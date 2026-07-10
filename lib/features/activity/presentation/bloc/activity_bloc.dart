import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/result.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/activity_page_result.dart';
import '../../../home/domain/repositories/home_repository.dart';
import '../../domain/repositories/activity_repository.dart';
import 'activity_event.dart';
import 'activity_state.dart';

class ActivityBloc extends Bloc<ActivityTimelineEvent, ActivityState> {
  final ActivityRepository _activityRepository;
  final HomeRepository _homeRepository;
  final AuthRepository _authRepository;

  ActivityBloc({
    required ActivityRepository activityRepository,
    required HomeRepository homeRepository,
    required AuthRepository authRepository,
  })  : _activityRepository = activityRepository,
        _homeRepository = homeRepository,
        _authRepository = authRepository,
        super(ActivityState.initial()) {
    on<LoadActivity>(_onLoadActivity);
    on<RefreshActivity>(_onRefreshActivity);
    on<LoadMoreActivity>(_onLoadMoreActivity);
    on<LoadAllActivity>(_onLoadAllActivity);
  }

  Future<void> _onLoadActivity(
    LoadActivity event,
    Emitter<ActivityState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    await _fetchUsersIfNeeded(emit);
    await _fetchPage(emit, refresh: true);
  }

  Future<void> _onRefreshActivity(
    RefreshActivity event,
    Emitter<ActivityState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    await _fetchUsersIfNeeded(emit);
    await _fetchPage(emit, refresh: true);
  }

  Future<void> _onLoadMoreActivity(
    LoadMoreActivity event,
    Emitter<ActivityState> emit,
  ) async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;
    emit(state.copyWith(isLoadingMore: true, error: null));
    await _fetchPage(emit, refresh: false);
  }

  Future<void> _onLoadAllActivity(
    LoadAllActivity event,
    Emitter<ActivityState> emit,
  ) async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;
    emit(state.copyWith(isLoadingMore: true, error: null));

    var hasMore = state.hasMore;
    while (hasMore && !isClosed) {
      await _fetchPage(emit, refresh: false);
      hasMore = state.hasMore;
    }

    if (!isClosed) {
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _fetchUsersIfNeeded(Emitter<ActivityState> emit) async {
    if (state.userNames.isNotEmpty) return;
    final usersResult = await _homeRepository.getAllUsers();
    if (usersResult.isSuccess) {
      final names = <String, String>{
        for (final u in usersResult.dataOrThrow) u.id: u.name,
      };
      emit(state.copyWith(userNames: names));
    }
  }

  Future<String?> _resolveCurrentUserId() async {
    final userResult = await _authRepository.getCurrentUser();
    if (!userResult.isSuccess) return null;
    final userId = userResult.dataOrThrow.id.trim();
    return userId.isEmpty ? null : userId;
  }

  Future<void> _fetchPage(Emitter<ActivityState> emit, {required bool refresh}) async {
    final userId = await _resolveCurrentUserId();
    if (userId == null) {
      emit(state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: 'Please log in again.',
      ));
      return;
    }

    final before = refresh ? null : state.cursor;
    final result = await _activityRepository.getActivityPage(
      userId: userId,
      before: before,
      limit: 20,
    );

    if (result is FailureResult<ActivityPageResult>) {
      emit(state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: result.failure.message,
      ));
      return;
    }

    final page = result.dataOrThrow;
    final merged = refresh ? page.items : [...state.items, ...page.items];
    emit(state.copyWith(
      isLoading: false,
      isLoadingMore: false,
      items: merged,
      cursor: page.nextCursor,
      hasMore: page.hasMore,
      error: null,
    ));
  }
}
