import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

import '../models/p2p_models.dart';

class P2PTransferService {
  final Map<String, P2PSenderBeacon> _activeBeacons = {};
  final Map<String, List<int>> _packagePayloads = {};

  String generatePairingPin() {
    final rand = Random();
    final pin = (100000 + rand.nextInt(900000)).toString();
    return pin;
  }

  String computeSha256(List<int> bytes) {
    return sha256.convert(bytes).toString();
  }

  P2PSenderBeacon startSenderBeacon({
    required String hostAddress,
    required int port,
    required List<P2PPackageManifest> packages,
    Map<String, List<int>>? packageBytesMap,
  }) {
    final pin = generatePairingPin();
    final sessionId = 'p2p_session_${DateTime.now().millisecondsSinceEpoch}';

    final beacon = P2PSenderBeacon(
      sessionId: sessionId,
      hostAddress: hostAddress,
      port: port,
      pairingPin: pin,
      availablePackages: packages,
      startedAt: DateTime.now(),
    );

    _activeBeacons[beacon.sessionId] = beacon;

    if (packageBytesMap != null) {
      _packagePayloads.addAll(packageBytesMap);
    } else {
      // Seed fallback binary payload for packages
      for (final pkg in packages) {
        final samplePayload = utf8.encode(
          jsonEncode({
            'packageId': pkg.packageId,
            'title': pkg.title,
            'version': pkg.version,
            'grade': pkg.grade,
            'stream': pkg.stream,
            'questionCount': pkg.questionCount,
            'timestamp': DateTime.now().toIso8601String(),
          }),
        );
        _packagePayloads[pkg.packageId] = samplePayload;
      }
    }

    return beacon;
  }

  void stopSenderBeacon(String sessionId) {
    _activeBeacons.remove(sessionId);
  }

  P2PSenderBeacon? getActiveBeacon(String sessionId) {
    return _activeBeacons[sessionId];
  }

  Stream<P2PTransferProgress> downloadPackageStream({
    required P2PSenderBeacon beacon,
    required String packageId,
    required String enteredPin,
  }) async* {
    yield P2PTransferProgress(
      status: P2PTransferStatus.connecting,
      currentPackageId: packageId,
    );

    await Future<void>.delayed(const Duration(milliseconds: 150));

    yield P2PTransferProgress(
      status: P2PTransferStatus.authorizing,
      currentPackageId: packageId,
    );

    if (enteredPin.trim() != beacon.pairingPin.trim()) {
      yield P2PTransferProgress(
        status: P2PTransferStatus.failed,
        currentPackageId: packageId,
        errorMessage: 'Invalid 6-digit pairing PIN. Authorization rejected by sender.',
      );
      return;
    }

    final manifest = beacon.availablePackages.firstWhere(
      (p) => p.packageId == packageId,
      orElse: () => throw Exception('Package $packageId not found on sender'),
    );

    final rawBytes = _packagePayloads[packageId] ??
        utf8.encode(jsonEncode({'packageId': packageId, 'title': manifest.title}));
    final totalBytes = rawBytes.length;
    const chunkSize = 256;
    int transferred = 0;

    yield P2PTransferProgress(
      status: P2PTransferStatus.transferring,
      bytesTransferred: 0,
      totalBytes: totalBytes,
      progressRatio: 0.0,
      speedKbps: 450.0,
      currentPackageId: packageId,
    );

    while (transferred < totalBytes) {
      final nextChunk = min(chunkSize, totalBytes - transferred);
      transferred += nextChunk;
      final ratio = transferred / totalBytes;

      await Future<void>.delayed(const Duration(milliseconds: 50));

      yield P2PTransferProgress(
        status: P2PTransferStatus.transferring,
        bytesTransferred: transferred,
        totalBytes: totalBytes,
        progressRatio: ratio,
        speedKbps: 520.0 + (transferred % 50),
        currentPackageId: packageId,
      );
    }

    yield P2PTransferProgress(
      status: P2PTransferStatus.verifyingChecksum,
      bytesTransferred: totalBytes,
      totalBytes: totalBytes,
      progressRatio: 1.0,
      speedKbps: 0.0,
      currentPackageId: packageId,
    );

    await Future<void>.delayed(const Duration(milliseconds: 100));

    final actualHash = computeSha256(rawBytes);
    // If manifest has matching checksum or placeholder, mark completed
    if (manifest.sha256Checksum.isNotEmpty &&
        manifest.sha256Checksum != actualHash &&
        !manifest.sha256Checksum.startsWith('sha256_mock')) {
      yield P2PTransferProgress(
        status: P2PTransferStatus.failed,
        bytesTransferred: totalBytes,
        totalBytes: totalBytes,
        currentPackageId: packageId,
        errorMessage: 'SHA-256 checksum mismatch! Package may be corrupted.',
      );
      return;
    }

    yield P2PTransferProgress(
      status: P2PTransferStatus.completed,
      bytesTransferred: totalBytes,
      totalBytes: totalBytes,
      progressRatio: 1.0,
      speedKbps: 0.0,
      currentPackageId: packageId,
    );
  }
}
