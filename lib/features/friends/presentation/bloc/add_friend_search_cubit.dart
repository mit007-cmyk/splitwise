import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/services/contacts_service.dart';
import '../../domain/entities/phone_contact.dart';

class AddFriendSearchState extends Equatable {
  final List<PhoneContact> allContacts;
  final List<PhoneContact> filteredContacts;
  final bool isLoading;
  final bool permissionDenied;
  final String query;

  const AddFriendSearchState({
    required this.allContacts,
    required this.filteredContacts,
    required this.isLoading,
    required this.permissionDenied,
    required this.query,
  });

  factory AddFriendSearchState.initial() {
    return const AddFriendSearchState(
      allContacts: [],
      filteredContacts: [],
      isLoading: true,
      permissionDenied: false,
      query: '',
    );
  }

  AddFriendSearchState copyWith({
    List<PhoneContact>? allContacts,
    List<PhoneContact>? filteredContacts,
    bool? isLoading,
    bool? permissionDenied,
    String? query,
  }) {
    return AddFriendSearchState(
      allContacts: allContacts ?? this.allContacts,
      filteredContacts: filteredContacts ?? this.filteredContacts,
      isLoading: isLoading ?? this.isLoading,
      permissionDenied: permissionDenied ?? this.permissionDenied,
      query: query ?? this.query,
    );
  }

  @override
  List<Object?> get props =>
      [allContacts, filteredContacts, isLoading, permissionDenied, query];
}

@injectable
class AddFriendSearchCubit extends Cubit<AddFriendSearchState> {
  final ContactsService _contactsService;

  AddFriendSearchCubit(this._contactsService)
      : super(AddFriendSearchState.initial());

  Future<void> loadContacts() async {
    emit(state.copyWith(isLoading: true, permissionDenied: false));

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
    emit(
      state.copyWith(
        isLoading: false,
        allContacts: contacts,
        filteredContacts: _filter(contacts, state.query),
      ),
    );
  }

  void filter(String query) {
    emit(
      state.copyWith(
        query: query,
        filteredContacts: _filter(state.allContacts, query),
      ),
    );
  }

  List<PhoneContact> _filter(List<PhoneContact> contacts, String query) {
    if (query.trim().isEmpty) return contacts;

    final lower = query.toLowerCase();
    return contacts.where((contact) {
      final nameMatch = contact.displayName.toLowerCase().contains(lower);
      final phoneMatch = contact.phone?.contains(query) ?? false;
      final emailMatch =
          contact.email?.toLowerCase().contains(lower) ?? false;
      return nameMatch || phoneMatch || emailMatch;
    }).toList();
  }
}
