import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/features/admin/presentation/widgets/curriculum_coverage_dashboard.dart';
import 'package:fidel_learn/features/subjects/domain/models/subject_models.dart';
import 'package:fidel_learn/features/subjects/domain/services/curriculum_coverage_service.dart';

void main() {
  group('CurriculumCoverageDashboardWidget Tests', () {
    late CurriculumCoverageReport dummyReport;

    setUp(() {
      dummyReport = CurriculumCoverageReport(
        evaluatedAt: DateTime.now(),
        subjectMetrics: const [
          SubjectCoverageMetrics(
            subjectId: 'physics_g12',
            subjectNameEn: 'Physics',
            subjectNameAm: 'ፊዚክስ',
            totalUnits: 10,
            unitsWithQuestions: 10,
            totalQuestions: 60,
            publishedQuestions: 60,
            reviewRequiredQuestions: 0,
            draftQuestions: 0,
            questionsPerExamYear: {2014: 60},
            rationaleCoveragePercent: 100.0,
            keyConceptCoveragePercent: 100.0,
            commonPitfallCoveragePercent: 100.0,
            amharicTranslationPercent: 100.0,
            readiness: SubjectLaunchReadiness.readyForLaunch,
            blockingGaps: [],
          ),
          SubjectCoverageMetrics(
            subjectId: 'history_g12',
            subjectNameEn: 'History',
            subjectNameAm: 'ታሪክ',
            totalUnits: 5,
            unitsWithQuestions: 5,
            totalQuestions: 25,
            publishedQuestions: 25,
            reviewRequiredQuestions: 0,
            draftQuestions: 0,
            questionsPerExamYear: {2015: 25},
            rationaleCoveragePercent: 95.0,
            keyConceptCoveragePercent: 90.0,
            commonPitfallCoveragePercent: 85.0,
            amharicTranslationPercent: 90.0,
            readiness: SubjectLaunchReadiness.readyForLaunch,
            blockingGaps: [],
          ),
        ],
      );
    });

    testWidgets(
        'renders top statistics banner, stream chips, and subject cards',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CurriculumCoverageDashboardWidget(report: dummyReport),
            ),
          ),
        ),
      );

      // Verify stat cards
      expect(find.text('Launch Subjects'), findsOneWidget);
      expect(find.text('Total Questions'), findsOneWidget);
      expect(find.text('2 Ready for Launch'), findsOneWidget);
      expect(find.text('85 Published'), findsOneWidget);

      // Verify filter chips
      expect(find.text('All (Grade 12)'), findsOneWidget);
      expect(find.text('Natural Science'), findsOneWidget);
      expect(find.text('Social Science'), findsOneWidget);

      // Verify initial cards (All)
      expect(find.text('Physics (ፊዚክስ)'), findsOneWidget);
      expect(find.text('History (ታሪክ)'), findsOneWidget);
      expect(find.text('READY FOR LAUNCH'), findsNWidgets(2));
    });

    testWidgets(
        'filtering by Social Science hides Natural subjects and shows Social only',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CurriculumCoverageDashboardWidget(report: dummyReport),
            ),
          ),
        ),
      );

      // Tap 'Social Science' filter chip
      await tester.tap(find.text('Social Science'));
      await tester.pumpAndSettle();

      expect(find.text('History (ታሪክ)'), findsOneWidget);
      expect(find.text('Physics (ፊዚክስ)'), findsNothing);
    });

    testWidgets(
        'filtering by Natural Science hides Social subjects and shows Natural only',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CurriculumCoverageDashboardWidget(report: dummyReport),
            ),
          ),
        ),
      );

      // Tap 'Natural Science' filter chip
      await tester.tap(find.text('Natural Science'));
      await tester.pumpAndSettle();

      expect(find.text('Physics (ፊዚክስ)'), findsOneWidget);
      expect(find.text('History (ታሪክ)'), findsNothing);
    });

    testWidgets(
        'filtering by Supplementary shows Civics and hides standard exam subjects',
        (tester) async {
      final reportWithCivics = CurriculumCoverageReport(
        evaluatedAt: DateTime.now(),
        subjectMetrics: const [
          SubjectCoverageMetrics(
            subjectId: 'physics_g12',
            subjectNameEn: 'Physics',
            subjectNameAm: 'ፊዚክስ',
            totalUnits: 9,
            unitsWithQuestions: 9,
            totalQuestions: 60,
            publishedQuestions: 60,
            reviewRequiredQuestions: 0,
            draftQuestions: 0,
            questionsPerExamYear: {2014: 60},
            rationaleCoveragePercent: 100.0,
            keyConceptCoveragePercent: 100.0,
            commonPitfallCoveragePercent: 100.0,
            amharicTranslationPercent: 100.0,
            readiness: SubjectLaunchReadiness.readyForLaunch,
            blockingGaps: [],
          ),
          SubjectCoverageMetrics(
            subjectId: 'civics_g12',
            subjectNameEn: 'Civics',
            subjectNameAm: 'ስነ-ዜጋ',
            totalUnits: 11,
            unitsWithQuestions: 11,
            totalQuestions: 40,
            publishedQuestions: 40,
            reviewRequiredQuestions: 0,
            draftQuestions: 0,
            questionsPerExamYear: {2014: 40},
            rationaleCoveragePercent: 100.0,
            keyConceptCoveragePercent: 100.0,
            commonPitfallCoveragePercent: 100.0,
            amharicTranslationPercent: 100.0,
            readiness: SubjectLaunchReadiness.readyForLaunch,
            blockingGaps: [],
            scope: SubjectScope.curriculumOnly,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child:
                  CurriculumCoverageDashboardWidget(report: reportWithCivics),
            ),
          ),
        ),
      );

      // Verify Supplementary chip exists
      expect(find.text('Supplementary (Civics)'), findsOneWidget);

      // Scroll to and tap 'Supplementary (Civics)' filter chip
      await tester.ensureVisible(find.text('Supplementary (Civics)'));
      await tester.tap(find.text('Supplementary (Civics)'));
      await tester.pumpAndSettle();

      expect(find.text('Civics (ስነ-ዜጋ)'), findsOneWidget);
      expect(find.text('Physics (ፊዚክስ)'), findsNothing);
    });

    testWidgets('renders badges for scope, variant, and decoupled metric bars',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CurriculumCoverageDashboardWidget(report: dummyReport),
            ),
          ),
        ),
      );

      // Check for Scope, Variant, Structure Badges
      expect(find.text('STREAMEXAM'), findsNWidgets(2));
      expect(find.text('SHARED'), findsNWidgets(2));
      expect(find.text('CURRICULUM'), findsNWidgets(2));

      // Check decoupled metric progress labels
      expect(find.textContaining('Curriculum Breadth'), findsWidgets);
      expect(find.textContaining('Past-Paper Depth'), findsWidgets);
    });

    testWidgets('tapping source evidence audit row opens modal dialog',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CurriculumCoverageDashboardWidget(report: dummyReport),
            ),
          ),
        ),
      );

      // Verify Audit button is present
      final auditFinder = find.text('Audit');
      expect(auditFinder, findsWidgets);

      // Ensure visible and tap first Audit button
      await tester.ensureVisible(auditFinder.first);
      await tester.tap(auditFinder.first);
      await tester.pumpAndSettle();

      // Verify dialog is open with provenance audit headers
      expect(find.text('Physics Curriculum Provenance'), findsOneWidget);
      expect(find.text('Canonical Subject ID'), findsOneWidget);
      expect(find.text('Source Authority'), findsOneWidget);
      expect(find.text('Source Document'), findsOneWidget);
      expect(find.text('Curriculum Version'), findsOneWidget);
      expect(find.text('Coverage Authority Level'), findsOneWidget);
      expect(find.text('Historical Depth Status'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.text('Physics Curriculum Provenance'), findsNothing);
    });
  });
}
