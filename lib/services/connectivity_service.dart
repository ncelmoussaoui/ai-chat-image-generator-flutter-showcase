import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Service for monitoring network connectivity
class ConnectivityService {
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  final _controller = StreamController<bool>.broadcast();

  bool _isConnected = true;

  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  /// Stream of connectivity status
  Stream<bool> get onConnectivityChanged => _controller.stream;

  /// Current connectivity status
  bool get isConnected => _isConnected;

  /// Initialize the connectivity service
  Future<void> init() async {
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);

    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final connected = results.isNotEmpty &&
        results.any((r) => r != ConnectivityResult.none);

    if (_isConnected != connected) {
      _isConnected = connected;
      _controller.add(_isConnected);
    }
  }

  /// Check current connectivity status
  Future<bool> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);
    return _isConnected;
  }

  /// Dispose of resources
  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
