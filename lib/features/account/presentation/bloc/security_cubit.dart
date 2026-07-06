import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/di.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/services/biometric_lock_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/hive_service.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

class SecurityState extends Equatable {
  final bool isBiometricsEnabled;
  final String timeout;
  final bool isAuthenticating;
  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;

  const SecurityState({
    required this.isBiometricsEnabled,
    required this.timeout,
    required this.isAuthenticating,
    required this.isLoading,
    required this.isSuccess,
    this.errorMessage,
  });

  factory SecurityState.initial() {
    return const SecurityState(
      isBiometricsEnabled: false,
      timeout: '5 seconds',
      isAuthenticating: false,
      isLoading: false,
      isSuccess: false,
    );
  }

  SecurityState copyWith({
    bool? isBiometricsEnabled,
    String? timeout,
    bool? isAuthenticating,
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
  }) {
    return SecurityState(
      isBiometricsEnabled: isBiometricsEnabled ?? this.isBiometricsEnabled,
      timeout: timeout ?? this.timeout,
      isAuthenticating: isAuthenticating ?? this.isAuthenticating,
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [isBiometricsEnabled, timeout, isAuthenticating, isLoading, isSuccess, errorMessage];
}

class SecurityCubit extends Cubit<SecurityState> {
  final HiveService _hiveService;
  final AppLogger _logger;
  final BiometricLockService _biometricLockService;
  String _userId = '';

  SecurityCubit(
    this._hiveService,
    this._logger,
    this._biometricLockService,
  ) : super(SecurityState.initial());

  Future<void> loadSettings(String userId) async {
    _userId = userId;

    final bool isEnabled =
        _hiveService.get<bool>(AppConstants.hiveSettingsBox, BiometricLockService.enabledKey) ??
            false;
    final String timeout = _hiveService.get<String>(
          AppConstants.hiveSettingsBox,
          BiometricLockService.timeoutKey,
        ) ??
        '5 seconds';

    emit(state.copyWith(
      isBiometricsEnabled: isEnabled,
      timeout: timeout,
      errorMessage: null,
      isSuccess: false,
    ));

    if (userId.isEmpty) return;

    try {
      final doc = await getIt<FirestoreService>().getDocument(
        FirestorePaths.root,
        FirestorePaths.securityDetails,
      );
      final data = doc.data()?[userId] as Map?;
      if (data == null) return;

      final bool remoteEnabled = data['biometricEnabled'] as bool? ?? isEnabled;
      final int remoteTimeoutSeconds =
          data['biometricTimeout'] as int? ?? BiometricLockService.timeoutLabelToSeconds(timeout);
      final String remoteTimeout = BiometricLockService.secondsToTimeoutLabel(remoteTimeoutSeconds);

      await _hiveService.put(
        AppConstants.hiveSettingsBox,
        BiometricLockService.enabledKey,
        remoteEnabled,
      );
      await _hiveService.put(
        AppConstants.hiveSettingsBox,
        BiometricLockService.timeoutKey,
        remoteTimeout,
      );

      emit(state.copyWith(
        isBiometricsEnabled: remoteEnabled,
        timeout: remoteTimeout,
      ));
    } catch (_) {
      // Keep local Hive values when Firestore is unavailable.
    }
  }

  void updateTimeout(String timeout) {
    _hiveService.put(AppConstants.hiveSettingsBox, BiometricLockService.timeoutKey, timeout);
    emit(state.copyWith(timeout: timeout, errorMessage: null, isSuccess: false));
  }

  Future<void> enableBiometrics(LocalAuthentication localAuth) async {
    emit(state.copyWith(isAuthenticating: true, errorMessage: null, isSuccess: false));
    try {
      final bool canAuthenticateWithBiometrics = await localAuth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await localAuth.isDeviceSupported();

      if (!canAuthenticate) {
        emit(state.copyWith(
          isAuthenticating: false,
          errorMessage: 'Biometric authentication is not supported or set up on this device.',
        ));
        return;
      }

      final bool didAuthenticate = await localAuth.authenticate(
        localizedReason: 'Please authenticate to enable biometrics',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );

      if (didAuthenticate) {
        await _hiveService.put(
          AppConstants.hiveSettingsBox,
          BiometricLockService.enabledKey,
          true,
        );
        await _biometricLockService.recordUnlock();
        emit(state.copyWith(
          isBiometricsEnabled: true,
          isAuthenticating: false,
          isSuccess: true,
        ));
      } else {
        emit(state.copyWith(
          isAuthenticating: false,
          errorMessage: 'Authentication cancelled or failed.',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isAuthenticating: false,
        errorMessage: 'Biometric error: $e',
      ));
    }
  }

  void disableBiometrics() {
    _hiveService.put(AppConstants.hiveSettingsBox, BiometricLockService.enabledKey, false);
    emit(state.copyWith(isBiometricsEnabled: false, errorMessage: null, isSuccess: false));
  }

  Future<void> saveSettings() async {
    emit(state.copyWith(isLoading: true, isSuccess: false, errorMessage: null));

    await _hiveService.put(
      AppConstants.hiveSettingsBox,
      BiometricLockService.enabledKey,
      state.isBiometricsEnabled,
    );
    await _hiveService.put(
      AppConstants.hiveSettingsBox,
      BiometricLockService.timeoutKey,
      state.timeout,
    );

    try {
      await _syncToFirestore();
      if (state.isBiometricsEnabled) {
        await _biometricLockService.recordUnlock();
      }
      emit(state.copyWith(isLoading: false, isSuccess: true));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> _syncToFirestore() async {
    final userId = await _resolveUserId();
    if (userId.isEmpty) {
      _logger.w('SecurityCubit: skipped Firestore sync — no authenticated user');
      throw Exception('User session not found. Please log in again.');
    }

    final payload = {
      'biometricEnabled': state.isBiometricsEnabled,
      'biometricType': 'fingerprint',
      'biometricTimeout': BiometricLockService.timeoutLabelToSeconds(state.timeout),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await getIt<FirestoreService>().setDocument(
      FirestorePaths.root,
      FirestorePaths.securityDetails,
      {userId: payload},
      merge: true,
    );

    _logger.i(
      'SecurityCubit: saved security_details/$userId -> '
      'enabled=${state.isBiometricsEnabled}, timeout=${payload['biometricTimeout']}s',
    );
  }

  Future<String> _resolveUserId() async {
    if (_userId.isNotEmpty) return _userId;

    final result = await getIt<AuthRepository>().getCurrentUser();
    if (result.isSuccess && result.dataOrThrow.id.isNotEmpty) {
      _userId = result.dataOrThrow.id;
    }
    return _userId;
  }
}
