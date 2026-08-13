import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:splitwise/features/auth/data/models/user_model.dart';
import 'package:splitwise/features/friends/domain/entities/user_preview.dart';
import 'package:splitwise/features/friends/domain/repositories/friends_repository.dart';

class AddGroupMembersState extends Equatable {
  final List<UserModel> allUsers;
  final List<UserModel> filteredUsers;
  final List<UserModel> selectedUsers;
  final List<String> existingMemberIds;
  final bool isLoading;

  const AddGroupMembersState({
    this.allUsers = const [],
    this.filteredUsers = const [],
    this.selectedUsers = const [],
    this.existingMemberIds = const [],
    this.isLoading = true,
  });

  AddGroupMembersState copyWith({
    List<UserModel>? allUsers,
    List<UserModel>? filteredUsers,
    List<UserModel>? selectedUsers,
    List<String>? existingMemberIds,
    bool? isLoading,
  }) {
    return AddGroupMembersState(
      allUsers: allUsers ?? this.allUsers,
      filteredUsers: filteredUsers ?? this.filteredUsers,
      selectedUsers: selectedUsers ?? this.selectedUsers,
      existingMemberIds: existingMemberIds ?? this.existingMemberIds,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        allUsers,
        filteredUsers,
        selectedUsers,
        existingMemberIds,
        isLoading,
      ];
}

class AddGroupMembersCubit extends Cubit<AddGroupMembersState> {
  final FriendsRepository _friendsRepository;

  AddGroupMembersCubit(this._friendsRepository) : super(const AddGroupMembersState());

  Future<void> init({
    required String currentUserId,
    required List<String> existingMemberIds,
  }) async {
    emit(state.copyWith(existingMemberIds: existingMemberIds, isLoading: true));

    final friendsResult = await _friendsRepository.getFriends(currentUserId);
    final pendingResult = await _friendsRepository.getPendingContacts(currentUserId);

    final previews = <UserPreview>[
      if (friendsResult.isSuccess) ...friendsResult.dataOrThrow,
      if (pendingResult.isSuccess) ...pendingResult.dataOrThrow,
    ];

    final users = previews
        .where((friend) => friend.id != currentUserId)
        .map(
          (friend) => UserModel(
            id: friend.id,
            email: friend.email ?? friend.phone ?? '',
            name: friend.name,
            photoUrl: friend.photoUrl,
          ),
        )
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    emit(state.copyWith(
      allUsers: users,
      filteredUsers: users,
      isLoading: false,
    ));
  }

  void filterUsers(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      emit(state.copyWith(filteredUsers: state.allUsers));
      return;
    }

    final phoneQuery = normalized.replaceAll(RegExp(r'\D'), '');
    final filtered = state.allUsers.where((user) {
      if (user.name.toLowerCase().contains(normalized)) return true;
      if (user.email.toLowerCase().contains(normalized)) return true;
      if (phoneQuery.length >= 4) {
        final digits = user.email.replaceAll(RegExp(r'\D'), '');
        if (digits.contains(phoneQuery)) return true;
      }
      return false;
    }).toList();
    emit(state.copyWith(filteredUsers: filtered));
  }

  void toggleSelection(UserModel user) {
    if (state.existingMemberIds.contains(user.id)) return;

    final selected = List<UserModel>.from(state.selectedUsers);
    if (selected.any((u) => u.id == user.id)) {
      selected.removeWhere((u) => u.id == user.id);
    } else {
      selected.add(user);
    }
    emit(state.copyWith(selectedUsers: selected));
  }

  void deselectUser(String userId) {
    final selected = List<UserModel>.from(state.selectedUsers);
    selected.removeWhere((u) => u.id == userId);
    emit(state.copyWith(selectedUsers: selected));
  }

  void updateExistingMemberIds(List<String> existingMemberIds) {
    emit(state.copyWith(existingMemberIds: existingMemberIds));
  }
}
