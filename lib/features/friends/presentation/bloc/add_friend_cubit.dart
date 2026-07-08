import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splitwise/features/friends/domain/entities/user_preview.dart';
import 'package:splitwise/features/friends/domain/repositories/friends_repository.dart';

class AddFriendState extends Equatable {
  final String name;
  final String phone;
  final String email;
  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;
  final UserPreview? resolvedUser;

  const AddFriendState({
    required this.name,
    required this.phone,
    required this.email,
    required this.isLoading,
    required this.isSuccess,
    this.errorMessage,
    this.resolvedUser,
  });

  factory AddFriendState.initial({
    String name = '',
    String phone = '',
    String email = '',
  }) {
    return AddFriendState(
      name: name,
      phone: phone,
      email: email,
      isLoading: false,
      isSuccess: false,
    );
  }

  bool get isValid {
    if (name.trim().isEmpty) return false;

    final phoneDigits = phone.replaceAll(RegExp(r'\D'), '').trim();
    final trimmedEmail = email.trim();

    if (phoneDigits.isEmpty && trimmedEmail.isEmpty) return false;

    if (phoneDigits.isNotEmpty && phoneDigits.length < 10) return false;

    if (trimmedEmail.isNotEmpty) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$');
      if (!emailRegex.hasMatch(trimmedEmail)) return false;
    }

    return true;
  }

  AddFriendState copyWith({
    String? name,
    String? phone,
    String? email,
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
    UserPreview? resolvedUser,
  }) {
    return AddFriendState(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage ?? this.errorMessage,
      resolvedUser: resolvedUser ?? this.resolvedUser,
    );
  }

  @override
  List<Object?> get props =>
      [name, phone, email, isLoading, isSuccess, errorMessage, resolvedUser];
}

class AddFriendCubit extends Cubit<AddFriendState> {
  late final FriendsRepository _friendsRepository;

  AddFriendCubit({
    required FriendsRepository friendsRepository,
    String? initialName,
    String? initialPhone,
    String? initialEmail,
  }) : super(
          AddFriendState.initial(
            name: initialName ?? '',
            phone: initialPhone ?? '',
            email: initialEmail ?? '',
          ),
        ) {
    _friendsRepository = friendsRepository;
  }

  void updateName(String name) {
    emit(state.copyWith(name: name));
  }

  void updatePhone(String phone) {
    emit(state.copyWith(phone: phone));
  }

  void updateEmail(String email) {
    emit(state.copyWith(email: email));
  }

  Future<void> addFriend({
    required String currentUserId,
  }) async {
    if (!state.isValid || state.isLoading) return;

    emit(state.copyWith(isLoading: true, isSuccess: false, errorMessage: null));

    final lookupResult = await _friendsRepository.findUserByEmailOrPhone(
      email: state.email.trim().isEmpty ? null : state.email.trim(),
      phone: state.phone.trim().isEmpty ? null : state.phone.trim(),
    );

    if (lookupResult.isFailure) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Could not search user.',
        ),
      );
      return;
    }

    final user = lookupResult.dataOrThrow;
    if (user == null) {
      final pendingResult = await _friendsRepository.createPendingContact(
        ownerUserId: currentUserId,
        displayName: state.name.trim(),
        email: state.email.trim().isEmpty ? null : state.email.trim(),
        phone: state.phone.trim().isEmpty ? null : state.phone.trim(),
      );

      if (pendingResult.isFailure) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: 'Could not create pending contact.',
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          isLoading: false,
          isSuccess: true,
        ),
      );
      return;
    }

    final addResult = await _friendsRepository.addFriendDirectly(
      currentUserId: currentUserId,
      friendUserId: user.id,
    );

    if (addResult.isFailure) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Could not add friend.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        isLoading: false,
        isSuccess: true,
        resolvedUser: user,
      ),
    );
  }
}
