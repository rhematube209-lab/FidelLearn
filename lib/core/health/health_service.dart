import 'dart:async';
import '../config/env_config.dart';
import '../config/release_info.dart';
import '../networking/connectivity_service.dart';

enum SystemOperationalStatus {
  operational,
  degraded,
  unavailable,
}

class HealthReport {
  final SystemOperationalStatus status;
  final bool isAlive;
  final bool isReady;
  final bool isDatabaseReady;
  final bool isBackendReachable;
  final String environment;
  final DateTime checkedAt;
  final Map<String, dynamic> details;

  HealthReport({
    required this.status,
    required this.isAlive,
    required this.isReady,
    required this.isDatabaseReady,
    required this.isBackendReachable,
    required this.environment,
    required this.checkedAt,
    required this.details,
  });

  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'is_alive': isAlive,
      'is_ready': isReady,
      'database_ready': isDatabaseReady,
      'backend_reachable': isBackendReachable,
      'environment': environment,
      'checked_at': checkedAt.toUtc().toIso8601String(),
      'release': ReleaseInfo.toDiagnosticMap(),
      'details': details,
    };
  }
}

/// Service for monitoring application liveness and backend readiness.
class HealthService {
  final ConnectivityService _connectivityService;
  final Future<bool> Function()? _dbCheck;
  final Future<bool> Function()? _remoteCheck;

  HealthService({
    required ConnectivityService connectivityService,
    Future<bool> Function()? dbCheck,
    Future<bool> Function()? remoteCheck,
  })  : _connectivityService = connectivityService,
        _dbCheck = dbCheck,
        _remoteCheck = remoteCheck;

  /// Performs a comprehensive health and readiness evaluation.
  Future<HealthReport> checkHealth() async {
    final now = DateTime.now();
    bool isDbOk = true;
    bool isRemoteOk = false;
    final isOnline = await _connectivityService.isOnline;

    if (_dbCheck != null) {
      try {
        isDbOk = await _dbCheck();
      } catch (_) {
        isDbOk = false;
      }
    }

    if (isOnline && _remoteCheck != null) {
      try {
        isRemoteOk = await _remoteCheck();
      } catch (_) {
        isRemoteOk = false;
      }
    } else if (isOnline && EnvConfig.isSupabaseConfigured) {
      isRemoteOk = true;
    } else if (isOnline && EnvConfig.isDevelopment) {
      isRemoteOk = true;
    }

    // Determine operational status
    SystemOperationalStatus opStatus;
    if (!isDbOk) {
      opStatus = SystemOperationalStatus.unavailable;
    } else if (!isOnline || !isRemoteOk) {
      // Local database works, but remote unavailable: degraded (offline mode operates normally)
      opStatus = SystemOperationalStatus.degraded;
    } else {
      opStatus = SystemOperationalStatus.operational;
    }

    final isReady =
        isDbOk; // In offline-first architecture, local DB ready = app is functional

    return HealthReport(
      status: opStatus,
      isAlive: true,
      isReady: isReady,
      isDatabaseReady: isDbOk,
      isBackendReachable: isRemoteOk,
      environment: EnvConfig.appEnvironment,
      checkedAt: now,
      details: {
        'network_online': isOnline,
        'offline_capable': true,
      },
    );
  }
}
