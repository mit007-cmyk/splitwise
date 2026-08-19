import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';

import '../../../../core/errors/exceptions.dart';

abstract class ExchangeRateRemoteDataSource {
  /// Units of each ISO code per 1 USD.
  Future<Map<String, double>> fetchUsdRates();
}

@LazySingleton(as: ExchangeRateRemoteDataSource)
class ExchangeRateRemoteDataSourceImpl implements ExchangeRateRemoteDataSource {
  static final _uri = Uri.parse('https://open.er-api.com/v6/latest/USD');

  final http.Client _client = http.Client();

  ExchangeRateRemoteDataSourceImpl();

  @override
  Future<Map<String, double>> fetchUsdRates() async {
    final response = await _client.get(_uri);
    if (response.statusCode != 200) {
      throw const NetworkException(
        message: 'Could not load current exchange rates.',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const ServerException(message: 'Unexpected exchange-rate response.');
    }
    if ((decoded['result'] as String?) != 'success') {
      throw ServerException(
        message: (decoded['error-type'] as String?) ??
            'Could not load current exchange rates.',
      );
    }
    final rawRates = decoded['rates'];
    if (rawRates is! Map) {
      throw const ServerException(message: 'Exchange rates were missing.');
    }

    final rates = <String, double>{'USD': 1};
    rawRates.forEach((key, value) {
      final code = key.toString().trim().toUpperCase();
      final amount = (value as num?)?.toDouble();
      if (code.isEmpty || amount == null || amount <= 0) return;
      rates[code] = amount;
    });
    return rates;
  }
}
