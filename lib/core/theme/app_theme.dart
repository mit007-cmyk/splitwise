import 'package:flutter/material.dart';
import 'dark_theme.dart';
import 'light_theme.dart';

export 'app_colors.dart' show AppColors, AppThemeExtension;
export 'app_text_theme.dart' show AppTextTheme;

/// Single entry point for the app's theme system.
///
/// ```dart
/// MaterialApp(
///   theme: AppTheme.lightTheme,
///   darkTheme: AppTheme.darkTheme,
///   themeMode: ThemeMode.system,
/// )
/// ```
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => LightTheme.theme;

  static ThemeData get darkTheme => DarkTheme.theme;
}
