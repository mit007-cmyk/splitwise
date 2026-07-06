import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import '../theme/app_colors.dart';

extension ContextExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;

  /// Semantic colors with no Material equivalent — success/warning/info,
  /// financial states, hint/disabled text. See `app_colors.dart`.
  AppThemeExtension get appColors =>
      theme.extension<AppThemeExtension>() ?? AppThemeExtension.light;

  AppLocalizations get loc => AppLocalizations.of(this) ?? AppLocalizations(const Locale('en'));
  String translate(String key) => loc.translate(key);

  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
}
