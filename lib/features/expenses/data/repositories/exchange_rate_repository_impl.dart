import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../../shared/repositories/base_repository.dart';
import '../../domain/repositories/exchange_rate_repository.dart';
import '../datasources/exchange_rate_remote_datasource.dart';

@LazySingleton(as: ExchangeRateRepository)
class ExchangeRateRepositoryImpl extends BaseRepository
    implements ExchangeRateRepository {
  final ExchangeRateRemoteDataSource _remote;

  ExchangeRateRepositoryImpl(this._remote);

  @override
  Future<Result<Map<String, double>>> getUsdRates() {
    return safeCall(_remote.fetchUsdRates);
  }
}
