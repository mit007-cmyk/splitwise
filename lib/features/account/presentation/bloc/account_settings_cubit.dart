import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/di.dart';
import '../../../../core/services/firestore_service.dart';

class AccountSettingsState extends Equatable {
  final String name;
  final String email;
  final String phone;
  final String password;
  final String timeZone;
  final String currency;
  final String language;
  final bool allowSuggest;
  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;

  const AccountSettingsState({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.timeZone,
    required this.currency,
    required this.language,
    required this.allowSuggest,
    required this.isLoading,
    required this.isSuccess,
    this.errorMessage,
  });

  factory AccountSettingsState.initial() {
    return const AccountSettingsState(
      name: '',
      email: '',
      phone: 'None',
      password: '••••••••',
      timeZone: '(GMT+05:30) Chennai',
      currency: 'USD',
      language: 'English',
      allowSuggest: true,
      isLoading: true,
      isSuccess: false,
    );
  }

  AccountSettingsState copyWith({
    String? name,
    String? email,
    String? phone,
    String? password,
    String? timeZone,
    String? currency,
    String? language,
    bool? allowSuggest,
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
  }) {
    return AccountSettingsState(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      timeZone: timeZone ?? this.timeZone,
      currency: currency ?? this.currency,
      language: language ?? this.language,
      allowSuggest: allowSuggest ?? this.allowSuggest,
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        name,
        email,
        phone,
        password,
        timeZone,
        currency,
        language,
        allowSuggest,
        isLoading,
        isSuccess,
        errorMessage,
      ];
}

class AccountSettingsCubit extends Cubit<AccountSettingsState> {
  AccountSettingsCubit() : super(AccountSettingsState.initial());

  Future<void> loadSettings(String userId, String defaultName, String defaultEmail) async {
    emit(state.copyWith(name: defaultName, email: defaultEmail, isLoading: true, isSuccess: false));
    try {
      final usersDoc = await getIt<FirestoreService>().getDocument('Splitwise', 'users');
      final usersData = usersDoc.data();
      if (usersData != null && usersData.containsKey(userId)) {
        final uData = Map<String, dynamic>.from(usersData[userId] as Map);
        emit(state.copyWith(
          name: uData['name'] as String? ?? defaultName,
          email: uData['email'] as String? ?? defaultEmail,
          phone: uData['phone'] as String? ?? 'None',
          timeZone: uData['timezone'] as String? ?? state.timeZone,
          currency: uData['currency'] as String? ?? state.currency,
          language: uData['language'] as String? ?? state.language,
          allowSuggest: uData['allowSuggest'] as bool? ?? state.allowSuggest,
          isLoading: false,
        ));
      } else {
        emit(state.copyWith(isLoading: false));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  void updateName(String name) => emit(state.copyWith(name: name));
  void updateEmail(String email) => emit(state.copyWith(email: email));
  void updatePhone(String phone) => emit(state.copyWith(phone: phone));
  
  Future<void> updatePassword(String newPassword) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        await currentUser.updatePassword(newPassword);
      } catch (e) {
        emit(state.copyWith(errorMessage: e.toString()));
      }
    }
  }

  void updateTimeZone(String timeZone) => emit(state.copyWith(timeZone: timeZone));
  void updateCurrency(String currency) => emit(state.copyWith(currency: currency));
  void updateLanguage(String language) => emit(state.copyWith(language: language));
  void updateAllowSuggest(bool allowSuggest) => emit(state.copyWith(allowSuggest: allowSuggest));

  Future<void> saveChanges(String userId) async {
    emit(state.copyWith(isLoading: true, isSuccess: false));
    try {
      final usersDoc = await getIt<FirestoreService>().getDocument('Splitwise', 'users');
      final usersData = Map<String, dynamic>.from(usersDoc.data() ?? {});
      
      final Map<String, dynamic> userMap = Map<String, dynamic>.from(usersData[userId] as Map? ?? {});
      userMap['name'] = state.name;
      userMap['email'] = state.email;
      userMap['phone'] = state.phone == 'None' ? null : state.phone;
      userMap['timezone'] = state.timeZone;
      userMap['currency'] = state.currency;
      userMap['language'] = state.language;
      userMap['allowSuggest'] = state.allowSuggest;
      userMap['updatedAt'] = DateTime.now().toIso8601String();

      usersData[userId] = userMap;
      await getIt<FirestoreService>().setDocument('Splitwise', 'users', usersData);

      // Try updating FirebaseAuth user display name if supported
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        if (currentUser.displayName != state.name) {
          await currentUser.updateDisplayName(state.name);
        }
      }

      emit(state.copyWith(isLoading: false, isSuccess: true));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }
}
