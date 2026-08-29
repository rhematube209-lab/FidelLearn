import 'package:equatable/equatable.dart';

enum P2PTransferStatus {
  idle,
  discovering,
  connecting,
  authorizing,
  transferring,
  verifyingChecksum,
  completed,
  failed;

  String get label {
    switch (this) {
      case P2PTransferStatus.idle:
        return 'Ready';
      case P2PTransferStatus.discovering:
        return 'Searching for Sender...';
      case P2PTransferStatus.connecting:
        return 'Connecting to Peer...';
      case P2PTransferStatus.authorizing:
        return 'Verifying PIN Authorization...';
      case P2PTransferStatus.transferring:
        return 'Transferring Package Data...';
      case P2PTransferStatus.verifyingChecksum:
        return 'Validating SHA-256 Checksum...';
      case P2PTransferStatus.completed:
        return 'Transfer Complete & Verified!';
      case P2PTransferStatus.failed:
        return 'Transfer Failed';
    }
  }
}

class P2PPackageManifest extends Equatable {
  final String packageId;
  final String title;
  final int grade;
  final String stream;
  final int questionCount;
  final int fileSizeBytes;
  final String sha256Checksum;
  final String version;

  const P2PPackageManifest({
    required this.packageId,
    required this.title,
    required this.grade,
    required this.stream,
    required this.questionCount,
    required this.fileSizeBytes,
    required this.sha256Checksum,
    required this.version,
  });

  Map<String, dynamic> toJson() => {
        'packageId': packageId,
        'title': title,
        'grade': grade,
        'stream': stream,
        'questionCount': questionCount,
        'fileSizeBytes': fileSizeBytes,
        'sha256Checksum': sha256Checksum,
        'version': version,
      };

  factory P2PPackageManifest.fromJson(Map<String, dynamic> json) {
    return P2PPackageManifest(
      packageId: json['packageId'] as String,
      title: json['title'] as String,
      grade: json['grade'] as int,
      stream: json['stream'] as String,
      questionCount: json['questionCount'] as int,
      fileSizeBytes: json['fileSizeBytes'] as int,
      sha256Checksum: json['sha256Checksum'] as String,
      version: json['version'] as String,
    );
  }

  @override
  List<Object?> get props => [
        packageId,
        title,
        grade,
        stream,
        questionCount,
        fileSizeBytes,
        sha256Checksum,
        version,
      ];
}

class P2PSenderBeacon extends Equatable {
  final String sessionId;
  final String hostAddress;
  final int port;
  final String pairingPin;
  final List<P2PPackageManifest> availablePackages;
  final DateTime startedAt;

  const P2PSenderBeacon({
    required this.sessionId,
    required this.hostAddress,
    required this.port,
    required this.pairingPin,
    required this.availablePackages,
    required this.startedAt,
  });

  String get connectionQrString =>
      'FIDEL_P2P:v1:$hostAddress:$port:$pairingPin';

  @override
  List<Object?> get props => [
        sessionId,
        hostAddress,
        port,
        pairingPin,
        availablePackages,
        startedAt,
      ];
}

class P2PTransferProgress extends Equatable {
  final int bytesTransferred;
  final int totalBytes;
  final double progressRatio;
  final double speedKbps;
  final P2PTransferStatus status;
  final String? errorMessage;
  final String? currentPackageId;

  const P2PTransferProgress({
    this.bytesTransferred = 0,
    this.totalBytes = 0,
    this.progressRatio = 0.0,
    this.speedKbps = 0.0,
    this.status = P2PTransferStatus.idle,
    this.errorMessage,
    this.currentPackageId,
  });

  P2PTransferProgress copyWith({
    int? bytesTransferred,
    int? totalBytes,
    double? progressRatio,
    double? speedKbps,
    P2PTransferStatus? status,
    String? errorMessage,
    String? currentPackageId,
  }) {
    return P2PTransferProgress(
      bytesTransferred: bytesTransferred ?? this.bytesTransferred,
      totalBytes: totalBytes ?? this.totalBytes,
      progressRatio: progressRatio ?? this.progressRatio,
      speedKbps: speedKbps ?? this.speedKbps,
      status: status ?? this.status,
      errorMessage: errorMessage,
      currentPackageId: currentPackageId ?? this.currentPackageId,
    );
  }

  @override
  List<Object?> get props => [
        bytesTransferred,
        totalBytes,
        progressRatio,
        speedKbps,
        status,
        errorMessage,
        currentPackageId,
      ];
}
