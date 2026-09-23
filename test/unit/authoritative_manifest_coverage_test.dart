import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/features/subjects/domain/models/subject_models.dart';
import 'package:fidel_learn/features/subjects/domain/models/subject_manifest.dart';
import 'package:fidel_learn/features/subjects/domain/services/curriculum_manifest_catalog.dart';
import 'package:fidel_learn/features/subjects/domain/services/curriculum_coverage_service.dart';
import 'package:fidel_learn/features/question_bank/domain/models/question_models.dart';
import 'package:fidel_learn/features/question_bank/domain/services/content_validation_service.dart';

void main() {
  group('Authoritative Curriculum Manifest Catalog', () {
    test('Official MoE curriculum unit counts match verified syllabus', () {
      // Geography must be 8 units (not 6)
      final geo = CurriculumManifestCatalog.findManifest('geography_g12')!;
      expect(geo.totalExpectedCount, equals(8));
      expect(geo.unitsOrDomains.length, equals(8));
      expect(geo.unitsOrDomains.first.titleEn,
          contains('Geographical Information Systems'));
      expect(geo.unitsOrDomains.last.titleEn, contains('Economic Activities'));

      // Economics must be 8 units (not 7)
      final econ = CurriculumManifestCatalog.findManifest('economics_g12')!;
      expect(econ.totalExpectedCount, equals(8));
      expect(econ.unitsOrDomains.length, equals(8));
      expect(econ.unitsOrDomains.last.titleEn, contains('Economic Growth'));
      expect(
          econ.unitsOrDomains.any((u) => u.titleEn.contains('Fiscal Policy')),
          isTrue);

      // Physics must be 9 units (not 10)
      final phys = CurriculumManifestCatalog.findManifest('physics_g12')!;
      expect(phys.totalExpectedCount, equals(9));
      expect(phys.unitsOrDomains.length, equals(9));

      // Chemistry must be 6 units
      final chem = CurriculumManifestCatalog.findManifest('chemistry_g12')!;
      expect(chem.totalExpectedCount, equals(6));

      // Biology must be 6 units
      final bio = CurriculumManifestCatalog.findManifest('biology_g12')!;
      expect(bio.totalExpectedCount, equals(6));

      // History must be 5 units
      final hist = CurriculumManifestCatalog.findManifest('history_g12')!;
      expect(hist.totalExpectedCount, equals(5));

      // Mathematics Natural must be 5 units
      final mathNat = CurriculumManifestCatalog.findManifest(
        'math_g12',
        variantCode: ExamVariantCode.naturalScience,
      )!;
      expect(mathNat.totalExpectedCount, equals(5));

      // Mathematics Social must be 6 units
      final mathSoc = CurriculumManifestCatalog.findManifest(
        'math_g12',
        variantCode: ExamVariantCode.socialScience,
      )!;
      expect(mathSoc.totalExpectedCount, equals(6));

      // English must be 6 skill domains
      final eng = CurriculumManifestCatalog.findManifest('english_g12')!;
      expect(eng.totalExpectedCount, equals(6));
      expect(eng.assessmentStructure, equals(AssessmentStructure.mixed));

      // Scholastic Aptitude must have 2 main domains and 11 skills
      final apt = CurriculumManifestCatalog.findManifest('aptitude_g12')!;
      expect(apt.assessmentStructure, equals(AssessmentStructure.skillBased));
      expect(apt.totalExpectedCount, equals(2));
      expect(
          apt.unitsOrDomains.fold(0, (acc, d) => acc + d.expectedSkills.length),
          equals(11));
    });

    test('All Grade 12 manifests target past exam years 2013-2018 E.C.', () {
      const expectedTargetYears = [2013, 2014, 2015, 2016, 2017, 2018];
      for (final manifest in CurriculumManifestCatalog.allManifests) {
        expect(
          manifest.targetPastExamYears,
          equals(expectedTargetYears),
          reason:
              'Subject ${manifest.manifestId} must target years 2013 to 2018 E.C.',
        );
      }
    });
  });

  group('Decoupled Coverage Metrics Evaluation', () {
    late CurriculumCoverageService service;

    setUp(() {
      service = CurriculumCoverageService();
    });

    test('Computes Curriculum Breadth and Past-Paper Depth independently', () {
      const subject = Subject(
        id: 'geography_g12',
        code: 'GEO12',
        nameEn: 'Geography',
        nameAm: 'ጂኦግራፊ',
        grade: 12,
        stream: 'social',
        scope: SubjectScope.streamExam,
        sortOrder: 1,
      );

      final units = [
        const Unit(
            id: 'geo_u1',
            subjectId: 'geography_g12',
            unitNumber: 1,
            titleEn: 'U1',
            titleAm: 'U1'),
        const Unit(
            id: 'geo_u2',
            subjectId: 'geography_g12',
            unitNumber: 2,
            titleEn: 'U2',
            titleAm: 'U2'),
        const Unit(
            id: 'geo_u3',
            subjectId: 'geography_g12',
            unitNumber: 3,
            titleEn: 'U3',
            titleAm: 'U3'),
        const Unit(
            id: 'geo_u4',
            subjectId: 'geography_g12',
            unitNumber: 4,
            titleEn: 'U4',
            titleAm: 'U4'),
      ];

      // Questions covering 2 units and 2 exam years (2014, 2015), total 5 questions
      final questions = [
        for (int i = 1; i <= 5; i++)
          Question(
            id: 'q$i',
            grade: 12,
            stream: 'social',
            subjectId: 'geography_g12',
            unitId: i <= 3 ? 'geo_u1' : 'geo_u2',
            topicId: 'top1',
            questionTextEn: 'Q$i',
            questionTextAm: 'Q$i Am',
            difficulty: 'medium',
            verificationStatus: VerificationStatus.published,
            sourceName: 'ESSLCE',
            contentVersion: 1,
            choices: const [
              AnswerChoice(id: 'c1', label: 'A', textEn: 'A', isCorrect: true),
              AnswerChoice(id: 'c2', label: 'B', textEn: 'B', isCorrect: false),
            ],
            explanation: const Explanation(
                solutionTextEn: 'Sol', solutionTextAm: 'Sol Am'),
            examYear: i <= 3 ? 2014 : 2015,
          ),
      ];

      final metrics = service.evaluateSubject(
        subject: subject,
        units: units,
        questions: questions,
        stream: 'social',
        enforceAuthoritativeBreadth: true,
      );

      // Total expected units in authoritative manifest = 8
      // Covered units = 2
      // Curriculum Breadth = (2 / 8) * 100 = 25.0%
      expect(metrics.manifestTotalUnits, equals(8));
      expect(metrics.unitsWithQuestions, equals(2));
      expect(metrics.curriculumBreadthPercent, equals(25.0));

      // Past paper depth: 2 covered years out of 6 target years (2013-2018)
      // (2 / 6) * 100 = 33.33%
      expect(metrics.pastPaperDepthPercent, closeTo(33.33, 0.1));

      // Question-Bank depth = 5
      expect(metrics.questionBankDepth, equals(5));

      // Readiness must NOT be readyForLaunch when breadth is incomplete
      expect(metrics.readiness,
          isNot(equals(SubjectLaunchReadiness.readyForLaunch)));
      expect(metrics.blockingGaps, isNotEmpty);
      expect(metrics.blockingGaps.any((g) => g.contains('Curriculum breadth')),
          isTrue);

      // Verify missing target years calculation
      expect(metrics.targetExamYears,
          equals([2013, 2014, 2015, 2016, 2017, 2018]));
      expect(metrics.verifiedExamYears, equals([2014, 2015]));
      expect(metrics.effectiveMissingTargetYears,
          equals([2013, 2016, 2017, 2018]));
    });

    test(
        'Past-Paper Depth is a coverage metric and does not block readyForLaunch when breadth and quality are complete',
        () {
      const subject = Subject(
        id: 'geography_g12',
        code: 'GEO12',
        nameEn: 'Geography',
        nameAm: 'ጂኦግራፊ',
        grade: 12,
        stream: 'social',
        scope: SubjectScope.streamExam,
        sortOrder: 1,
      );

      // Create all 8 units for Geography
      final units = [
        for (int u = 1; u <= 8; u++)
          Unit(
            id: 'geo_u$u',
            subjectId: 'geography_g12',
            unitNumber: u,
            titleEn: 'Unit $u',
            titleAm: 'ክፍል $u',
          ),
      ];

      // Provide questions covering all 8 units, but only for 1 year (2014 E.C.)
      final questions = [
        for (int u = 1; u <= 8; u++)
          Question(
            id: 'geo_q$u',
            grade: 12,
            stream: 'social',
            subjectId: 'geography_g12',
            unitId: 'geo_u$u',
            topicId: 'top_$u',
            questionTextEn: 'Q$u',
            questionTextAm: 'Q$u Am',
            difficulty: 'medium',
            verificationStatus: VerificationStatus.published,
            sourceName: 'ESSLCE 2014',
            contentVersion: 1,
            choices: const [
              AnswerChoice(id: 'c1', label: 'A', textEn: 'A', isCorrect: true),
              AnswerChoice(id: 'c2', label: 'B', textEn: 'B', isCorrect: false),
            ],
            explanation: const Explanation(
              solutionTextEn: 'Detailed explanation for unit',
              solutionTextAm: 'ዝርዝር ማብራሪያ',
            ),
            examYear: 2014,
          ),
      ];

      final metrics = service.evaluateSubject(
        subject: subject,
        units: units,
        questions: questions,
        stream: 'social',
        enforceAuthoritativeBreadth: true,
      );

      // Breadth: 8/8 = 100%
      expect(metrics.curriculumBreadthPercent, equals(100.0));
      // Past paper depth: 1/6 = 16.67%
      expect(metrics.pastPaperDepthPercent, closeTo(16.67, 0.1));
      expect(metrics.verifiedExamYears, equals([2014]));
      expect(metrics.effectiveMissingTargetYears,
          equals([2013, 2015, 2016, 2017, 2018]));
      // Explanation coverage: 100%
      expect(metrics.explanationCoveragePercent, equals(100.0));

      // Launch readiness must be readyForLaunch despite past-paper depth < 100%
      expect(metrics.readiness, equals(SubjectLaunchReadiness.readyForLaunch));
      expect(metrics.blockingGaps, isEmpty);
      expect(metrics.historicalCoverageStatus,
          equals(HistoricalCoverageStatus.partial));
    });

    test(
        'Case A: Complete curriculum (100%), partial historical papers (3/6) -> readyForLaunch',
        () {
      const subject = Subject(
        id: 'biology_g12',
        code: 'BIO12',
        nameEn: 'Biology',
        nameAm: 'ባዮሎጂ',
        grade: 12,
        stream: 'natural',
        scope: SubjectScope.streamExam,
        sortOrder: 4,
      );

      // Biology has 6 units
      final units = [
        for (int u = 1; u <= 6; u++)
          Unit(
            id: 'bio_u$u',
            subjectId: 'biology_g12',
            unitNumber: u,
            titleEn: 'Bio Unit $u',
            titleAm: 'ባዮ ክፍል $u',
          ),
      ];

      // Provide questions for all 6 units across 3 years (2013, 2014, 2015)
      final questions = [
        for (int u = 1; u <= 6; u++)
          Question(
            id: 'bio_q$u',
            grade: 12,
            stream: 'natural',
            subjectId: 'biology_g12',
            unitId: 'bio_u$u',
            topicId: 'bio_top_$u',
            questionTextEn: 'Bio Q$u',
            questionTextAm: 'Bio Q$u Am',
            difficulty: 'medium',
            verificationStatus: VerificationStatus.published,
            sourceName: 'ESSLCE ${2013 + (u % 3)}',
            contentVersion: 1,
            choices: const [
              AnswerChoice(id: 'c1', label: 'A', textEn: 'A', isCorrect: true),
              AnswerChoice(id: 'c2', label: 'B', textEn: 'B', isCorrect: false),
            ],
            explanation: const Explanation(
              solutionTextEn: 'Complete verified rationale',
              solutionTextAm: 'የተረጋገጠ ማብራሪያ',
            ),
            examYear: 2013 + (u % 3), // 2013, 2014, 2015
          ),
      ];

      final metrics = service.evaluateSubject(
        subject: subject,
        units: units,
        questions: questions,
        stream: 'natural',
        enforceAuthoritativeBreadth: true,
      );

      expect(metrics.curriculumBreadthPercent, equals(100.0));
      expect(metrics.unitsWithQuestions, equals(6));
      expect(metrics.manifestTotalUnits, equals(6));
      expect(metrics.verifiedExamYears, equals([2013, 2014, 2015]));
      expect(metrics.pastPaperDepthPercent, equals(50.0));
      expect(metrics.effectiveMissingTargetYears, equals([2016, 2017, 2018]));
      expect(metrics.historicalCoverageStatus,
          equals(HistoricalCoverageStatus.partial));
      expect(metrics.readiness, equals(SubjectLaunchReadiness.readyForLaunch));
      expect(metrics.blockingGaps, isEmpty);
    });

    test(
        'Case B: Incomplete curriculum (50%), complete historical years (6/6) -> NOT readyForLaunch',
        () {
      const subject = Subject(
        id: 'chemistry_g12',
        code: 'CHEM12',
        nameEn: 'Chemistry',
        nameAm: 'ኬሚስትሪ',
        grade: 12,
        stream: 'natural',
        scope: SubjectScope.streamExam,
        sortOrder: 3,
      );

      // Chemistry has 6 units; provide only 3 units
      final units = [
        for (int u = 1; u <= 3; u++)
          Unit(
            id: 'chem_u$u',
            subjectId: 'chemistry_g12',
            unitNumber: u,
            titleEn: 'Chem Unit $u',
            titleAm: 'ኬም ክፍል $u',
          ),
      ];

      // Provide questions covering all 6 years (2013-2018), but only inside the 3 units
      final questions = [
        for (int y = 2013; y <= 2018; y++)
          Question(
            id: 'chem_q$y',
            grade: 12,
            stream: 'natural',
            subjectId: 'chemistry_g12',
            unitId: 'chem_u${1 + (y % 3)}',
            topicId: 'chem_top_1',
            questionTextEn: 'Chem Q$y',
            questionTextAm: 'Chem Q$y Am',
            difficulty: 'medium',
            verificationStatus: VerificationStatus.published,
            sourceName: 'ESSLCE $y',
            contentVersion: 1,
            choices: const [
              AnswerChoice(id: 'c1', label: 'A', textEn: 'A', isCorrect: true),
              AnswerChoice(id: 'c2', label: 'B', textEn: 'B', isCorrect: false),
            ],
            explanation: const Explanation(
              solutionTextEn: 'Complete verified rationale',
              solutionTextAm: 'የተረጋገጠ ማብራሪያ',
            ),
            examYear: y,
          ),
      ];

      final metrics = service.evaluateSubject(
        subject: subject,
        units: units,
        questions: questions,
        stream: 'natural',
        enforceAuthoritativeBreadth: true,
      );

      expect(metrics.curriculumBreadthPercent, equals(50.0));
      expect(metrics.manifestTotalUnits, equals(6));
      expect(metrics.unitsWithQuestions, equals(3));
      expect(metrics.pastPaperDepthPercent, equals(100.0));
      expect(metrics.historicalCoverageStatus,
          equals(HistoricalCoverageStatus.complete));
      expect(metrics.effectiveMissingTargetYears, isEmpty);
      // Historical depth cannot compensate for missing curriculum breadth
      expect(metrics.readiness,
          isNot(equals(SubjectLaunchReadiness.readyForLaunch)));
      expect(metrics.blockingGaps.any((g) => g.contains('Curriculum breadth')),
          isTrue);
    });

    test(
        'Case C: Manifest with needsVerification status results in unverified authority and blocks launch',
        () {
      const subject = Subject(
        id: 'unverified_subject',
        code: 'UNV12',
        nameEn: 'Unverified Subject',
        nameAm: 'ያልተረጋገጠ',
        grade: 12,
        stream: 'natural',
        scope: SubjectScope.streamExam,
        sortOrder: 99,
      );

      const unverifiedManifest = SubjectManifest(
        manifestId: 'unverified_subject',
        canonicalSubjectId: 'unverified_subject',
        variantCode: ExamVariantCode.naturalScience,
        title: 'Unverified Subject',
        assessmentStructure: AssessmentStructure.curriculum,
        expectedUnitsOrDomains: [
          ExpectedUnitOrDomain(
            index: 1,
            id: 'u1',
            titleEn: 'Unit 1',
            titleAm: 'ክፍል 1',
          ),
        ],
        targetPastExamYears: [2013, 2014, 2015, 2016, 2017, 2018],
        sourceAuthority: 'Draft Note',
        sourceDocumentTitle: 'Unverified Note',
        sourceDocumentId: 'NOTE-001',
        sourceReference: 'Section A',
        curriculumVersion: '2024 Draft',
        verificationStatus: ManifestVerificationStatus.needsVerification,
      );

      final units = [
        const Unit(
          id: 'u1',
          subjectId: 'unverified_subject',
          unitNumber: 1,
          titleEn: 'Unit 1',
          titleAm: 'ክፍል 1',
        ),
      ];

      final questions = [
        for (int i = 1; i <= 5; i++)
          Question(
            id: 'q$i',
            grade: 12,
            stream: 'natural',
            subjectId: 'unverified_subject',
            unitId: 'u1',
            topicId: 'top1',
            questionTextEn: 'Q$i',
            questionTextAm: 'Q$i Am',
            difficulty: 'medium',
            verificationStatus: VerificationStatus.published,
            sourceName: 'ESSLCE 2015',
            contentVersion: 1,
            choices: const [
              AnswerChoice(id: 'c1', label: 'A', textEn: 'A', isCorrect: true),
              AnswerChoice(id: 'c2', label: 'B', textEn: 'B', isCorrect: false),
            ],
            explanation: const Explanation(
              solutionTextEn: 'Rationale',
              solutionTextAm: 'ማብራሪያ',
            ),
            examYear: 2015,
          ),
      ];

      final metrics = service.evaluateSubject(
        subject: subject,
        units: units,
        questions: questions,
        stream: 'natural',
        manifestOverride: unverifiedManifest,
        enforceAuthoritativeBreadth: true,
      );

      expect(metrics.coverageAuthorityLevel,
          equals(CoverageAuthorityLevel.unverified));
      expect(metrics.readiness,
          isNot(equals(SubjectLaunchReadiness.readyForLaunch)));
      expect(
          metrics.blockingGaps.any((g) => g.contains('manifest verification')),
          isTrue);
    });

    test(
        'HistoricalDepthLaunchPolicy controls blocking behavior when configured',
        () {
      const subject = Subject(
        id: 'geography_g12',
        code: 'GEO12',
        nameEn: 'Geography',
        nameAm: 'ጂኦግራፊ',
        grade: 12,
        stream: 'social',
        scope: SubjectScope.streamExam,
        sortOrder: 1,
      );

      final units = [
        for (int u = 1; u <= 8; u++)
          Unit(
            id: 'geo_u$u',
            subjectId: 'geography_g12',
            unitNumber: u,
            titleEn: 'Unit $u',
            titleAm: 'ክፍል $u',
          ),
      ];

      // 8 units covered across 2 exam years: 2013 and 2014
      final questions = [
        for (int u = 1; u <= 8; u++)
          Question(
            id: 'geo_q$u',
            grade: 12,
            stream: 'social',
            subjectId: 'geography_g12',
            unitId: 'geo_u$u',
            topicId: 'top_$u',
            questionTextEn: 'Q$u',
            questionTextAm: 'Q$u Am',
            difficulty: 'medium',
            verificationStatus: VerificationStatus.published,
            sourceName: 'ESSLCE',
            contentVersion: 1,
            choices: const [
              AnswerChoice(id: 'c1', label: 'A', textEn: 'A', isCorrect: true),
              AnswerChoice(id: 'c2', label: 'B', textEn: 'B', isCorrect: false),
            ],
            explanation: const Explanation(
              solutionTextEn: 'Rationale',
              solutionTextAm: 'ማብራሪያ',
            ),
            examYear: u <= 4 ? 2013 : 2014,
          ),
      ];

      // Policy 1: informationalOnly -> passes
      final metricsInfo = service.evaluateSubject(
        subject: subject,
        units: units,
        questions: questions,
        stream: 'social',
        historicalDepthPolicy: HistoricalDepthLaunchPolicy.informationalOnly,
      );
      expect(
          metricsInfo.readiness, equals(SubjectLaunchReadiness.readyForLaunch));

      // Policy 2: minimumYearCount(4) -> fails (we only have 2 years)
      final metricsMin4 = service.evaluateSubject(
        subject: subject,
        units: units,
        questions: questions,
        stream: 'social',
        historicalDepthPolicy: HistoricalDepthLaunchPolicy.minimumYearCount,
        minimumVerifiedYears: 4,
      );
      expect(metricsMin4.readiness,
          isNot(equals(SubjectLaunchReadiness.readyForLaunch)));
      expect(
          metricsMin4.blockingGaps
              .any((g) => g.contains('requires at least 4 verified years')),
          isTrue);

      // Policy 3: allTargetYears -> fails (we have 2 out of 6)
      final metricsAll = service.evaluateSubject(
        subject: subject,
        units: units,
        questions: questions,
        stream: 'social',
        historicalDepthPolicy: HistoricalDepthLaunchPolicy.allTargetYears,
      );
      expect(metricsAll.readiness,
          isNot(equals(SubjectLaunchReadiness.readyForLaunch)));
    });
  });

  group('Manifest Validation & Provenance Audit', () {
    test(
        'Case D: ContentValidationService detects unverified or incomplete manifests',
        () {
      final invalidManifests = [
        const SubjectManifest(
          manifestId: 'inv1',
          canonicalSubjectId: 'inv1',
          variantCode: ExamVariantCode.naturalScience,
          title: 'Missing Authority',
          assessmentStructure: AssessmentStructure.curriculum,
          expectedUnitsOrDomains: [],
          targetPastExamYears: [2013, 2014],
          sourceAuthority: '', // missing
          sourceDocumentTitle: 'Title',
          sourceDocumentId: 'DOC-1',
          sourceReference: 'Ref',
          curriculumVersion: '2024',
          verificationStatus: ManifestVerificationStatus.confirmed,
          verifiedBy: 'Expert',
          verifiedAt: '2024-08-15',
        ),
        const SubjectManifest(
          manifestId: 'inv2',
          canonicalSubjectId: 'inv2',
          variantCode: ExamVariantCode.naturalScience,
          title: 'Confirmed without verifier',
          assessmentStructure: AssessmentStructure.curriculum,
          expectedUnitsOrDomains: [],
          targetPastExamYears: [2013, 2014],
          sourceAuthority: 'Authority',
          sourceDocumentTitle: 'Title',
          sourceDocumentId: 'DOC-2',
          sourceReference: 'Ref',
          curriculumVersion: '2024',
          verificationStatus: ManifestVerificationStatus.confirmed,
          // verifiedBy and verifiedAt missing
        ),
      ];

      final results = ContentValidationService.validateCurriculumManifests(
          invalidManifests);
      expect(
          results.any((r) =>
              r.issueType ==
              ValidationIssueType.missingManifestSourceAuthority),
          isTrue);
      expect(
          results.any((r) =>
              r.issueType == ValidationIssueType.unverifiedConfirmedManifest),
          isTrue);
    });

    test('All production catalog manifests pass strict manifest validation',
        () {
      final results = ContentValidationService.validateCurriculumManifests(
        CurriculumManifestCatalog.allManifests,
      );
      final errors =
          results.where((r) => r.severity == ValidationSeverity.error).toList();
      expect(errors, isEmpty,
          reason: 'Catalog manifests must have 0 validation errors: $errors');
    });

    test('Case E: Manifest Source Audit report generates full audit summaries',
        () {
      final auditSummaries =
          CurriculumCoverageService.generateManifestSourceAuditSummary();
      expect(auditSummaries.length, equals(11));

      for (final summary in auditSummaries) {
        expect(summary['sourceAuthority'], isNotEmpty);
        expect(summary['sourceDocumentTitle'], isNotEmpty);
        expect(summary['sourceDocumentId'], isNotEmpty);
        expect(summary['curriculumVersion'], isNotEmpty);
        expect(summary['verificationStatus'], equals('confirmed'));
        expect(summary['verifiedBy'], isNotNull);
        expect(summary['verifiedAt'], isNotNull);
      }
    });
  });
}
