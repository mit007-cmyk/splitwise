import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:splitwise/core/errors/failures.dart';
import 'package:splitwise/core/errors/result.dart';
import 'package:splitwise/core/services/contacts_service.dart';
import 'package:splitwise/features/auth/data/models/user_model.dart';
import 'package:splitwise/features/friends/domain/entities/phone_contact.dart';
import 'package:splitwise/features/friends/domain/entities/user_preview.dart';
import 'package:splitwise/features/friends/domain/repositories/friends_repository.dart';
import 'package:splitwise/features/friends/domain/services/contact_user_matcher.dart';
import 'package:splitwise/features/friends/domain/services/friend_list_deduper.dart';
import 'package:splitwise/features/groups/domain/entities/group_member_invite.dart';

class AddGroupMembersState extends Equatable {
  final List<UserModel> allUsers;
  final List<UserModel> filteredUsers;
  final List<PhoneContact> allContacts;
  final List<PhoneContact> filteredContacts;
  final Map<String, UserPreview> registeredMatches;
  final List<GroupMemberInvite> selected;
  final List<String> existingMemberIds;
  final String query;
  final bool isLoading;
  final bool isLoadingContacts;
  final bool isSubmitting;
  final String? errorMessage;

  const AddGroupMembersState({
    this.allUsers = const [],
    this.filteredUsers = const [],
    this.allContacts = const [],
    this.filteredContacts = const [],
    this.registeredMatches = const {},
    this.selected = const [],
    this.existingMemberIds = const [],
    this.query = '',
    this.isLoading = true,
    this.isLoadingContacts = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  AddGroupMembersState copyWith({
    List<UserModel>? allUsers,
    List<UserModel>? filteredUsers,
    List<PhoneContact>? allContacts,
    List<PhoneContact>? filteredContacts,
    Map<String, UserPreview>? registeredMatches,
    List<GroupMemberInvite>? selected,
    List<String>? existingMemberIds,
    String? query,
    bool? isLoading,
    bool? isLoadingContacts,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AddGroupMembersState(
      allUsers: allUsers ?? this.allUsers,
      filteredUsers: filteredUsers ?? this.filteredUsers,
      allContacts: allContacts ?? this.allContacts,
      filteredContacts: filteredContacts ?? this.filteredContacts,
      registeredMatches: registeredMatches ?? this.registeredMatches,
      selected: selected ?? this.selected,
      existingMemberIds: existingMemberIds ?? this.existingMemberIds,
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      isLoadingContacts: isLoadingContacts ?? this.isLoadingContacts,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        allUsers,
        filteredUsers,
        allContacts,
        filteredContacts,
        registeredMatches,
        selected,
        existingMemberIds,
        query,
        isLoading,
        isLoadingContacts,
        isSubmitting,
        errorMessage,
      ];
}

class AddGroupMembersCubit extends Cubit<AddGroupMembersState> {
  final FriendsRepository _friendsRepository;
  final ContactsService _contactsService;

  final Set<String> _friendEmails = {};
  final Set<String> _friendPhones = {};

  AddGroupMembersCubit(
    this._friendsRepository,
    this._contactsService,
  ) : super(const AddGroupMembersState());

  Future<void> init({
    required String currentUserId,
    required List<String> existingMemberIds,
  }) async {
    emit(state.copyWith(existingMemberIds: existingMemberIds, isLoading: true));
    await _loadFriends(currentUserId);
    await _loadContacts();
  }

  Future<void> _loadFriends(String currentUserId) async {
    final friendsResult = await _friendsRepository.getFriends(currentUserId);
    final pendingResult = await _friendsRepository.getPendingContacts(currentUserId);

    final previews = FriendListDeduper.merge(
      friends: friendsResult.isSuccess ? friendsResult.dataOrThrow : const [],
      pending: pendingResult.isSuccess ? pendingResult.dataOrThrow : const [],
    );

    _indexFriendKeys(previews);

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
      filteredUsers: _filterFriends(users, state.query),
      isLoading: false,
    ));
  }

  Future<void> _loadContacts() async {
    emit(state.copyWith(isLoadingContacts: true));

    final contacts = await _contactsService.loadContacts();
    final unique = contacts.where((contact) => !_isAlreadyFriend(contact)).toList();
    final registeredResult = await _friendsRepository.getRegisteredUsers();
    final registered =
        registeredResult.isSuccess ? registeredResult.dataOrThrow : const <UserPreview>[];
    final matches = <String, UserPreview>{};
    for (final contact in unique) {
      final user = ContactUserMatcher.registeredUserFor(
        contact: contact,
        registeredUsers: registered,
      );
      if (user != null) matches[contact.id] = user;
    }

    emit(state.copyWith(
      allContacts: unique,
      filteredContacts: _filterContacts(unique, state.query),
      registeredMatches: matches,
      isLoadingContacts: false,
    ));
  }

  void filterUsers(String query) {
    emit(state.copyWith(
      query: query,
      filteredUsers: _filterFriends(state.allUsers, query),
      filteredContacts: _filterContacts(state.allContacts, query),
    ));
  }

  void toggleSelection(UserModel user) {
    if (state.existingMemberIds.contains(user.id)) return;
    _toggleInvite(GroupMemberInvite.fromUser(user));
  }

  void toggleContact(PhoneContact contact) {
    final matched = state.registeredMatches[contact.id];
    if (matched != null) {
      toggleSelection(
        UserModel(
          id: matched.id,
          email: matched.email ?? matched.phone ?? '',
          name: matched.name,
          photoUrl: matched.photoUrl,
        ),
      );
      return;
    }
    _toggleInvite(GroupMemberInvite.fromContact(contact));
  }

  void upsertInvite(GroupMemberInvite invite) {
    final selected = List<GroupMemberInvite>.from(state.selected);
    final index = selected.indexWhere((item) => item.key == invite.key);
    if (index >= 0) {
      selected[index] = invite;
    } else {
      selected.add(invite);
    }
    emit(state.copyWith(selected: selected, clearError: true));
  }

  void deselect(String key) {
    final selected = List<GroupMemberInvite>.from(state.selected);
    selected.removeWhere((item) => item.key == key);
    emit(state.copyWith(selected: selected));
  }

  bool isSelectedKey(String key) => state.selected.any((item) => item.key == key);

  void updateExistingMemberIds(List<String> existingMemberIds) {
    emit(state.copyWith(existingMemberIds: existingMemberIds));
  }

  Future<Result<List<String>>> resolveSelectedMemberIds(String currentUserId) async {
    if (state.selected.isEmpty) {
      return Result.failure(const UnknownFailure('Select at least one person.'));
    }
    if (state.isSubmitting) {
      return Result.failure(const UnknownFailure('Already adding members.'));
    }

    emit(state.copyWith(isSubmitting: true, clearError: true));

    final ids = <String>[];
    for (final invite in state.selected) {
      final resolved = await _resolveInvite(currentUserId, invite);
      if (resolved.isFailure) {
        final failure = (resolved as FailureResult<String>).failure;
        emit(state.copyWith(isSubmitting: false, errorMessage: failure.message));
        return Result.failure(failure);
      }
      ids.add(resolved.dataOrThrow);
    }

    emit(state.copyWith(isSubmitting: false));
    return Result.success(ids);
  }

  Future<Result<String>> _resolveInvite(
    String currentUserId,
    GroupMemberInvite invite,
  ) async {
    if (invite.userId != null && invite.userId!.isNotEmpty) {
      return Result.success(invite.userId!);
    }

    final pendingResult = await _friendsRepository.getPendingContacts(currentUserId);
    if (pendingResult.isFailure) return _asStringFailure(pendingResult);
    final existingPending = _matchPreview(pendingResult.dataOrThrow, invite);
    if (existingPending != null) {
      return Result.success(existingPending.id);
    }

    final lookup = await _friendsRepository.findUserByEmailOrPhone(
      email: invite.email,
      phone: invite.phone,
    );
    if (lookup.isFailure) return _asStringFailure(lookup);
    final user = lookup.dataOrThrow;
    if (user != null && user.id != currentUserId) {
      await _friendsRepository.addFriendDirectly(
        currentUserId: currentUserId,
        friendUserId: user.id,
      );
      return Result.success(user.id);
    }

    final created = await _friendsRepository.createPendingContact(
      ownerUserId: currentUserId,
      displayName: invite.displayName.trim().isEmpty
          ? (invite.phone ?? invite.email ?? 'Friend')
          : invite.displayName.trim(),
      email: invite.email,
      phone: invite.phone,
    );
    if (created.isFailure) return created;
    return Result.success(created.dataOrThrow);
  }

  Result<String> _asStringFailure<T>(Result<T> result) {
    if (result is FailureResult<T>) {
      return Result.failure(result.failure);
    }
    return Result.failure(const UnknownFailure('Could not add this contact.'));
  }

  UserPreview? _matchPreview(List<UserPreview> previews, GroupMemberInvite invite) {
    final email = invite.email?.trim().toLowerCase();
    final phone = _phoneKey(invite.phone);
    for (final preview in previews) {
      final previewEmail = preview.email?.trim().toLowerCase();
      if (email != null && email.isNotEmpty && previewEmail == email) {
        return preview;
      }
      final previewPhone = _phoneKey(preview.phone) ?? _phoneKey(preview.email);
      if (phone != null && previewPhone == phone) return preview;
    }
    return null;
  }

  void _toggleInvite(GroupMemberInvite invite) {
    final selected = List<GroupMemberInvite>.from(state.selected);
    if (selected.any((item) => item.key == invite.key)) {
      selected.removeWhere((item) => item.key == invite.key);
    } else {
      selected.add(invite);
    }
    emit(state.copyWith(selected: selected, clearError: true));
  }

  void _indexFriendKeys(List<UserPreview> previews) {
    _friendEmails.clear();
    _friendPhones.clear();
    for (final friend in previews) {
      final email = friend.email?.trim().toLowerCase();
      if (email != null && email.isNotEmpty) {
        _friendEmails.add(email);
      }
      final phone = _phoneKey(friend.phone) ?? _phoneKey(friend.email);
      if (phone != null) _friendPhones.add(phone);
    }
  }

  bool _isAlreadyFriend(PhoneContact contact) {
    final email = contact.email?.trim().toLowerCase();
    if (email != null && email.isNotEmpty && _friendEmails.contains(email)) {
      return true;
    }
    final phone = _phoneKey(contact.phone);
    return phone != null && _friendPhones.contains(phone);
  }

  List<UserModel> _filterFriends(List<UserModel> users, String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return users;

    final phoneQuery = normalized.replaceAll(RegExp(r'\D'), '');
    return users.where((user) {
      if (user.name.toLowerCase().contains(normalized)) return true;
      if (user.email.toLowerCase().contains(normalized)) return true;
      if (phoneQuery.length >= 4) {
        final digits = user.email.replaceAll(RegExp(r'\D'), '');
        if (digits.contains(phoneQuery)) return true;
      }
      return false;
    }).toList();
  }

  List<PhoneContact> _filterContacts(List<PhoneContact> contacts, String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return contacts;

    final phoneQuery = normalized.replaceAll(RegExp(r'\D'), '');
    return contacts.where((contact) {
      if (contact.displayName.toLowerCase().contains(normalized)) return true;
      if (contact.email?.toLowerCase().contains(normalized) ?? false) return true;
      if (phoneQuery.length >= 4) {
        final digits = (contact.phone ?? '').replaceAll(RegExp(r'\D'), '');
        if (digits.contains(phoneQuery)) return true;
      }
      return false;
    }).toList();
  }

  static String? _phoneKey(String? raw) => ContactUserMatcher.phoneKey(raw);
}
