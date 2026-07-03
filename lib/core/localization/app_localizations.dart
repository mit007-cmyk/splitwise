import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'Splitwise',
      'common_retry': 'Retry',
      'common_cancel': 'Cancel',
      'common_confirm': 'Confirm',
      'common_error': 'Error',
      'common_no_data': 'No data found',
      'network_error_title': 'No Internet Connection',
      'network_error_msg': 'Please check your connection and try again.',
      'unknown_error_msg': 'Something went wrong. Please try again.',
      'splash_tagline': 'Split bills, not friendships',
      'maintenance_title': 'Under Maintenance',
      'maintenance_msg': 'We are upgrading our servers. Please check back shortly.',
      'force_update_title': 'Update Required',
      'force_update_msg': 'A new version of the app is available. Please update to continue.',
      'force_update_btn': 'Update Now',
      'search_placeholder': 'Search...',
    },
    'es': {
      'app_title': 'Splitwise',
      'common_retry': 'Reintentar',
      'common_cancel': 'Cancelar',
      'common_confirm': 'Confirmar',
      'common_error': 'Error',
      'common_no_data': 'No se encontraron datos',
      'network_error_title': 'Sin conexión a Internet',
      'network_error_msg': 'Por favor, comprueba tu conexión e inténtalo de nuevo.',
      'unknown_error_msg': 'Algo salió mal. Por favor, inténtelo de nuevo.',
      'splash_tagline': 'Comparte gastos, no amistades',
      'maintenance_title': 'En mantenimiento',
      'maintenance_msg': 'Estamos actualizando nuestros servidores. Por favor, vuelva pronto.',
      'force_update_title': 'Actualización requerida',
      'force_update_msg': 'Una nueva versión de la aplicación está disponible. Por favor, actualice para continuar.',
      'force_update_btn': 'Actualizar ahora',
      'search_placeholder': 'Buscar...',
    }
  };

  String translate(String key) {
    final valuesForLanguage = _localizedValues[locale.languageCode] ?? _localizedValues['en']!;
    return valuesForLanguage[key] ?? key;
  }

  // Helper getters
  String get appTitle => translate('app_title');
  String get commonRetry => translate('common_retry');
  String get commonCancel => translate('common_cancel');
  String get commonConfirm => translate('common_confirm');
  String get commonError => translate('common_error');
  String get commonNoData => translate('common_no_data');
  String get networkErrorTitle => translate('network_error_title');
  String get networkErrorMsg => translate('network_error_msg');
  String get unknownErrorMsg => translate('unknown_error_msg');
  String get splashTagline => translate('splash_tagline');
  String get maintenanceTitle => translate('maintenance_title');
  String get maintenanceMsg => translate('maintenance_msg');
  String get forceUpdateTitle => translate('force_update_title');
  String get forceUpdateMsg => translate('force_update_msg');
  String get forceUpdateBtn => translate('force_update_btn');
  String get searchPlaceholder => translate('search_placeholder');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'es'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    // Set default locale for external formatters like DateFormat
    Intl.defaultLocale = locale.toString();
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
