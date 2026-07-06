import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../constants/app_constants.dart';
import '../services/hive_service.dart';

/// Manages app-wide [ThemeMode] and persists the user's choice in Hive.
@lazySingleton
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._hiveService) : super(ThemeMode.system) {
    loadSavedTheme();
  }

  final HiveService _hiveService;

  void loadSavedTheme() {
    final saved = _hiveService.get<String>(
      AppConstants.hiveThemeBox,
      AppConstants.hiveThemeModeKey,
    );
    emit(_fromStorage(saved));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _hiveService.put(
      AppConstants.hiveThemeBox,
      AppConstants.hiveThemeModeKey,
      _toStorage(mode),
    );
    emit(mode);
  }

  static ThemeMode _fromStorage(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _toStorage(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
