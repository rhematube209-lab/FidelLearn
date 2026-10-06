import 'dart:io';
import 'package:crypto/crypto.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/logging/app_logger.dart';

class PackageInstallResult {
  final bool success;
  final String packageId;
  final String installedPath;
  final String hash;
  final String? errorMessage;

  const PackageInstallResult({
    required this.success,
    required this.packageId,
    required this.installedPath,
    required this.hash,
    this.errorMessage,
  });
}

/// Service for atomic installation, SHA-256 integrity verification, and safe rollback of .flpkg packages.
class AtomicPackageInstaller {
  final Directory storageDir;

  AtomicPackageInstaller(this.storageDir);

  /// Computes SHA-256 digest of byte content.
  static String computeSha256(List<int> bytes) {
    return sha256.convert(bytes).toString();
  }

  /// Atomically installs package bytes into destination, validating integrity.
  Future<PackageInstallResult> installPackageBytes({
    required String packageId,
    required List<int> packageBytes,
    required String expectedHash,
    Map<String, dynamic>? manifest,
  }) async {
    final opId = AppLogger.generateCorrelationId('pkg-inst');
    final activeFile = File('${storageDir.path}/$packageId.flpkg');
    final tempFile = File('${storageDir.path}/$packageId.flpkg.tmp');
    final backupFile = File('${storageDir.path}/$packageId.flpkg.bak');

    try {
      // 1. Verify SHA-256 integrity of incoming payload
      final computedHash = computeSha256(packageBytes);
      if (computedHash.toLowerCase() != expectedHash.toLowerCase()) {
        AppLogger.warning(
          service: 'AtomicPackageInstaller',
          operation: 'installPackageBytes',
          correlationId: opId,
          errorCode: 'HASH_MISMATCH',
          message:
              'Package hash mismatch for $packageId: expected $expectedHash, got $computedHash',
        );
        throw InvalidPackageFailure(
          'Hash mismatch: expected $expectedHash, got $computedHash',
        );
      }

      // 2. Validate manifest if provided
      if (manifest != null &&
          (!manifest.containsKey('subject_id') ||
              !manifest.containsKey('version'))) {
        throw const InvalidPackageFailure(
            'Manifest is missing required subject_id or version fields');
      }

      // 3. Write payload to temporary file
      await tempFile.writeAsBytes(packageBytes, flush: true);

      // 4. Create backup of existing active version if present
      if (await activeFile.exists()) {
        if (await backupFile.exists()) {
          await backupFile.delete();
        }
        await activeFile.copy(backupFile.path);
      }

      // 5. Atomic rename: temp -> active
      if (await activeFile.exists()) {
        await activeFile.delete();
      }
      await tempFile.rename(activeFile.path);

      AppLogger.info(
        service: 'AtomicPackageInstaller',
        operation: 'installPackageBytes',
        correlationId: opId,
        message:
            'Successfully installed package $packageId (hash: $computedHash)',
      );

      return PackageInstallResult(
        success: true,
        packageId: packageId,
        installedPath: activeFile.path,
        hash: computedHash,
      );
    } catch (e) {
      // Rollback: Clean up temp file
      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }

      // Restore backup if active was lost
      if (!await activeFile.exists() && await backupFile.exists()) {
        try {
          await backupFile.rename(activeFile.path);
        } catch (_) {}
      }

      return PackageInstallResult(
        success: false,
        packageId: packageId,
        installedPath: activeFile.path,
        hash: '',
        errorMessage: e.toString(),
      );
    }
  }
}
