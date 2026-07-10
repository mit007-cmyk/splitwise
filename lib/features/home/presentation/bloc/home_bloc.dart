import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../domain/repositories/home_repository.dart';
import '../../domain/entities/home_summary.dart';
import '../../../../core/errors/result.dart';
import 'home_event.dart';
import 'home_state.dart';

@injectable
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository _homeRepository;
  final AuthRepository _authRepository;
  final ConnectivityService _connectivityService;

  HomeBloc(
    this._homeRepository,
    this._authRepository,
    this._connectivityService,
  ) : super(const HomeInitial()) {
    on<LoadHome>(_onLoadHome);
    on<RefreshHome>(_onRefreshHome);
    on<CreateGroupRequested>(_onCreateGroupRequested);
    on<AddContactRequested>(_onAddContactRequested);
    on<AddGroupMembersRequested>(_onAddGroupMembersRequested);
    on<EditGroupRequested>(_onEditGroupRequested);
    on<LeaveGroupRequested>(_onLeaveGroupRequested);
    on<DeleteGroupRequested>(_onDeleteGroupRequested);
    on<RemoveGroupMemberRequested>(_onRemoveGroupMemberRequested);
    on<ChangeFilter>(_onChangeFilter);
    on<ChangeFabExtension>(_onChangeFabExtension);
  }

  Future<void> _onLoadHome(LoadHome event, Emitter<HomeState> emit) async {
    emit(const HomeLoading());
    await _fetchHomeSummary(emit, forceRefresh: false);
  }

  /// Refreshes the home summary and waits until the fetch completes.
  Future<void> refreshAndWait() {
    final completer = Completer<void>();
    add(RefreshHome(completer: completer));
    return completer.future;
  }

  Future<void> _onRefreshHome(RefreshHome event, Emitter<HomeState> emit) async {
    try {
      if (state is HomeLoaded) {
        emit(HomeRefreshing(
          summary: (state as HomeLoaded).summary,
          isOffline: (state as HomeLoaded).isOffline,
        ));
      } else {
        emit(const HomeLoading());
      }
      await _fetchHomeSummary(emit, forceRefresh: true);
    } finally {
      event.completer?.complete();
    }
  }

  Future<void> _onCreateGroupRequested(
    CreateGroupRequested event,
    Emitter<HomeState> emit,
  ) async {
    final userResult = await _authRepository.getCurrentUser();
    if (!userResult.isSuccess || userResult.dataOrThrow.id.isEmpty) {
      emit(const HomeError('User session not found. Please log in again.'));
      return;
    }

    final userId = userResult.dataOrThrow.id;
    final userName = userResult.dataOrThrow.name.isNotEmpty
        ? userResult.dataOrThrow.name
        : userResult.dataOrThrow.email.split('@')[0];

    emit(const HomeLoading());

    final createResult = await _homeRepository.createGroup(
      userId: userId,
      userName: userName,
      name: event.name,
      type: event.type,
    );

    if (createResult is SuccessResult<void>) {
      await _fetchHomeSummary(emit, forceRefresh: true);
    } else if (createResult is FailureResult<void>) {
      emit(HomeError(createResult.failure.message));
    } else {
      emit(const HomeError('Failed to create group.'));
    }
  }

  Future<void> _onAddContactRequested(
    AddContactRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(const HomeLoading());
    final result = await _homeRepository.addContact(
      name: event.name,
      phone: event.phone,
      email: event.email,
    );

    if (result is SuccessResult<void>) {
      await _fetchHomeSummary(emit, forceRefresh: true);
    } else if (result is FailureResult<void>) {
      emit(HomeError(result.failure.message));
    }
  }

  Future<void> _onAddGroupMembersRequested(
    AddGroupMembersRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(const HomeLoading());
    final result = await _homeRepository.addGroupMembers(
      groupId: event.groupId,
      memberIds: event.memberIds,
    );

    if (result is SuccessResult<void>) {
      await _fetchHomeSummary(emit, forceRefresh: true);
    } else if (result is FailureResult<void>) {
      emit(HomeError(result.failure.message));
    }
  }

  Future<void> _onEditGroupRequested(
    EditGroupRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(const HomeLoading());
    final result = await _homeRepository.editGroup(
      groupId: event.groupId,
      name: event.name,
      type: event.type,
    );

    if (result is SuccessResult<void>) {
      await _fetchHomeSummary(emit, forceRefresh: true);
    } else if (result is FailureResult<void>) {
      emit(HomeError(result.failure.message));
    }
  }

  Future<void> _onLeaveGroupRequested(
    LeaveGroupRequested event,
    Emitter<HomeState> emit,
  ) async {
    final userResult = await _authRepository.getCurrentUser();
    if (!userResult.isSuccess || userResult.dataOrThrow.id.isEmpty) {
      emit(const HomeError('User session not found. Please log in again.'));
      return;
    }

    final userId = userResult.dataOrThrow.id;
    emit(const HomeLoading());

    final result = await _homeRepository.leaveGroup(
      groupId: event.groupId,
      userId: userId,
    );

    if (result is SuccessResult<void>) {
      await _fetchHomeSummary(emit, forceRefresh: true);
    } else if (result is FailureResult<void>) {
      emit(HomeError(result.failure.message));
    }
  }

  Future<void> _onDeleteGroupRequested(
    DeleteGroupRequested event,
    Emitter<HomeState> emit,
  ) async {
    final userResult = await _authRepository.getCurrentUser();
    if (!userResult.isSuccess || userResult.dataOrThrow.id.isEmpty) {
      emit(const HomeError('User session not found. Please log in again.'));
      return;
    }

    final userId = userResult.dataOrThrow.id;
    emit(const HomeLoading());

    final result = await _homeRepository.deleteGroup(
      groupId: event.groupId,
      userId: userId,
    );

    if (result is SuccessResult<void>) {
      await _fetchHomeSummary(emit, forceRefresh: true);
    } else if (result is FailureResult<void>) {
      emit(HomeError(result.failure.message));
    }
  }

  Future<void> _onRemoveGroupMemberRequested(
    RemoveGroupMemberRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(const HomeLoading());

    final result = await _homeRepository.leaveGroup(
      groupId: event.groupId,
      userId: event.memberId,
    );

    if (result is SuccessResult<void>) {
      await _fetchHomeSummary(emit, forceRefresh: true);
    } else if (result is FailureResult<void>) {
      emit(HomeError(result.failure.message));
    }
  }

  Future<void> _fetchHomeSummary(Emitter<HomeState> emit, {required bool forceRefresh}) async {
    final userResult = await _authRepository.getCurrentUser();
    if (!userResult.isSuccess || userResult.dataOrThrow.id.isEmpty) {
      emit(const HomeError('User session not found. Please log in again.'));
      return;
    }

    final userId = userResult.dataOrThrow.id;
    final isOnline = await _connectivityService.isConnected;
    final summaryResult = await _homeRepository.getHomeSummary(
      userId: userId,
      forceRefresh: forceRefresh,
    );

    if (summaryResult is SuccessResult<HomeSummary>) {
      emit(HomeLoaded(
        summary: summaryResult.data,
        isOffline: !isOnline,
      ));
    } else if (summaryResult is FailureResult<HomeSummary>) {
      emit(HomeError(summaryResult.failure.message));
    }
  }

  void _onChangeFilter(ChangeFilter event, Emitter<HomeState> emit) {
    if (state is HomeLoaded) {
      emit((state as HomeLoaded).copyWith(selectedFilter: event.filter));
    }
  }

  void _onChangeFabExtension(ChangeFabExtension event, Emitter<HomeState> emit) {
    if (state is HomeLoaded) {
      emit((state as HomeLoaded).copyWith(isFabExtended: event.isExtended));
    }
  }
}
