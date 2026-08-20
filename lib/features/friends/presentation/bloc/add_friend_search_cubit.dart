import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/services/contacts_service.dart';
import '../../domain/entities/phone_contact.dart';
import '../../domain/entities/user_preview.dart';
import '../../domain/repositories/friends_repository.dart';
import '../../domain/services/contact_user_matcher.dart';

class AddFriendSearchState extends Equatable {
  final List<PhoneContact> allContacts;
  final List<PhoneContact> filteredContacts;
  final Map<String, UserPreview> registeredMatches;
  final Set<String> friendIds;
  final Set<String> invitedContactIds;
  final Set<String> addingContactIds;
  final bool isLoading;
  final bool permissionDenied;
  final String query;
  final String? errorMessage;
  final String? addedFriendName;

  const AddFriendSearchState({
    required this.allContacts,
    required this.filteredContacts,
    required this.registeredMatches,
    required this.friendIds,
    required this.invitedContactIds,
    required this.addingContactIds,
    required this.isLoading,
    required this.permissionDenied,
    required this.query,
    this.errorMessage,
    this.addedFriendName,
  });

  factory AddFriendSearchState.initial() {
    return const AddFriendSearchState(
      allContacts: [],
      filteredContacts: [],
      registeredMatches: {},
      friendIds: {},
      invitedContactIds: {},
      addingContactIds: {},
      isLoading: true,
      permissionDenied: false,
      query: '',
    );
  }

  AddFriendSearchState copyWith({
    List<PhoneContact>? allContacts,
    List<PhoneContact>? filteredContacts,
    Map<String, UserPreview>? registeredMatches,
    Set<String>? friendIds,
    Set<String>? invitedContactIds,
    Set<String>? addingContactIds,
    bool? isLoading,
    bool? permissionDenied,
    String? query,
    String? errorMessage,
    String? addedFriendName,
    bool clearMessages = false,
  }) {
    return AddFriendSearchState(
      allContacts: allContacts ?? this.allContacts,
      filteredContacts: filteredContacts ?? this.filteredContacts,
      registeredMatches: registeredMatches ?? this.registeredMatches,
      friendIds: friendIds ?? this.friendIds,
      invitedContactIds: invitedContactIds ?? this.invitedContactIds,
      addingContactIds: addingContactIds ?? this.addingContactIds,
      isLoading: isLoading ?? this.isLoading,
      permissionDenied: permissionDenied ?? this.permissionDenied,
      query: query ?? this.query,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      addedFriendName:
          clearMessages ? null : (addedFriendName ?? this.addedFriendName),
    );
  }

  @override
  List<Object?> get props => [
        allContacts,
        filteredContacts,
        registeredMatches,
        friendIds,
        invitedContactIds,
        addingContactIds,
        isLoading,
        permissionDenied,
        query,
        errorMessage,
        addedFriendName,
      ];
}

@injectable
class AddFriendSearchCubit extends Cubit<AddFriendSearchState> {
  final ContactsService _contactsService;
  final FriendsRepository _friendsRepository;

  AddFriendSearchCubit(this._contactsService, this._friendsRepository)
      : super(AddFriendSearchState.initial());

  Future<void> loadContacts({required String currentUserId}) async {
    emit(state.copyWith(isLoading: true, permissionDenied: false, clearMessages: true));

    final granted = await _contactsService.requestPermission();
    if (!granted) {
      emit(
        state.copyWith(
          isLoading: false,
          permissionDenied: true,
          allContacts: [],
          filteredContacts: [],
        ),
      );
      return;
    }

    final contacts = await _contactsService.loadContacts();
    final registeredResult = await _friendsRepository.getRegisteredUsers();
    final friendsResult = await _friendsRepository.getFriends(currentUserId);
    final pendingResult = await _friendsRepository.getPendingContacts(currentUserId);

    final registered =
        registeredResult.isSuccess ? registeredResult.dataOrThrow : const <UserPreview>[];
    final pending =
        pendingResult.isSuccess ? pendingResult.dataOrThrow : const <UserPreview>[];
    final friendIds = <String>{
      if (friendsResult.isSuccess) ...friendsResult.dataOrThrow.map((u) => u.id),
      ...pending.map((u) => u.id),
    };

    final matches = <String, UserPreview>{};
    final invitedContactIds = <String>{};
    for (final contact in contacts) {
      final user = ContactUserMatcher.registeredUserFor(
        contact: contact,
        registeredUsers: registered,
      );
      if (user != null && user.id != currentUserId) {
        matches[contact.id] = user;
      }
      final invited = ContactUserMatcher.registeredUserFor(
        contact: contact,
        registeredUsers: pending,
        skipPending: false,
      );
      if (invited != null) {
        invitedContactIds.add(contact.id);
      }
    }

    emit(
      state.copyWith(
        isLoading: false,
        allContacts: contacts,
        filteredContacts: _filter(contacts, state.query),
        registeredMatches: matches,
        friendIds: friendIds,
        invitedContactIds: invitedContactIds,
      ),
    );
  }

  void filter(String query) {
    emit(
      state.copyWith(
        query: query,
        filteredContacts: _filter(state.allContacts, query),
        clearMessages: true,
      ),
    );
  }

  Future<void> addRegisteredContact({
    required String currentUserId,
    required PhoneContact contact,
  }) async {
    final user = state.registeredMatches[contact.id];
    if (user == null || state.friendIds.contains(user.id)) return;
    if (state.addingContactIds.contains(contact.id)) return;

    emit(
      state.copyWith(
        addingContactIds: {...state.addingContactIds, contact.id},
        clearMessages: true,
      ),
    );

    final result = await _friendsRepository.addFriendDirectly(
      currentUserId: currentUserId,
      friendUserId: user.id,
    );

    final remaining = Set<String>.from(state.addingContactIds)..remove(contact.id);
    if (result.isFailure) {
      emit(
        state.copyWith(
          addingContactIds: remaining,
          errorMessage: 'Could not add ${contact.displayName}.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        addingContactIds: remaining,
        friendIds: {...state.friendIds, user.id},
        addedFriendName: user.name,
      ),
    );
  }

  List<PhoneContact> _filter(List<PhoneContact> contacts, String query) {
    if (query.trim().isEmpty) return contacts;

    final lower = query.toLowerCase();
    return contacts.where((contact) {
      final nameMatch = contact.displayName.toLowerCase().contains(lower);
      final phoneMatch = contact.phone?.contains(query) ?? false;
      final emailMatch = contact.email?.toLowerCase().contains(lower) ?? false;
      return nameMatch || phoneMatch || emailMatch;
    }).toList();
  }
}
