import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/friend_code_info.dart';
import '../../domain/repositories/friends_repository.dart';

class MyCodeState extends Equatable {
  final bool isLoading;
  final bool isChangingCode;
  final FriendCodeInfo? info;
  final String? errorMessage;
  final String? successMessage;

  const MyCodeState({
    required this.isLoading,
    required this.isChangingCode,
    this.info,
    this.errorMessage,
    this.successMessage,
  });

  factory MyCodeState.initial() {
    return const MyCodeState(
      isLoading: true,
      isChangingCode: false,
    );
  }

  MyCodeState copyWith({
    bool? isLoading,
    bool? isChangingCode,
    FriendCodeInfo? info,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return MyCodeState(
      isLoading: isLoading ?? this.isLoading,
      isChangingCode: isChangingCode ?? this.isChangingCode,
      info: info ?? this.info,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [isLoading, isChangingCode, info, errorMessage, successMessage];
}

@injectable
class MyCodeCubit extends Cubit<MyCodeState> {
  final FriendsRepository _friendsRepository;

  MyCodeCubit(this._friendsRepository) : super(MyCodeState.initial());

  Future<void> load({
    required String userId,
    required String userName,
    String? photoUrl,
  }) async {
    emit(state.copyWith(isLoading: true, clearMessages: true));

    final result = await _friendsRepository.getMyFriendCode(
      userId: userId,
      userName: userName,
      photoUrl: photoUrl,
    );

    if (result.isSuccess) {
      emit(state.copyWith(isLoading: false, info: result.dataOrThrow));
      return;
    }

    emit(
      state.copyWith(
        isLoading: false,
        errorMessage: 'Could not load your friend code. Please try again.',
      ),
    );
  }

  Future<void> changeCode({
    required String userId,
    required String userName,
    String? photoUrl,
  }) async {
    emit(state.copyWith(isChangingCode: true, clearMessages: true));

    final result = await _friendsRepository.changeFriendCode(
      userId: userId,
      userName: userName,
      photoUrl: photoUrl,
    );

    if (result.isSuccess) {
      emit(
        state.copyWith(
          isChangingCode: false,
          info: result.dataOrThrow,
          successMessage: 'Your friend code has been updated.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        isChangingCode: false,
        errorMessage: 'Could not change your friend code. Please try again.',
      ),
    );
  }
}
