import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/features/school/domain/models/institutional_reporting_models.dart';
import 'package:fidel_learn/features/school/data/repositories/local_institutional_reporting_repository.dart';
import 'package:fidel_learn/features/school/data/services/institutional_csv_exporter.dart';
import 'package:fidel_learn/features/school/data/services/institutional_document_exporter.dart';

void main() {
  group('P10 Institutional Analytics — Metric Dictionary Tests', () {
    test('All canonical metrics are registered in dictionary', () {
      const metrics = InstitutionalMetricDictionary.allMetrics;
      expect(metrics.isNotEmpty, isTrue);
      expect(metrics.length, greaterThanOrEqualTo(16));

      for (final m in metrics) {
        expect(m.id.isNotEmpty, isTrue);
        expect(m.displayName.isNotEmpty, isTrue);
        expect(m.definition.isNotEmpty, isTrue);
        expect(m.numerator.isNotEmpty, isTrue);
        expect(m.denominator.isNotEmpty, isTrue);
        expect(m.version, equals(kInstitutionalAnalyticsVersion));
      }
    });

    test('Institutional report types count exactly 11 canonical reports', () {
      expect(InstitutionalReportType.values.length, equals(11));
      expect(InstitutionalReportType.values,
          contains(InstitutionalReportType.teacherCoverage));
      expect(InstitutionalReportType.teacherCoverage.dbValue,
          equals('teacher_coverage'));
      expect(InstitutionalReportType.teacherCoverage.titleEn,
          equals('Teacher Coverage Report'));
    });

    test('Required metrics can be retrieved by ID', () {
      final mActive = InstitutionalMetricDictionary.getById('active_students');
      expect(mActive, isNotNull);
      expect(mActive!.displayName, equals('Active Students'));

      final mAssign =
          InstitutionalMetricDictionary.getById('assignment_completion_rate');
      expect(mAssign, isNotNull);
      expect(mAssign!.denominator, contains('requiredForCompletion'));

      final mInterv = InstitutionalMetricDictionary.getById(
          'interventions_with_followup_evidence');
      expect(mInterv, isNotNull);
      expect(mInterv!.timeWindow, contains('30 days'));

      final mCover =
          InstitutionalMetricDictionary.getById('fresh_data_coverage');
      expect(mCover, isNotNull);
      expect(mCover!.timeWindow, contains('14 days'));
    });
  });

  group('P10 Institutional Analytics — CSV Serialization & Privacy Tests', () {
    test('RFC 4180 field escaping handles commas, quotes, and newlines', () {
      expect(InstitutionalCsvExporter.escapeField('simple'), equals('simple'));
      expect(InstitutionalCsvExporter.escapeField('hello, world'),
          equals('"hello, world"'));
      expect(InstitutionalCsvExporter.escapeField('quote "test" here'),
          equals('"quote ""test"" here"'));
      expect(InstitutionalCsvExporter.escapeField('multi\nline'),
          equals('"multi\nline"'));
    });

    test(
        'Formula injection defense escapes =, +, -, @, tabs, and carriage returns',
        () {
      expect(InstitutionalCsvExporter.escapeField('=HYPERLINK("calc")'),
          equals("\"'=HYPERLINK(\"\"calc\"\")\""));
      expect(InstitutionalCsvExporter.escapeField('+12345'), equals("'+12345"));
      expect(InstitutionalCsvExporter.escapeField('-SUM(A1:A10)'),
          equals("'-SUM(A1:A10)"));
      expect(
          InstitutionalCsvExporter.escapeField('@IMPORT'), equals("'@IMPORT"));
      expect(InstitutionalCsvExporter.escapeField('\tCMD'), equals("'\tCMD"));
    });

    test('CSV serialization preserves UTF-8 Amharic characters correctly', () {
      const amharicText = 'የአዲስ አበባ ሁለተኛ ደረጃ ትምህርት ቤት';
      final escaped = InstitutionalCsvExporter.escapeField(amharicText);
      expect(escaped, equals(amharicText));

      final csv = InstitutionalCsvExporter.toCsvString([
        ['ትምህርት ቤት', amharicText]
      ]);
      expect(csv, contains(amharicText));
    });

    test('Executive report CSV export contains expected metadata and zero PII',
        () {
      final now = DateTime.now().toUtc();
      final report = ExecutiveReport(
        schoolId: '11111111-1111-1111-1111-111111111111',
        schoolName: 'Bole Secondary School',
        academicYear: '2026/27',
        periodStart: now.subtract(const Duration(days: 30)),
        periodEnd: now,
        dataAsOf: now,
        studentPopulation: 1000,
        naturalStreamStudents: 600,
        socialStreamStudents: 400,
        teacherPopulation: 50,
        classPopulation: 25,
        assessmentEligibleStudents: 1000,
        assessmentParticipants: 850,
        assessmentParticipationRate: 85.0,
        recentAssessmentAverage: 72.5,
        recentAssessmentMedian: 74.0,
        simulationParticipants: 600,
        simulationParticipationRate: 60.0,
        simulationAverage: 69.1,
        simulationMedian: 70.0,
        requiredForCompletion: 500,
        submittedCount: 450,
        completedCount: 440,
        completionRate: 90.0,
        verifiedLateCount: 30,
        lateRateVerified: 6.67,
        timingUnverifiedCount: 10,
        clockAnomalyCount: 2,
        interventionsCreated: 25,
        interventionsCompleted: 20,
        interventionsWithFollowupEvidence: 15,
        teacherCoverageRate: 98.0,
        freshSyncCount: 800,
        moderateSyncCount: 100,
        staleSyncCount: 80,
        veryStaleSyncCount: 20,
        freshDataCoverageRate: 90.0,
      );

      final csv = InstitutionalCsvExporter.exportExecutive(report);
      expect(csv, contains('School Executive Report'));
      expect(csv, contains('Bole Secondary School'));
      expect(csv, contains('85.0%'));
      expect(csv, contains('Non-Causal Notice'));

      // Verify privacy: zero PII keywords
      expect(csv, isNot(contains('phone_number')));
      expect(csv, isNot(contains('password')));
      expect(csv, isNot(contains('email')));
      expect(csv, isNot(contains('study_coins')));

      // Verify SHA-256 calculation
      final sha = InstitutionalCsvExporter.calculateSha256(csv);
      expect(sha.length, equals(64));
    });

    test('Subject performance CSV export marks suppressed cohorts (n < 5)', () {
      final now = DateTime.now().toUtc();
      final rows = [
        SubjectPerformanceRow(
          subjectId: 'physics_g12',
          subjectName: 'Physics',
          stream: 'natural',
          eligibleStudents: 100,
          participants: 80,
          participationRate: 80.0,
          attemptCount: 150,
          averageScore: 72.0,
          medianScore: 75.0,
          affectedStudents: 15,
          activeMistakes: 45,
          assignmentCompletion: 85.0,
          interventionsCount: 3,
          dataAsOf: now,
          privacySuppressed: false,
        ),
        SubjectPerformanceRow(
          subjectId: 'special_sub',
          subjectName: 'Special Elective',
          stream: 'natural',
          eligibleStudents: 10,
          participants: 3, // n < 5
          participationRate: 30.0,
          attemptCount: 4,
          averageScore: null,
          medianScore: null,
          affectedStudents: 1,
          activeMistakes: 2,
          assignmentCompletion: 50.0,
          interventionsCount: 0,
          dataAsOf: now,
          privacySuppressed: true,
        ),
      ];

      final csv = InstitutionalCsvExporter.exportSubjects(rows);
      expect(csv, contains('Physics'));
      expect(csv, contains('72.0'));
      expect(csv, contains('[SUPPRESSED n<5]'));
    });
  });

  group('P10 Institutional Analytics — Printable Document Exporter Tests', () {
    test(
        'Generates structured document with KPIs, non-causal notice, and footers',
        () {
      final now = DateTime.now().toUtc();
      final report = ExecutiveReport(
        schoolId: '11111111-1111-1111-1111-111111111111',
        schoolName: 'Hawassa Secondary School',
        academicYear: '2026/27',
        periodStart: now.subtract(const Duration(days: 90)),
        periodEnd: now,
        dataAsOf: now,
        studentPopulation: 800,
        naturalStreamStudents: 500,
        socialStreamStudents: 300,
        teacherPopulation: 40,
        classPopulation: 20,
        assessmentEligibleStudents: 800,
        assessmentParticipants: 700,
        assessmentParticipationRate: 87.5,
        recentAssessmentAverage: 75.0,
        recentAssessmentMedian: 77.0,
        simulationParticipants: 450,
        simulationParticipationRate: 56.25,
        simulationAverage: 71.0,
        simulationMedian: 72.5,
        requiredForCompletion: 400,
        submittedCount: 370,
        completedCount: 360,
        completionRate: 92.5,
        verifiedLateCount: 20,
        lateRateVerified: 5.41,
        timingUnverifiedCount: 8,
        clockAnomalyCount: 1,
        interventionsCreated: 18,
        interventionsCompleted: 15,
        interventionsWithFollowupEvidence: 12,
        teacherCoverageRate: 100.0,
        freshSyncCount: 650,
        moderateSyncCount: 80,
        staleSyncCount: 50,
        veryStaleSyncCount: 20,
        freshDataCoverageRate: 91.25,
      );

      final doc = InstitutionalDocumentExporter.formatExecutiveReport(report);
      expect(doc, contains('FIDELLEARN INSTITUTIONAL REPORTING SYSTEM'));
      expect(doc, contains('Hawassa Secondary School'));
      expect(doc, contains('1. Institutional Population Overview'));
      expect(
          doc, contains('2. National Exam Preparation & Simulation Evidence'));
      expect(doc,
          contains('3. Instructional Workflow & Assignment Follow-Through'));
      expect(doc,
          contains('4. Student Academic Interventions & Follow-Up Evidence'));
      expect(doc, contains('METHODOLOGY FOOTER & DISCLAIMERS'));
      expect(doc, contains('Causation is not established'));

      final sha = InstitutionalDocumentExporter.calculateSha256(doc);
      expect(sha.length, equals(64));
    });
  });

  group('P10 Institutional Analytics — Local Repository Verification', () {
    late LocalInstitutionalReportingRepository repo;

    setUp(() {
      repo = LocalInstitutionalReportingRepository();
    });

    test('Can retrieve executive report with valid indicators', () async {
      final report = await repo.getExecutiveReport(schoolId: 'demo-school');
      expect(report.schoolName, isNotEmpty);
      expect(report.studentPopulation, greaterThan(0));
      expect(report.completionRate, greaterThan(0));
      expect(report.analyticsVersion, equals(kInstitutionalAnalyticsVersion));
    });

    test('Can retrieve subject performance with separated Math variants',
        () async {
      final rows =
          await repo.getSubjectPerformanceReport(schoolId: 'demo-school');
      expect(rows.length, greaterThanOrEqualTo(3));

      final mathNat = rows.where((r) =>
          r.subjectId == 'math_g12' && r.examVariant == 'naturalScience');
      final mathSoc = rows.where(
          (r) => r.subjectId == 'math_g12' && r.examVariant == 'socialScience');

      expect(mathNat.length, equals(1));
      expect(mathSoc.length, equals(1));
      expect(mathNat.first.subjectName, contains('Natural'));
      expect(mathSoc.first.subjectName, contains('Social'));
    });

    test('Can create and list persistent report runs', () async {
      final now = DateTime.now().toUtc();
      final newRun = await repo.createReportRun(
        schoolId: 'demo-school',
        reportType: InstitutionalReportType.subjectPerformance,
        academicYear: '2026/27',
        periodStart: now.subtract(const Duration(days: 30)),
        periodEnd: now,
        filters: {'stream': 'natural'},
        fileFormat: 'csv',
      );

      expect(newRun.id, isNotEmpty);
      expect(newRun.reportType,
          equals(InstitutionalReportType.subjectPerformance));
      expect(newRun.status, equals(ReportRunStatus.completed));

      final runs = await repo.getReportRuns(schoolId: 'demo-school');
      expect(runs.any((r) => r.id == newRun.id), isTrue);
    });

    test(
        'Intervention follow-up report returns comparable baseline and follow-up data',
        () async {
      final rows =
          await repo.getInterventionFollowUpReport(schoolId: 'demo-school');
      expect(rows.isNotEmpty, isTrue);

      final first = rows.first;
      expect(first.baselineAccuracy, isNotNull);
      expect(first.followupAccuracy, isNotNull);
      expect(first.observedChangePp, equals(16.0));
      expect(
          first.evidenceInterpretation, contains('causation not established'));
    });

    test('Can retrieve teacher coverage report from local repo', () async {
      final report =
          await repo.getTeacherCoverageReport(schoolId: 'demo-school');
      expect(report.totalClassrooms, equals(4));
      expect(report.totalSubjects, equals(6));
      expect(report.totalRequiredSlots, equals(24));
      expect(report.assignedSlots, equals(22));
      expect(report.unassignedSlots, equals(2));
      expect(report.coveragePercentage, equals(91.67));
      expect(report.slots.length, equals(3));
    });
  });

  group('P10 Institutional Analytics — Methodology & Provenance Tests', () {
    test('P5 Provenance Helper returns authoritative normalized labels', () {
      final row1 = AssessmentReportRow(
        examId: 'e-1',
        examTitle: 'ESSLCE 2014 Physics',
        subjectId: 'physics_g12',
        sourceType: 'officialHistoricalPaper',
        examMode: 'historicalPaper',
        examType: 'national_exam',
        eligibleStudents: 100,
        participants: 80,
        participationRate: 80.0,
        attemptCount: 90,
        averageScore: 70.0,
        medianScore: 72.0,
        bandBelow50: 10,
        band50to59: 15,
        band60to69: 20,
        band70to79: 25,
        band80to89: 8,
        band90Plus: 2,
        dataAsOf: DateTime.now().toUtc(),
      );
      expect(row1.provenanceLabel, equals('Official Historical Paper'));

      final row2 = AssessmentReportRow(
        examId: 'e-2',
        examTitle: 'Model Exam 2026',
        subjectId: 'math_g12',
        sourceType: 'verifiedModelPaper',
        examMode: 'practice',
        examType: 'practice',
        eligibleStudents: 100,
        participants: 50,
        participationRate: 50.0,
        attemptCount: 60,
        averageScore: 65.0,
        medianScore: 68.0,
        bandBelow50: 5,
        band50to59: 10,
        band60to69: 15,
        band70to79: 15,
        band80to89: 4,
        band90Plus: 1,
        dataAsOf: DateTime.now().toUtc(),
      );
      expect(row2.provenanceLabel, equals('Verified Model Exam'));

      final row3 = AssessmentReportRow(
        examId: 'e-3',
        examTitle: 'Simulation 1',
        subjectId: 'chem_g12',
        sourceType: 'generatedSimulation',
        examMode: 'nationalSimulation',
        examType: 'mock_full',
        eligibleStudents: 100,
        participants: 90,
        participationRate: 90.0,
        attemptCount: 95,
        averageScore: 75.0,
        medianScore: 76.0,
        bandBelow50: 5,
        band50to59: 10,
        band60to69: 20,
        band70to79: 30,
        band80to89: 20,
        band90Plus: 5,
        dataAsOf: DateTime.now().toUtc(),
      );
      expect(row3.provenanceLabel, equals('FidelLearn ESSLCE Simulation'));
    });

    test(
        'Assignment timeliness formulas strictly exclude unverified timing from rates',
        () {
      // 10 verified on-time, 2 verified late, 3 unverified, 1 anomaly
      // Total verified = 12
      // Verified on-time rate = 10 / 12 = 83.33%
      // Verified late rate = 2 / 12 = 16.67%
      final row = AssignmentOutcomeRow(
        assignmentId: 'a-1',
        assignmentTitle: 'Calculus Review',
        assignmentType: 'practice',
        classroomId: 'c-1',
        classroomName: '12-A',
        subjectId: 'math_g12',
        teacherName: 'Teacher Abebe',
        publicationCohort: 16,
        requiredDenominator: 16,
        submittedCount: 16,
        completedCount: 16,
        excusedCount: 0,
        verifiedOnTimeCount: 10,
        verifiedLateCount: 2,
        timingUnverifiedCount: 3,
        clockAnomalyCount: 1,
        completionRate: 100.0,
        averageScore: 78.5,
        medianScore: 80.0,
        dataAsOf: DateTime.now().toUtc(),
      );

      expect(row.verifiedOnTimeCount + row.verifiedLateCount, equals(12));
      expect(row.verifiedOnTimeRate, closeTo(83.33, 0.01));
      expect(row.verifiedLateRate, closeTo(16.67, 0.01));
      expect(row.timingUnverifiedCount, equals(3));
      expect(row.clockAnomalyCount, equals(1));
    });

    test(
        'Incomplete intervention row correctly reflects unfulfilled action status',
        () {
      final now = DateTime.now().toUtc();
      final openRow = InterventionFollowUpRow(
        interventionId: 'int-open-1',
        studentId: 'stud-1',
        studentName: 'Tigist',
        classroomId: 'c-1',
        classroomName: '12-A',
        subjectId: 'math_g12',
        teacherName: 'Teacher Abebe',
        source: 'manual',
        reasonCodes: const ['low_quiz_score'],
        actionType: 'one_on_one_review',
        status: 'open',
        createdAt: now.subtract(const Duration(days: 10)),
        completedAt: null,
        baselineAccuracy: 45.0,
        followupAccuracy: null,
        observedChangePp: null,
        evidenceStatus: 'not_yet_eligible',
        evidenceInterpretation: 'Intervention not yet completed by educator',
        evidenceCountPre: 1,
        evidenceCountPost: 0,
        confidence: 'insufficient',
        dataAsOf: now,
      );

      expect(openRow.status, equals('open'));
      expect(openRow.completedAt, isNull);
      expect(openRow.followupAccuracy, isNull);
      expect(openRow.observedChangePp, isNull);
      expect(openRow.evidenceStatus, equals('not_yet_eligible'));
      expect(openRow.confidence, equals('insufficient'));
    });
  });
}
