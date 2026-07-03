import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';
import 'app_logger.dart';

@singleton
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final AppLogger _logger;
  
  final StreamController<bool> _connectionStreamController = StreamController<bool>.broadcast();

  ConnectivityService(this._logger) {
    _connectivity.onConnectivityChanged.listen((results) {
      final isConnected = _hasInternet(results);
      _logger.d('Connectivity changed: isConnected = $isConnected (results: $results)');
      _connectionStreamController.add(isConnected);
    });
  }

  /// Broadcast stream showing connection status (true = connected, false = disconnected)
  Stream<bool> get onConnectionChanged => _connectionStreamController.stream;

  /// Checks if device currently has internet access
  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return _hasInternet(result);
  }

  bool _hasInternet(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    // If only 'none' is present, there is no network.
    if (results.length == 1 && results.first == ConnectivityResult.none) {
      return false;
    }
    return !results.contains(ConnectivityResult.none);
  }

  void dispose() {
    _connectionStreamController.close();
  }
}
