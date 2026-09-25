import 'dart:async';
import '../models/exam_mode.dart';

/// Clock interface to allow deterministic time injection in tests
typedef ClockProvider = DateTime Function();

/// Authoritative timer service for examination sessions.
/// Derives remaining duration from wall-clock timestamps rather than UI counters alone,
/// guaranteeing interruption safety, background survival, and auto-submit triggers.
class AuthoritativeExamTimer {
  final DateTime startTime;
  final int totalDurationSeconds;
  final NationalExamPolicy policy;
  final ClockProvider clock;

  final int _elapsedPausedSeconds;
  DateTime? _lastActiveTime;
  bool _timerIntegrityWarning;
  Timer? _periodicTimer;
  final _tickController = StreamController<int>.broadcast();

  AuthoritativeExamTimer({
    required this.startTime,
    required this.totalDurationSeconds,
    required this.policy,
    int elapsedPausedSeconds = 0,
    DateTime? lastActiveTime,
    bool initialIntegrityWarning = false,
    ClockProvider? clock,
  })  : clock = clock ?? DateTime.now,
        _elapsedPausedSeconds = elapsedPausedSeconds,
        _lastActiveTime = lastActiveTime,
        _timerIntegrityWarning = initialIntegrityWarning;

  /// Stream of remaining seconds, updated every second
  Stream<int> get ticks => _tickController.stream;

  bool get timerIntegrityWarning => _timerIntegrityWarning;
  int get elapsedPausedSeconds => _elapsedPausedSeconds;

  /// Authoritatively computes remaining seconds based on wall-clock elapsed time
  int getRemainingSeconds() {
    if (totalDurationSeconds <= 0) return 0; // Untimed exam

    final now = clock();

    // Clock manipulation detection: clock moved backwards significantly
    if (_lastActiveTime != null &&
        now.isBefore(_lastActiveTime!.subtract(const Duration(seconds: 15)))) {
      _timerIntegrityWarning = true;
    }
    _lastActiveTime = now;

    final int elapsed;
    if (policy.strictWallClock || !policy.allowPause) {
      // Wall-clock authoritative: background duration counts as exam time
      elapsed = now.difference(startTime).inSeconds;
    } else {
      // Non-strict: minus explicit paused time
      final rawElapsed = now.difference(startTime).inSeconds;
      elapsed = rawElapsed - _elapsedPausedSeconds;
    }

    final remaining = totalDurationSeconds - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  /// Whether the exam has expired (reached 0 seconds)
  bool get isExpired => totalDurationSeconds > 0 && getRemainingSeconds() <= 0;

  /// Elapsed duration in seconds
  int getElapsedSeconds() {
    if (totalDurationSeconds <= 0) {
      return clock().difference(startTime).inSeconds;
    }
    return totalDurationSeconds - getRemainingSeconds();
  }

  /// Starts or resumes the periodic 1-second ticker
  void start() {
    _periodicTimer?.cancel();
    _tickController.add(getRemainingSeconds());

    _periodicTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = getRemainingSeconds();
      _tickController.add(remaining);
      if (remaining <= 0) {
        _periodicTimer?.cancel();
      }
    });
  }

  /// Stops the ticker (e.g., when exam is submitted or screen disposed)
  void stop() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  /// Disposes timer resources
  void dispose() {
    stop();
    _tickController.close();
  }

  /// Formats remaining seconds as HH:MM:SS or MM:SS
  static String formatDuration(int totalSeconds) {
    if (totalSeconds < 0) totalSeconds = 0;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final mStr = minutes.toString().padLeft(2, '0');
    final sStr = seconds.toString().padLeft(2, '0');

    if (hours > 0) {
      final hStr = hours.toString().padLeft(2, '0');
      return '$hStr:$mStr:$sStr';
    } else {
      return '$mStr:$sStr';
    }
  }

  /// Checks if crossing a warning threshold (e.g. 30, 10, 5, 1 minute)
  static int? checkWarningThreshold({
    required int previousRemaining,
    required int currentRemaining,
    required List<int> thresholdsMinutes,
  }) {
    for (final m in thresholdsMinutes) {
      final threshSec = m * 60;
      if (previousRemaining > threshSec && currentRemaining <= threshSec) {
        return m;
      }
    }
    return null;
  }
}
