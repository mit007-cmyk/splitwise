import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/user_preview.dart';
import '../../domain/repositories/friends_repository.dart';

class FriendsListState extends Equatable {
  final bool isLoading;
  final List<UserPreview> friends;
  final String? errorMessage;

  const FriendsListState({
    required this.isLoading,
    required this.friends,
    this.errorMessage,
  });

  factory FriendsListState.initial() {
    return const FriendsListState(
      isLoading: true,
      friends: [],
    );
  }

  FriendsListState copyWith({
    bool? isLoading,
    List<UserPreview>? friends,
    String? errorMessage,
  }) {
    return FriendsListState(
      isLoading: isLoading ?? this.isLoading,
      friends: friends ?? this.friends,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, friends, errorMessage];
}

@injectable
class FriendsListCubit extends Cubit<FriendsListState> {
  final FriendsRepository _friendsRepository;

  FriendsListCubit(this._friendsRepository) : super(FriendsListState.initial());

  void setIdle() {
    emit(state.copyWith(isLoading: false, friends: const [], errorMessage: null));
  }

  Future<void> load(String userId) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    final friendsResult = await _friendsRepository.getFriends(userId);
    final pendingResult = await _friendsRepository.getPendingContacts(userId);

    if (friendsResult.isFailure || pendingResult.isFailure) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Could not load friends.',
        ),
      );
      return;
    }

    final merged = <UserPreview>[
      ...friendsResult.dataOrThrow,
      ...pendingResult.dataOrThrow,
    ]..sort((a, b) => a.name.compareTo(b.name));

    emit(
      state.copyWith(
        isLoading: false,
        friends: merged,
      ),
    );
  }
}
