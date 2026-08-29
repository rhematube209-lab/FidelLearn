import 'package:fidel_learn/features/p2p_transfer/domain/models/p2p_models.dart';
import 'package:fidel_learn/features/p2p_transfer/domain/services/p2p_transfer_service.dart';

abstract class P2PRepository {
  Future<List<P2PPackageManifest>> getShareablePackages();
  Future<P2PSenderBeacon> startSharing({required List<String> packageIds});
  Future<void> stopSharing(String sessionId);
  Stream<P2PTransferProgress> receivePackage({
    required P2PSenderBeacon beacon,
    required String packageId,
    required String pin,
  });
}

class LocalP2PRepository implements P2PRepository {
  final P2PTransferService _service;
  final List<P2PPackageManifest> _shareablePackages = [];

  LocalP2PRepository({P2PTransferService? service})
      : _service = service ?? P2PTransferService() {
    _seedPackages();
  }

  void _seedPackages() {
    _shareablePackages.addAll([
      const P2PPackageManifest(
        packageId: 'pkg_g12_math',
        title: 'Grade 12 Mathematics (Natural Stream)',
        grade: 12,
        stream: 'natural',
        questionCount: 20,
        fileSizeBytes: 245000,
        sha256Checksum: 'sha256_mock_math_g12_v1',
        version: '1.0.0',
      ),
      const P2PPackageManifest(
        packageId: 'pkg_g12_aptitude',
        title: 'Grade 12 Scholastic Aptitude Test',
        grade: 12,
        stream: 'common',
        questionCount: 15,
        fileSizeBytes: 180000,
        sha256Checksum: 'sha256_mock_aptitude_v1',
        version: '1.0.0',
      ),
    ]);
  }

  @override
  Future<List<P2PPackageManifest>> getShareablePackages() async {
    return List.unmodifiable(_shareablePackages);
  }

  @override
  Future<P2PSenderBeacon> startSharing({
    required List<String> packageIds,
  }) async {
    final selected = _shareablePackages
        .where((p) => packageIds.contains(p.packageId))
        .toList();

    return _service.startSenderBeacon(
      hostAddress: '192.168.43.1', // Standard Wi-Fi Hotspot Gateway
      port: 8088,
      packages: selected.isNotEmpty ? selected : _shareablePackages,
    );
  }

  @override
  Future<void> stopSharing(String sessionId) async {
    _service.stopSenderBeacon(sessionId);
  }

  @override
  Stream<P2PTransferProgress> receivePackage({
    required P2PSenderBeacon beacon,
    required String packageId,
    required String pin,
  }) {
    return _service.downloadPackageStream(
      beacon: beacon,
      packageId: packageId,
      enteredPin: pin,
    );
  }
}
