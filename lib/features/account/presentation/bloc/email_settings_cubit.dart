import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/di.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/firestore_service.dart';

class EmailSettingsState extends Equatable {
  final Map<String, bool> settings;
  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;

  const EmailSettingsState({
    required this.settings,
    required this.isLoading,
    required this.isSuccess,
    this.errorMessage,
  });

  factory EmailSettingsState.initial() {
    return const EmailSettingsState(
      settings: {
        'addsMeToGroup': true,
        'addsMeAsFriend': true,
        'expenseAdded': false,
        'expenseEditedDeleted': false,
        'expenseCommented': false,
        'expenseDue': true,
        'paysMe': true,
        'monthlyActivitySummary': true,
        'majorNewsUpdates': true,
      },
      isLoading: true,
      isSuccess: false,
    );
  }

  EmailSettingsState copyWith({
    Map<String, bool>? settings,
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
  }) {
    return EmailSettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [settings, isLoading, isSuccess, errorMessage];
}

class EmailSettingsCubit extends Cubit<EmailSettingsState> {
  EmailSettingsCubit() : super(EmailSettingsState.initial());

  Future<void> loadSettings(String userId) async {
    emit(state.copyWith(isLoading: true, isSuccess: false));
    try {
      final doc = await getIt<FirestoreService>().getDocument('Splitwise', 'email_configuration');
      final data = doc.data()?[userId] as Map?;
      if (data != null) {
        final Map<String, bool> updated = Map<String, bool>.from(state.settings);
        for (final key in updated.keys) {
          if (data.containsKey(key)) {
            updated[key] = data[key] as bool;
          }
        }
        emit(state.copyWith(settings: updated, isLoading: false));
      } else {
        emit(state.copyWith(isLoading: false));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  void toggleSetting(String key, bool value) {
    final Map<String, bool> updated = Map<String, bool>.from(state.settings);
    updated[key] = value;
    emit(state.copyWith(settings: updated));
  }

  Future<void> saveSettings(String userId) async {
    emit(state.copyWith(isLoading: true, isSuccess: false));
    try {
      await getIt<FirestoreService>().setDocument(
        'Splitwise',
        'email_configuration',
        {
          userId: state.settings,
        },
        merge: true,
      );
      emit(state.copyWith(isLoading: false, isSuccess: true));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }
}
