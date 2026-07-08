import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/friend_invite_preview.dart';
import '../../domain/entities/friend_invite_resolution.dart';
import '../../domain/repositories/friends_repository.dart';

class FriendInviteState extends Equatable {
  final bool isLoading;
  final bool isSubmitting;
  final FriendInvitePreview? preview;
  final String? errorMessage;
  final String? successMessage;
  final bool actionCompleted;

  const FriendInviteState({
    required this.isLoading,
    required this.isSubmitting,
    this.preview,
    this.errorMessage,
    this.successMessage,
    required this.actionCompleted,
  });

  factory FriendInviteState.initial() {
    return const FriendInviteState(
      isLoading: true,
      isSubmitting: false,
      actionCompleted: false,
    );
  }

  FriendInviteState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    FriendInvitePreview? preview,
    String? errorMessage,
    String? successMessage,
    bool? actionCompleted,
    bool clearMessages = false,
  }) {
    return FriendInviteState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      preview: preview ?? this.preview,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
      actionCompleted: actionCompleted ?? this.actionCompleted,
    );
  }

  @override
  List<Object?> get props =>
      [isLoading, isSubmitting, preview, errorMessage, successMessage, actionCompleted];
}

@injectable
class FriendInviteCubit extends Cubit<FriendInviteState> {
  final FriendsRepository _friendsRepository;

  FriendInviteCubit(this._friendsRepository) : super(FriendInviteState.initial());

  Future<void> load({
    required String currentUserId,
    required String friendCode,
  }) async {
    emit(state.copyWith(isLoading: true, clearMessages: true));

    final result = await _friendsRepository.resolveInvitePreview(
      currentUserId: currentUserId,
      friendCode: friendCode,
    );

    if (result.isSuccess) {
      emit(state.copyWith(isLoading: false, preview: result.dataOrThrow));
      return;
    }

    emit(
      state.copyWith(
        isLoading: false,
        errorMessage: 'Could not look up that friend code.',
      ),
    );
  }

  Future<void> sendRequest({
    required String currentUserId,
    required String toUserId,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearMessages: true));

    final result = await _friendsRepository.sendFriendRequest(
      fromUserId: currentUserId,
      toUserId: toUserId,
    );

    if (result.isSuccess) {
      emit(
        state.copyWith(
          isSubmitting: false,
          successMessage: 'Friend request sent!',
          actionCompleted: true,
          preview: FriendInvitePreview(
            resolution: FriendInviteResolution.outgoingPending,
            user: state.preview?.user,
            requestId: '${currentUserId}_$toUserId',
          ),
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        isSubmitting: false,
        errorMessage: 'Could not send friend request. Please try again.',
      ),
    );
  }

  Future<void> acceptRequest({
    required String requestId,
    required String currentUserId,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearMessages: true));

    final result = await _friendsRepository.acceptFriendRequest(
      requestId: requestId,
      userId: currentUserId,
    );

    if (result.isSuccess) {
      emit(
        state.copyWith(
          isSubmitting: false,
          successMessage: 'You are now friends!',
          actionCompleted: true,
          preview: FriendInvitePreview(
            resolution: FriendInviteResolution.alreadyFriends,
            user: state.preview?.user,
            requestId: requestId,
          ),
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        isSubmitting: false,
        errorMessage: 'Could not accept friend request.',
      ),
    );
  }

  Future<void> declineRequest({
    required String requestId,
    required String currentUserId,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearMessages: true));

    final result = await _friendsRepository.declineFriendRequest(
      requestId: requestId,
      userId: currentUserId,
    );

    if (result.isSuccess) {
      emit(
        state.copyWith(
          isSubmitting: false,
          successMessage: 'Friend request declined.',
          actionCompleted: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        isSubmitting: false,
        errorMessage: 'Could not decline friend request.',
      ),
    );
  }
}
