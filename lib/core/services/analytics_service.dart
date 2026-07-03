import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:injectable/injectable.dart';
import 'app_logger.dart';

@singleton
class AnalyticsService {
  FirebaseAnalytics get _analytics => FirebaseAnalytics.instance;
  final AppLogger _logger;

  AnalyticsService(this._logger);

  /// Track a user navigating to a screen/route
  Future<void> logScreen({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      _logger.d('Analytics: Log Screen -> $screenName (class: $screenClass)');
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
    } catch (e, stackTrace) {
      _logger.e('Failed to log screen view: $screenName', e, stackTrace);
    }
  }

  /// Track custom user interactions or events
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      _logger.d('Analytics: Log Event -> $name (params: $parameters)');
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (e, stackTrace) {
      _logger.e('Failed to log event: $name', e, stackTrace);
    }
  }

  /// Associate events with a specific user profile
  Future<void> setUser({required String? userId}) async {
    try {
      _logger.d('Analytics: Set User ID -> $userId');
      await _analytics.setUserId(id: userId);
    } catch (e, stackTrace) {
      _logger.e('Failed to set user id', e, stackTrace);
    }
  }

  /// Set customized user metadata property
  Future<void> setProperty({
    required String name,
    required String? value,
  }) async {
    try {
      _logger.d('Analytics: Set User Property -> $name : $value');
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e, stackTrace) {
      _logger.e('Failed to set user property: $name', e, stackTrace);
    }
  }
}
