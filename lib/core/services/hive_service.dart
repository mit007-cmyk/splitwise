import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';
import '../constants/app_constants.dart';
import 'app_logger.dart';

@singleton
class HiveService {
  final AppLogger _logger;

  HiveService(this._logger);

  /// Initializes Hive and opens all application boxes
  Future<void> init() async {
    try {
      await Hive.initFlutter();
      
      // Open boxes
      await Future.wait([
        Hive.openBox(AppConstants.hiveUserBox),
        Hive.openBox(AppConstants.hiveSettingsBox),
        Hive.openBox(AppConstants.hiveCacheBox),
        Hive.openBox(AppConstants.hiveThemeBox),
        Hive.openBox(AppConstants.hivePendingSyncBox),
      ]);
      
      _logger.i('Hive boxes initialized successfully.');
    } catch (e, stackTrace) {
      _logger.e('Failed to initialize Hive boxes', e, stackTrace);
      rethrow;
    }
  }

  Box _getBox(String boxName) {
    if (!Hive.isBoxOpen(boxName)) {
      throw Exception('Box $boxName is not open. Ensure HiveService.init() was called.');
    }
    return Hive.box(boxName);
  }

  /// Retrieve value from a box
  T? get<T>(String boxName, String key, {T? defaultValue}) {
    try {
      final box = _getBox(boxName);
      return box.get(key, defaultValue: defaultValue) as T?;
    } catch (e, stackTrace) {
      _logger.e('Hive read error: box=$boxName, key=$key', e, stackTrace);
      return defaultValue;
    }
  }

  /// Save value to a box
  Future<void> put<T>(String boxName, String key, T value) async {
    try {
      final box = _getBox(boxName);
      await box.put(key, value);
    } catch (e, stackTrace) {
      _logger.e('Hive write error: box=$boxName, key=$key', e, stackTrace);
      rethrow;
    }
  }

  /// Delete value from a box
  Future<void> delete(String boxName, String key) async {
    try {
      final box = _getBox(boxName);
      await box.delete(key);
    } catch (e, stackTrace) {
      _logger.e('Hive delete error: box=$boxName, key=$key', e, stackTrace);
      rethrow;
    }
  }

  /// Clear all entries from a box
  Future<void> clear(String boxName) async {
    try {
      final box = _getBox(boxName);
      await box.clear();
    } catch (e, stackTrace) {
      _logger.e('Hive clear error: box=$boxName', e, stackTrace);
      rethrow;
    }
  }
}
