import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

enum NetworkStatus {
  onlineWifi,
  onlineCellular,
  onlineEthernet,
  offline,
}

abstract class ConnectivityService {
  Future<bool> get isOnline;
  Future<NetworkStatus> get currentStatus;
  Stream<NetworkStatus> get onStatusChanged;
  void dispose();
}

class ConnectivityPlusService implements ConnectivityService {
  final Connectivity _connectivity;
  final StreamController<NetworkStatus> _controller =
      StreamController<NetworkStatus>.broadcast();
  StreamSubscription<dynamic>? _subscription;

  ConnectivityPlusService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity() {
    _init();
  }

  void _init() {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final status = _mapResultToStatus(results);
      _controller.add(status);
    });
  }

  NetworkStatus _mapResultToStatus(dynamic result) {
    if (result is List<ConnectivityResult>) {
      if (result.contains(ConnectivityResult.wifi)) {
        return NetworkStatus.onlineWifi;
      }
      if (result.contains(ConnectivityResult.mobile)) {
        return NetworkStatus.onlineCellular;
      }
      if (result.contains(ConnectivityResult.ethernet)) {
        return NetworkStatus.onlineEthernet;
      }
      if (result.contains(ConnectivityResult.none)) {
        return NetworkStatus.offline;
      }
      return result.isNotEmpty
          ? NetworkStatus.onlineWifi
          : NetworkStatus.offline;
    } else if (result is ConnectivityResult) {
      switch (result) {
        case ConnectivityResult.wifi:
          return NetworkStatus.onlineWifi;
        case ConnectivityResult.mobile:
          return NetworkStatus.onlineCellular;
        case ConnectivityResult.ethernet:
          return NetworkStatus.onlineEthernet;
        case ConnectivityResult.none:
        default:
          return NetworkStatus.offline;
      }
    }
    return NetworkStatus.offline;
  }

  @override
  Future<bool> get isOnline async {
    final result = await _connectivity.checkConnectivity();
    final status = _mapResultToStatus(result);
    return status != NetworkStatus.offline;
  }

  @override
  Future<NetworkStatus> get currentStatus async {
    final result = await _connectivity.checkConnectivity();
    return _mapResultToStatus(result);
  }

  @override
  Stream<NetworkStatus> get onStatusChanged => _controller.stream;

  @override
  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}

class MockConnectivityService implements ConnectivityService {
  bool _isOnline;
  final StreamController<NetworkStatus> _controller =
      StreamController<NetworkStatus>.broadcast();

  MockConnectivityService({bool initialOnline = true})
      : _isOnline = initialOnline;

  void setOnline(bool online) {
    _isOnline = online;
    _controller.add(
      online ? NetworkStatus.onlineWifi : NetworkStatus.offline,
    );
  }

  @override
  Future<bool> get isOnline async => _isOnline;

  @override
  Future<NetworkStatus> get currentStatus async =>
      _isOnline ? NetworkStatus.onlineWifi : NetworkStatus.offline;

  @override
  Stream<NetworkStatus> get onStatusChanged => _controller.stream;

  @override
  void dispose() {
    _controller.close();
  }
}
