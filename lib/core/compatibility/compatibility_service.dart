enum UpdateAction {
  none,
  recommended,
  required,
}

class CompatibilityResult {
  final UpdateAction action;
  final String currentVersion;
  final String? minimumSupportedVersion;
  final String? recommendedVersion;
  final String? latestVersion;
  final String? messageEn;
  final String? messageAm;
  final bool isOfflineFallback;

  const CompatibilityResult({
    required this.action,
    required this.currentVersion,
    this.minimumSupportedVersion,
    this.recommendedVersion,
    this.latestVersion,
    this.messageEn,
    this.messageAm,
    this.isOfflineFallback = false,
  });

  bool get isBlocked => action == UpdateAction.required;

  factory CompatibilityResult.offlineFallback(String version) {
    return CompatibilityResult(
      action: UpdateAction.none,
      currentVersion: version,
      isOfflineFallback: true,
      messageEn:
          'Running in offline mode. Local study materials are accessible.',
      messageAm: 'ከመስመር ውጭ እየሰራ ነው። የወረዱ የፈተና ይዘቶች ይሰራሉ።',
    );
  }
}

/// Service for validating client version compatibility against server policy.
class CompatibilityService {
  CompatibilityService._();

  /// Compares two semver strings (v1 vs v2).
  /// Returns:
  ///   1 if v1 > v2
  ///  -1 if v1 < v2
  ///   0 if v1 == v2
  static int compareSemver(String v1, String v2) {
    final clean1 = v1.split('+').first.split('-').first;
    final clean2 = v2.split('+').first.split('-').first;

    final parts1 = clean1.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final parts2 = clean2.split('.').map((p) => int.tryParse(p) ?? 0).toList();

    while (parts1.length < 3) {
      parts1.add(0);
    }
    while (parts2.length < 3) {
      parts2.add(0);
    }

    for (int i = 0; i < 3; i++) {
      if (parts1[i] > parts2[i]) return 1;
      if (parts1[i] < parts2[i]) return -1;
    }
    return 0;
  }

  /// Evaluates compatibility from local parameters or server response.
  static CompatibilityResult evaluate({
    required String currentVersion,
    required String minimumSupportedVersion,
    required String recommendedVersion,
    required String latestVersion,
    String? messageEn,
    String? messageAm,
  }) {
    final cmpMin = compareSemver(currentVersion, minimumSupportedVersion);
    final cmpRec = compareSemver(currentVersion, recommendedVersion);

    if (cmpMin < 0) {
      return CompatibilityResult(
        action: UpdateAction.required,
        currentVersion: currentVersion,
        minimumSupportedVersion: minimumSupportedVersion,
        recommendedVersion: recommendedVersion,
        latestVersion: latestVersion,
        messageEn: messageEn ??
            'Please update FidelLearn to continue accessing exams.',
        messageAm: messageAm ?? 'እባክዎ ፈተናዎችን ለማግኘት መተግበሪያውን ያዘምኑ።',
      );
    } else if (cmpRec < 0) {
      return CompatibilityResult(
        action: UpdateAction.recommended,
        currentVersion: currentVersion,
        minimumSupportedVersion: minimumSupportedVersion,
        recommendedVersion: recommendedVersion,
        latestVersion: latestVersion,
        messageEn: messageEn ??
            'A newer version of FidelLearn is available with performance improvements.',
        messageAm: 'አዲስ የፊደል ለርን ስሪት ተዘጋጅቷል።',
      );
    }

    return CompatibilityResult(
      action: UpdateAction.none,
      currentVersion: currentVersion,
      minimumSupportedVersion: minimumSupportedVersion,
      recommendedVersion: recommendedVersion,
      latestVersion: latestVersion,
    );
  }
}
