import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/core/errors/failures.dart';
import 'package:fidel_learn/features/question_bank/domain/models/question_models.dart';
import 'package:fidel_learn/features/question_bank/domain/services/content_validation_service.dart';
import 'package:fidel_learn/features/subjects/data/repositories/local_content_repository.dart';
import 'package:fidel_learn/features/subjects/domain/models/scientific_asset_manifest.dart';
import 'package:fidel_learn/features/subjects/domain/models/subject_models.dart';

void main() {
  group('Package Scientific Asset Integrity & Activation Gate Tests', () {
    const validSvgContent = '''
<svg viewBox="0 0 200 100" xmlns="http://www.w3.org/2000/svg">
  <rect x="0" y="0" width="200" height="100" fill="blue" />
</svg>
''';
    final validSvgBytes = utf8.encode(validSvgContent);
    final validSvgChecksum = sha256.convert(validSvgBytes).toString();

    const testQuestion = Question(
      id: 'PHY-2016-42',
      subjectId: 'physics_g12',
      unitId: 'unit_1',
      topicId: 'circuits',
      grade: 12,
      stream: 'natural',
      difficulty: 'hard',
      questionTextEn: 'Examine the circuit diagram:',
      verificationStatus: VerificationStatus.published,
      sourceName: 'ESSLCE 2016',
      contentVersion: 1,
      diagramAsset: 'assets/diagrams/circuit_42.svg',
      choices: [
        AnswerChoice(id: 'c1', label: 'A', textEn: '12 V', isCorrect: true),
        AnswerChoice(id: 'c2', label: 'B', textEn: '6 V', isCorrect: false),
      ],
      explanation: Explanation(solutionTextEn: 'Solution rationale'),
    );

    const testPackage = ContentPackage(
      packageId: 'pkg_physics_g12',
      subjectId: 'physics_g12',
      nameEn: 'Physics Grade 12',
      nameAm: 'ፊዚክስ 12ኛ ክፍል',
      grade: 12,
      stream: 'natural',
      version: 1,
      sizeBytes: 1024,
      publisher: 'FidelLearn',
      license: 'demo',
      attribution: 'Attribution',
      isDownloaded: false,
    );

    test(
        '1. Valid scientific package: required SVG exists and checksum matches',
        () {
      final manifest = ScientificAssetManifest(
        packageId: 'pkg_physics_g12',
        version: 1,
        assets: [
          ScientificAssetEntry(
            assetId: 'circuit_42',
            assetType: ScientificAssetType.circuitDiagram,
            assetPath: 'assets/diagrams/circuit_42.svg',
            checksum: validSvgChecksum,
            requiredByQuestion: 'PHY-2016-42',
            altText: 'Schematic showing DC bridge network',
            isRequired: true,
          ),
        ],
      );

      final assetFiles = {
        'assets/diagrams/circuit_42.svg': validSvgBytes,
      };

      final report = ContentValidationService.validatePackageScientificAssets(
        packageId: 'pkg_physics_g12',
        questions: [testQuestion],
        manifest: manifest,
        assetFiles: assetFiles,
      );

      expect(report.errorCount, equals(0));
      expect(ContentValidationService.canActivatePackage(report), isTrue);
    });

    test(
        '2. Missing required diagram: validation fails and activation is blocked',
        () async {
      const manifest = ScientificAssetManifest(
        packageId: 'pkg_physics_g12',
        version: 1,
        assets: [
          ScientificAssetEntry(
            assetId: 'circuit_42',
            assetType: ScientificAssetType.circuitDiagram,
            assetPath: 'assets/diagrams/circuit_42.svg',
            requiredByQuestion: 'PHY-2016-42',
            isRequired: true,
          ),
        ],
      );

      // Package payload missing the required asset file
      final assetFiles = <String, List<int>>{};

      final report = ContentValidationService.validatePackageScientificAssets(
        packageId: 'pkg_physics_g12',
        questions: [testQuestion],
        manifest: manifest,
        assetFiles: assetFiles,
      );

      expect(report.errorCount, greaterThan(0));
      expect(
        report.issues.any(
            (i) => i.issueType == ValidationIssueType.missingRequiredAsset),
        isTrue,
      );
      expect(ContentValidationService.canActivatePackage(report), isFalse);

      // Verify LocalContentRepository blocks activation
      final repo = LocalContentRepository();
      repo.initializeWithData(
        packages: [testPackage],
        subjects: [],
        units: [],
        topics: [],
        questions: [testQuestion],
      );
      repo.registerPackageAssetManifest(
        'pkg_physics_g12',
        manifest: manifest,
        assetFiles: assetFiles,
      );

      expect(
        () => repo.downloadPackage('pkg_physics_g12'),
        throwsA(isA<PackageActivationFailure>()),
      );

      final packages = await repo.getPackages(grade: 12, stream: 'natural');
      expect(packages.first.isDownloaded, isFalse);
    });

    test(
        '3. Corrupted diagram: checksum mismatch fails validation and blocks activation',
        () async {
      const manifest = ScientificAssetManifest(
        packageId: 'pkg_physics_g12',
        version: 1,
        assets: [
          ScientificAssetEntry(
            assetId: 'circuit_42',
            assetType: ScientificAssetType.circuitDiagram,
            assetPath: 'assets/diagrams/circuit_42.svg',
            checksum: 'expected_different_sha256_hash_value',
            requiredByQuestion: 'PHY-2016-42',
            isRequired: true,
          ),
        ],
      );

      final assetFiles = {
        'assets/diagrams/circuit_42.svg': validSvgBytes,
      };

      final report = ContentValidationService.validatePackageScientificAssets(
        packageId: 'pkg_physics_g12',
        questions: [testQuestion],
        manifest: manifest,
        assetFiles: assetFiles,
      );

      expect(report.errorCount, greaterThan(0));
      expect(
        report.issues.any(
            (i) => i.issueType == ValidationIssueType.corruptAssetChecksum),
        isTrue,
      );
      expect(ContentValidationService.canActivatePackage(report), isFalse);

      final repo = LocalContentRepository();
      repo.initializeWithData(
        packages: [testPackage],
        subjects: [],
        units: [],
        topics: [],
        questions: [testQuestion],
      );
      repo.registerPackageAssetManifest(
        'pkg_physics_g12',
        manifest: manifest,
        assetFiles: assetFiles,
      );

      expect(
        () => repo.downloadPackage('pkg_physics_g12'),
        throwsA(isA<PackageActivationFailure>()),
      );
    });

    test('4. Broken SVG: malformed XML tags fail validation', () {
      const brokenSvgContent = '<div>This is not valid SVG markup</div>';
      final brokenBytes = utf8.encode(brokenSvgContent);

      const manifest = ScientificAssetManifest(
        packageId: 'pkg_physics_g12',
        version: 1,
        assets: [
          ScientificAssetEntry(
            assetId: 'circuit_42',
            assetType: ScientificAssetType.circuitDiagram,
            assetPath: 'assets/diagrams/circuit_42.svg',
            requiredByQuestion: 'PHY-2016-42',
          ),
        ],
      );

      final assetFiles = {
        'assets/diagrams/circuit_42.svg': brokenBytes,
      };

      final report = ContentValidationService.validatePackageScientificAssets(
        packageId: 'pkg_physics_g12',
        questions: [testQuestion],
        manifest: manifest,
        assetFiles: assetFiles,
      );

      expect(report.errorCount, greaterThan(0));
      expect(
        report.issues
            .any((i) => i.issueType == ValidationIssueType.malformedSvgDiagram),
        isTrue,
      );
      expect(ContentValidationService.canActivatePackage(report), isFalse);
    });

    test(
        '5. Unsupported asset format: flags non-standard extensions as critical error',
        () {
      final badExtQuestion = testQuestion.copyWith(
        diagramAsset: 'assets/diagrams/circuit_42.bmp',
      );

      const manifest = ScientificAssetManifest(
        packageId: 'pkg_physics_g12',
        version: 1,
        assets: [
          ScientificAssetEntry(
            assetId: 'circuit_42',
            assetType: ScientificAssetType.generic,
            assetPath: 'assets/diagrams/circuit_42.bmp',
            requiredByQuestion: 'PHY-2016-42',
          ),
        ],
      );

      final report = ContentValidationService.validatePackageScientificAssets(
        packageId: 'pkg_physics_g12',
        questions: [badExtQuestion],
        manifest: manifest,
      );

      expect(report.errorCount, greaterThan(0));
      expect(
        report.issues.any(
            (i) => i.issueType == ValidationIssueType.unsupportedAssetFormat),
        isTrue,
      );
      expect(ContentValidationService.canActivatePackage(report), isFalse);
    });

    test(
        '6. Missing alt-text produces warning without blocking package activation',
        () {
      final manifest = ScientificAssetManifest(
        packageId: 'pkg_physics_g12',
        version: 1,
        assets: [
          ScientificAssetEntry(
            assetId: 'circuit_42',
            assetType: ScientificAssetType.circuitDiagram,
            assetPath: 'assets/diagrams/circuit_42.svg',
            checksum: validSvgChecksum,
            requiredByQuestion: 'PHY-2016-42',
            altText: null, // Missing accessibility metadata
            isRequired: true,
          ),
        ],
      );

      final assetFiles = {
        'assets/diagrams/circuit_42.svg': validSvgBytes,
      };

      final report = ContentValidationService.validatePackageScientificAssets(
        packageId: 'pkg_physics_g12',
        questions: [testQuestion],
        manifest: manifest,
        assetFiles: assetFiles,
      );

      // Error count is 0, so activation is permitted
      expect(report.errorCount, equals(0));
      expect(ContentValidationService.canActivatePackage(report), isTrue);

      // Warning count is 1 for missing alt text
      expect(report.warningCount, equals(1));
      expect(
        report.issues
            .any((i) => i.issueType == ValidationIssueType.missingAltText),
        isTrue,
      );
    });
  });
}
