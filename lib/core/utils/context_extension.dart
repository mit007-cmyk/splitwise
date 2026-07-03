import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

extension ContextExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;
  
  AppLocalizations get loc => AppLocalizations.of(this) ?? AppLocalizations(const Locale('en'));
  String translate(String key) => loc.translate(key);

  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
}
