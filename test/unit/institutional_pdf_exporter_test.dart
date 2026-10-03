import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/features/school/data/services/institutional_pdf_exporter.dart';
import 'package:fidel_learn/features/school/domain/models/institutional_reporting_models.dart';

void main() {
  group('P10 Institutional Analytics — Real PDF Exporter Tests', () {
    late ExecutiveReport sampleReport;
    late TeacherCoverageReport sampleCoverageReport;

    setUp(() {
      final now = DateTime.now().toUtc();
      sampleReport = ExecutiveReport(
        schoolId: '11111111-1111-1111-1111-111111111111',
        schoolName: 'Bole Secondary School',
        academicYear: '2026/27',
        periodStart: now.subtract(const Duration(days: 30)),
        periodEnd: now,
        dataAsOf: now,
        studentPopulation: 1200,
        activeEnrolledStudents: 1200,
        studentsWithAcademicEvidence: 1050,
        naturalStreamStudents: 700,
        socialStreamStudents: 500,
        teacherPopulation: 60,
        classPopulation: 30,
        assessmentEligibleStudents: 1200,
        assessmentParticipants: 1050,
        assessmentParticipationRate: 87.5,
        recentAssessmentAverage: 73.2,
        recentAssessmentMedian: 75.0,
        simulationParticipants: 800,
        simulationParticipationRate: 66.7,
        simulationAverage: 70.4,
        simulationMedian: 71.0,
        requiredForCompletion: 600,
        submittedCount: 540,
        completedCount: 520,
        completionRate: 90.0,
        verifiedLateCount: 40,
        lateRateVerified: 7.41,
        verifiedOnTimeRate: 92.59,
        timingUnverifiedCount: 15,
        clockAnomalyCount: 3,
        interventionsCreated: 35,
        interventionsCompleted: 28,
        interventionsWithFollowupEvidence: 22,
        teacherCoverageRate: 95.8,
        freshSyncCount: 950,
        moderateSyncCount: 150,
        staleSyncCount: 80,
        veryStaleSyncCount: 20,
        freshDataCoverageRate: 91.67,
      );

      sampleCoverageReport = TeacherCoverageReport(
        schoolId: '11111111-1111-1111-1111-111111111111',
        academicYear: '2026/27',
        dataAsOf: now,
        totalClassrooms: 4,
        totalSubjects: 6,
        totalRequiredSlots: 24,
        assignedSlots: 22,
        unassignedSlots: 2,
        coveragePercentage: 91.67,
        slots: const [
          TeacherCoverageSlotRow(
            classroomId: 'c-101',
            classroomName: '12-A Natural',
            grade: 12,
            stream: 'natural',
            subjectId: 'sub-math-nat',
            subjectName: 'Mathematics (Natural)',
            isAssigned: true,
            teacherId: 't-001',
            teacherName: 'Teacher Haile',
          ),
          TeacherCoverageSlotRow(
            classroomId: 'c-102',
            classroomName: '12-B Social',
            grade: 12,
            stream: 'social',
            subjectId: 'sub-math-soc',
            subjectName: 'Mathematics (Social)',
            isAssigned: false,
          ),
        ],
      );
    });

    test('Generates valid binary PDF 1.4 for School Executive Report', () {
      final pdfBytes = InstitutionalPdfExporter.exportExecutive(sampleReport);

      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.lengthInBytes, greaterThan(1500));

      // 1. PDF Header / Magic Bytes check (%PDF-1.4)
      final headerStr = utf8.decode(pdfBytes.sublist(0, 8));
      expect(headerStr.startsWith('%PDF-1.4'), isTrue);

      // 2. Binary EOF check (%%EOF)
      final contentStr = utf8.decode(pdfBytes, allowMalformed: true);
      expect(contentStr.trim().endsWith('%%EOF'), isTrue);

      // 3. PDF Object structure checks
      expect(contentStr, contains('/Type /Catalog'));
      expect(contentStr, contains('/Type /Pages'));
      expect(contentStr, contains('/Type /Page'));
      expect(contentStr, contains('/Type /Font'));
      expect(contentStr, contains('/BaseFont /Helvetica'));
      expect(contentStr, contains('/BaseFont /Helvetica-Bold'));
      expect(contentStr, contains('xref'));
      expect(contentStr, contains('trailer'));
      expect(contentStr, contains('startxref'));

      // 4. Content verification
      expect(contentStr, contains('FidelLearn Institutional Executive Report'));
      expect(contentStr, contains('Bole Secondary School'));
      expect(contentStr, contains('Active Enrolled Students'));
      expect(contentStr, contains('Non-Causal Academic Evidence Notice'));
      expect(contentStr, contains('Causation is not established'));
      expect(
          contentStr,
          contains(
              'Privacy Suppression: Aggregate cells with fewer than 5 students'));
      expect(
          contentStr,
          contains(
              'P4 Mastery Limitation: Adaptive spaced mastery and national readiness remain device-local'));

      // 5. SHA-256 calculation
      final sha = InstitutionalPdfExporter.calculateSha256(pdfBytes);
      expect(sha.length, equals(64));
    });

    test('Generates valid binary PDF 1.4 for Teacher Coverage Report', () {
      final pdfBytes =
          InstitutionalPdfExporter.exportTeacherCoverage(sampleCoverageReport);

      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.lengthInBytes, greaterThan(1000));

      final contentStr = utf8.decode(pdfBytes, allowMalformed: true);
      expect(contentStr.startsWith('%PDF-1.4'), isTrue);
      expect(contentStr.trim().endsWith('%%EOF'), isTrue);
      expect(contentStr, contains('FidelLearn Teacher Coverage Report'));
      expect(contentStr, contains('12-A Natural'));
      expect(contentStr, contains('Teacher Haile'));
      expect(contentStr, contains('NO TEACHER ASSIGNED'));
      expect(contentStr,
          contains('No teacher ranking or evaluation score is computed'));

      final sha = InstitutionalPdfExporter.calculateSha256(pdfBytes);
      expect(sha.length, equals(64));
    });
  });
}
