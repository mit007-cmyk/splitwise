import 'dart:convert';
import 'package:injectable/injectable.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/hive_service.dart';
import '../models/home_summary_model.dart';

abstract class HomeLocalDataSource {
  Future<void> cacheHomeSummary(String userId, HomeSummaryModel summary);
  Future<HomeSummaryModel?> getCachedHomeSummary(String userId);
  Future<void> clearCache(String userId);
}

@LazySingleton(as: HomeLocalDataSource)
class HomeLocalDataSourceImpl implements HomeLocalDataSource {
  final HiveService _hiveService;
  static const _cachePrefix = 'home_summary_';

  HomeLocalDataSourceImpl(this._hiveService);

  @override
  Future<void> cacheHomeSummary(String userId, HomeSummaryModel summary) async {
    final String jsonStr = jsonEncode(summary.toJson());
    await _hiveService.put(AppConstants.hiveCacheBox, '$_cachePrefix$userId', jsonStr);
  }

  @override
  Future<HomeSummaryModel?> getCachedHomeSummary(String userId) async {
    final String? jsonStr = _hiveService.get<String>(
      AppConstants.hiveCacheBox,
      '$_cachePrefix$userId',
    );
    if (jsonStr == null) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return HomeSummaryModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearCache(String userId) async {
    await _hiveService.delete(AppConstants.hiveCacheBox, '$_cachePrefix$userId');
  }
}
