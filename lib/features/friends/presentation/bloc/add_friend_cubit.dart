import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splitwise/features/home/presentation/bloc/home_bloc.dart';
import 'package:splitwise/features/home/presentation/bloc/home_event.dart';

class AddFriendState extends Equatable {
  final String name;
  final String phone;
  final String email;
  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;

  const AddFriendState({
    required this.name,
    required this.phone,
    required this.email,
    required this.isLoading,
    required this.isSuccess,
    this.errorMessage,
  });

  factory AddFriendState.initial() {
    return const AddFriendState(
      name: '',
      phone: '',
      email: '',
      isLoading: false,
      isSuccess: false,
    );
  }

  bool get isValid {
    if (name.trim().isEmpty) return false;
    if (phone.trim().isEmpty && email.trim().isEmpty) return false;

    if (phone.isNotEmpty && phone.length != 10) return false;
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (email.isNotEmpty && !emailRegex.hasMatch(email)) return false;

    return true;
  }

  AddFriendState copyWith({
    String? name,
    String? phone,
    String? email,
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
  }) {
    return AddFriendState(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [name, phone, email, isLoading, isSuccess, errorMessage];
}

class AddFriendCubit extends Cubit<AddFriendState> {
  AddFriendCubit() : super(AddFriendState.initial());

  void updateName(String name) {
    emit(state.copyWith(name: name));
  }

  void updatePhone(String phone) {
    emit(state.copyWith(phone: phone));
  }

  void updateEmail(String email) {
    emit(state.copyWith(email: email));
  }

  void saveContact(HomeBloc homeBloc) {
    if (!state.isValid || state.isLoading) return;

    emit(state.copyWith(isLoading: true, isSuccess: false));
    
    homeBloc.add(AddContactRequested(
      name: state.name.trim(),
      phone: state.phone.isNotEmpty ? state.phone.trim() : null,
      email: state.email.isNotEmpty ? state.email.trim() : null,
    ));

    // Simulate completion matching the UI delay
    Future.delayed(const Duration(milliseconds: 600), () {
      emit(state.copyWith(isLoading: false, isSuccess: true));
    });
  }
}
