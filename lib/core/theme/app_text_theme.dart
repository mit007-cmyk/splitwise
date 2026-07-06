import 'package:flutter/material.dart';

/// Centralized typography for the app.
///
/// Both [LightTheme] and [DarkTheme] apply this same type scale, only
/// swapping body/display colors for the theme's text color. Never construct
/// a raw [TextStyle] in a widget — always read from `context.textTheme`.
class AppTextTheme {
  AppTextTheme._();

  static const String fontFamily = 'Outfit';

  static const TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 57,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.25,
      height: 1.12,
    ),
    displayMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 45,
      fontWeight: FontWeight.bold,
      height: 1.16,
    ),
    displaySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 36,
      fontWeight: FontWeight.w600,
      height: 1.22,
    ),
    headlineLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 32,
      fontWeight: FontWeight.bold,
      height: 1.25,
    ),
    headlineMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 28,
      fontWeight: FontWeight.w600,
      height: 1.29,
    ),
    headlineSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 24,
      fontWeight: FontWeight.w600,
      height: 1.33,
    ),
    titleLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 22,
      fontWeight: FontWeight.w600,
      height: 1.27,
    ),
    titleMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
      height: 1.5,
    ),
    titleSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.43,
    ),
    bodyLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.normal,
      letterSpacing: 0.5,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.normal,
      letterSpacing: 0.25,
      height: 1.43,
    ),
    bodySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.normal,
      letterSpacing: 0.4,
      height: 1.33,
    ),
    labelLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      height: 1.43,
    ),
    labelMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      height: 1.33,
    ),
    labelSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.45,
    ),
  );
}
