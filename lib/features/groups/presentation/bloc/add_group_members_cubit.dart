import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:splitwise/features/auth/data/models/user_model.dart';
import 'package:splitwise/features/home/domain/repositories/home_repository.dart';

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
  final HomeRepository _homeRepository;

  AddGroupMembersCubit(this._homeRepository) : super(const AddGroupMembersState());

  Future<void> init(List<String> existingMemberIds) async {
    emit(state.copyWith(existingMemberIds: existingMemberIds, isLoading: true));
    final result = await _homeRepository.getAllUsers();
    final users = result.isSuccess ? result.dataOrThrow : <UserModel>[];
    emit(state.copyWith(
      allUsers: users,
      filteredUsers: users,
      isLoading: false,
    ));
  }

  void filterUsers(String query) {
    if (query.isEmpty) {
      emit(state.copyWith(filteredUsers: state.allUsers));
    } else {
      final filtered = state.allUsers.where((user) {
        final nameMatch = user.name.toLowerCase().contains(query.toLowerCase());
        final emailMatch = user.email.toLowerCase().contains(query.toLowerCase());
        return nameMatch || emailMatch;
      }).toList();
      emit(state.copyWith(filteredUsers: filtered));
    }
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
}
