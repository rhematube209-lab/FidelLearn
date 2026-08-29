import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/features/p2p_transfer/domain/models/p2p_models.dart';
import 'package:fidel_learn/features/p2p_transfer/domain/services/p2p_transfer_service.dart';
import 'package:fidel_learn/features/p2p_transfer/data/repositories/local_p2p_repository.dart';

void main() {
  group('P2PTransferService & LocalP2PRepository Tests', () {
    late P2PTransferService service;
    late LocalP2PRepository repository;

    setUp(() {
      service = P2PTransferService();
      repository = LocalP2PRepository(service: service);
    });

    test('generates valid 6-digit numeric pairing PIN', () {
      final pin = service.generatePairingPin();
      expect(pin.length, 6);
      expect(int.tryParse(pin), isNotNull);
    });

    test('computes consistent SHA-256 checksums', () {
      final data1 = [1, 2, 3, 4, 5];
      final data2 = [1, 2, 3, 4, 5];
      final hash1 = service.computeSha256(data1);
      final hash2 = service.computeSha256(data2);
      expect(hash1, hash2);
      expect(hash1.length, 64);
    });

    test('starts and stops sender beacon with package manifest', () async {
      final packages = await repository.getShareablePackages();
      expect(packages.isNotEmpty, isTrue);

      final beacon = await repository.startSharing(
        packageIds: [packages.first.packageId],
      );

      expect(beacon.pairingPin.length, 6);
      expect(beacon.availablePackages.isNotEmpty, isTrue);
      expect(beacon.connectionQrString.startsWith('FIDEL_P2P:v1:'), isTrue);

      final active = service.getActiveBeacon(beacon.sessionId);
      expect(active, isNotNull);

      await repository.stopSharing(beacon.sessionId);
      expect(service.getActiveBeacon(beacon.sessionId), isNull);
    });

    test('rejects receiver transfer if PIN is incorrect', () async {
      final packages = await repository.getShareablePackages();
      final beacon = await repository.startSharing(
        packageIds: [packages.first.packageId],
      );

      final progressEvents = await repository
          .receivePackage(
            beacon: beacon,
            packageId: packages.first.packageId,
            pin: '000000', // Incorrect PIN
          )
          .toList();

      final failedState = progressEvents.last;
      expect(failedState.status, P2PTransferStatus.failed);
      expect(failedState.errorMessage, contains('Invalid 6-digit pairing PIN'));
    });

    test('completes end-to-end chunked P2P transfer with verified checksum', () async {
      final packages = await repository.getShareablePackages();
      final targetPkg = packages.first;
      final beacon = await repository.startSharing(
        packageIds: [targetPkg.packageId],
      );

      final progressEvents = await repository
          .receivePackage(
            beacon: beacon,
            packageId: targetPkg.packageId,
            pin: beacon.pairingPin, // Correct PIN
          )
          .toList();

      expect(progressEvents.any((p) => p.status == P2PTransferStatus.transferring), isTrue);
      expect(progressEvents.any((p) => p.status == P2PTransferStatus.verifyingChecksum), isTrue);
      expect(progressEvents.last.status, P2PTransferStatus.completed);
      expect(progressEvents.last.progressRatio, 1.0);
    });
  });
}
