import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fidel_learn/features/teacher/domain/models/teacher_portal_models.dart';
import 'package:fidel_learn/features/school/domain/models/school_leadership_models.dart';
import 'package:fidel_learn/features/school/data/repositories/local_school_leadership_repository.dart';
import 'package:fidel_learn/features/school/data/repositories/supabase_school_leadership_repository.dart';

class _FailingSupabaseClient implements SupabaseClient {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #rpc) {
      throw Exception('ClientException: Failed to connect to host (offline)');
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  group('P8 School Leadership Domain Models Test', () {
    test('SchoolLeadershipSummary deserializes correctly and retains metrics',
        () {
      final json = {
        'school_id': 'sch-001',
        'school_name': 'Menelik II Secondary School',
        'academic_year': '2016 E.C.',
        'total_active_students': 320,
        'natural_stream_students': 180,
        'social_stream_students': 140,
        'total_active_teachers': 24,
        'total_active_classrooms': 8,
        'recent_simulation_count': 295,
        'recent_simulation_avg_pct': 64.8,
        'recent_simulation_median_pct': 66.0,
        'simulation_participation_rate': 92.19,
        'unique_students_needing_help': 28,
        'high_severity_student_count': 12,
        'stale_sync_student_count': 16,
        'top_weak_subject_name': 'Physics Grade 12',
        'top_weak_subject_mistakes': 420,
        'teacher_assignment_coverage': 87.5,
        'unassigned_subject_slots': 3,
        'active_within_7d': 260,
        'active_8_to_14d': 32,
        'active_15_to_30d': 18,
        'inactive_over_30d': 10,
      };

      final summary = SchoolLeadershipSummary.fromJson(json);

      expect(summary.schoolId, 'sch-001');
      expect(summary.schoolName, 'Menelik II Secondary School');
      expect(summary.academicYear, '2016 E.C.');
      expect(summary.totalActiveStudents, 320);
      expect(summary.naturalStreamStudents, 180);
      expect(summary.socialStreamStudents, 140);
      expect(summary.simulationParticipationRate, 92.19);
      expect(summary.recentSimulationAvgPct, 64.8);
      expect(summary.recentSimulationMedianPct, 66.0);
      expect(summary.uniqueStudentsNeedingHelp, 28);
      expect(summary.freshDataCoverageRate, 0.0);
    });

    test('SchoolStreamSummary maintains Natural and Social stream isolation',
        () {
      final natJson = {
        'stream': 'natural',
        'enrolled_students': 180,
        'participating_students': 172,
        'participation_rate': 95.56,
        'simulations_completed': 172,
        'avg_score_pct': 67.4,
        'median_score_pct': 68.5,
        'students_needing_help': 14,
      };

      final socJson = {
        'stream': 'social',
        'enrolled_students': 140,
        'participating_students': 123,
        'participation_rate': 87.86,
        'simulations_completed': 123,
        'avg_score_pct': 61.2,
        'median_score_pct': 62.0,
        'students_needing_help': 14,
      };

      final natSummary = SchoolStreamSummary.fromJson(natJson);
      final socSummary = SchoolStreamSummary.fromJson(socJson);

      expect(natSummary.isNatural, isTrue);
      expect(natSummary.isSocial, isFalse);
      expect(natSummary.streamLabel, 'Natural Science');
      expect(natSummary.participationRate, 95.56);

      expect(socSummary.isNatural, isFalse);
      expect(socSummary.isSocial, isTrue);
      expect(socSummary.streamLabel, 'Social Science');
      expect(socSummary.participationRate, 87.86);
    });

    test('SchoolSubjectSummary isolates Math variants: Natural vs Social', () {
      final advMathJson = {
        'subject_id': 'math_g12',
        'subject_name': 'Mathematics',
        'exam_variant': 'naturalScience',
        'display_name': 'Mathematics — Natural Science',
        'stream': 'natural',
        'enrolled_student_count': 180,
        'participant_count': 168,
        'participation_rate': 93.33,
        'attempt_count': 168,
        'avg_percentage': 61.5,
        'median_percentage': 63.0,
        'active_mistake_count': 380,
        'has_teacher_coverage': true,
      };

      final appMathJson = {
        'subject_id': 'math_g12',
        'subject_name': 'Mathematics',
        'exam_variant': 'socialScience',
        'display_name': 'Mathematics — Social Science',
        'stream': 'social',
        'enrolled_student_count': 140,
        'participant_count': 118,
        'participation_rate': 84.29,
        'attempt_count': 118,
        'avg_percentage': 58.2,
        'median_percentage': 60.0,
        'active_mistake_count': 310,
        'has_teacher_coverage': true,
      };

      final advMath = SchoolSubjectSummary.fromJson(advMathJson);
      final appMath = SchoolSubjectSummary.fromJson(appMathJson);

      expect(advMath.subjectId, 'math_g12');
      expect(advMath.examVariant, 'naturalScience');
      expect(advMath.displayName, 'Mathematics — Natural Science');
      expect(advMath.stream, 'natural');

      expect(appMath.subjectId, 'math_g12');
      expect(appMath.examVariant, 'socialScience');
      expect(appMath.displayName, 'Mathematics — Social Science');
      expect(appMath.stream, 'social');

      // Canonical subject ID is identical; variants isolate curricula
      expect(advMath.subjectId, equals(appMath.subjectId));
      expect(advMath.examVariant, isNot(equals(appMath.examVariant)));
    });

    test('SchoolClassSummary uses neutral metrics without pejorative badges',
        () {
      final classSummary = SchoolClassSummary.fromJson(const {
        'classroom_id': 'cls-12a',
        'classroom_name': 'Grade 12A',
        'grade': 12,
        'section': 'A',
        'stream': 'natural',
        'enrolled_count': 45,
        'active_students': 43,
        'completed_assessments': 86,
        'avg_score_pct': 69.2,
        'completion_rate_pct': 95.56,
        'assigned_teacher_count': 5,
        'students_needing_help': 3,
      });

      expect(classSummary.classroomName, 'Grade 12A');
      expect(classSummary.completionRatePct, 95.56);
      expect(classSummary.avgScorePct, 69.2);
      expect(classSummary.stream, 'natural');
    });

    test('SchoolAssessmentOverview preserves canonical P5 provenance', () {
      final assessments = [
        SchoolAssessmentOverview.fromJson({
          'assessment_id': 'exam-p5-01',
          'title': 'ESSLCE 2015 E.C. National Exam',
          'subject_id': 'physics_g12',
          'subject_name': 'Physics Grade 12',
          'provenance': 'officialPastExam',
          'grade': 12,
          'stream': 'natural',
          'submission_count': 156,
          'avg_percentage': 68.2,
          'median_percentage': 70.0,
          'highest_percentage': 96.0,
          'lowest_percentage': 32.0,
          'created_at': DateTime.now().toIso8601String(),
        }),
        SchoolAssessmentOverview.fromJson({
          'assessment_id': 'exam-p5-02',
          'title': 'Addis Ababa City Prep Model Exam',
          'subject_id': 'chem_g12',
          'subject_name': 'Chemistry Grade 12',
          'provenance': 'modelExam',
          'grade': 12,
          'stream': 'natural',
          'submission_count': 142,
          'avg_percentage': 63.4,
          'median_percentage': 64.0,
          'highest_percentage': 92.0,
          'lowest_percentage': 28.0,
          'created_at': DateTime.now().toIso8601String(),
        }),
        SchoolAssessmentOverview.fromJson({
          'assessment_id': 'exam-p5-03',
          'title': 'Unit 3 Thermodynamics Midterm',
          'subject_id': 'physics_g12',
          'subject_name': 'Physics Grade 12',
          'provenance': 'teacherCustom',
          'grade': 12,
          'stream': 'natural',
          'submission_count': 45,
          'avg_percentage': 72.1,
          'median_percentage': 74.0,
          'highest_percentage': 98.0,
          'lowest_percentage': 44.0,
          'created_at': DateTime.now().toIso8601String(),
        }),
      ];

      expect(assessments[0].provenance, 'officialPastExam');
      expect(assessments[0].isOfficialPastExam, isTrue);
      expect(assessments[0].provenanceLabel, 'Official Historical Paper');

      expect(assessments[1].provenance, 'modelExam');
      expect(assessments[1].isModelExam, isTrue);
      expect(assessments[1].provenanceLabel, 'Verified Model Exam');

      expect(assessments[2].provenance, 'teacherCustom');
      expect(assessments[2].isTeacherCustom, isTrue);
      expect(assessments[2].provenanceLabel, 'Teacher Assignment');
    });
  });

  group('LocalSchoolLeadershipRepository Contract Tests', () {
    late LocalSchoolLeadershipRepository repo;

    setUp(() {
      repo = LocalSchoolLeadershipRepository();
    });

    test('getLeadershipSummary returns non-null mock data', () async {
      final summary = await repo.getLeadershipSummary(schoolId: 'sch-test-01');
      expect(summary, isNotNull);
      expect(summary.schoolName, contains('Secondary School'));
      expect(summary.totalActiveStudents, 840);
      expect(summary.simulationParticipationRate, greaterThan(0));
    });

    test('getStreamSummary returns both Natural and Social streams', () async {
      final streams = await repo.getStreamSummary(schoolId: 'sch-test-01');
      expect(streams.length, 2);
      expect(streams.any((s) => s.isNatural), isTrue);
      expect(streams.any((s) => s.isSocial), isTrue);
    });

    test('getSubjectSummary returns separated Math variants with canonical ID',
        () async {
      final subjects = await repo.getSubjectSummary(schoolId: 'sch-test-01');
      expect(subjects, isNotEmpty);

      final mathSubjects =
          subjects.where((s) => s.subjectId == 'math_g12').toList();
      expect(mathSubjects.length, 2);

      final natMath =
          mathSubjects.firstWhere((s) => s.examVariant == 'naturalScience');
      final socMath =
          mathSubjects.firstWhere((s) => s.examVariant == 'socialScience');

      expect(natMath.displayName, 'Mathematics — Natural Science');
      expect(socMath.displayName, 'Mathematics — Social Science');
      expect(natMath.stream.toLowerCase(), contains('nat'));
      expect(socMath.stream.toLowerCase(), contains('soc'));
    });

    test('getSystemicWeakTopics calculates mistake concentration', () async {
      final topics = await repo.getSystemicWeakTopics(schoolId: 'sch-test-01');
      expect(topics, isNotEmpty);
      for (final t in topics) {
        expect(t.activeMistakeCount, greaterThan(0));
        expect(t.mistakeConcentrationPct, greaterThan(0));
      }
    });

    test('getSupportPopulation filters by severity and supports pagination',
        () async {
      final highStudents = await repo.getSupportPopulation(
        schoolId: 'sch-test-01',
        severity: 'high',
        limit: 10,
        offset: 0,
      );

      expect(highStudents, isNotEmpty);
      for (final s in highStudents) {
        expect(s.severity, AttentionSeverity.high);
      }

      final page1 = await repo.getSupportPopulation(
        schoolId: 'sch-test-01',
        limit: 2,
        offset: 0,
      );
      expect(page1.length, 2);

      final page2 = await repo.getSupportPopulation(
        schoolId: 'sch-test-01',
        limit: 2,
        offset: 2,
      );
      expect(page2.length, 2);
      expect(page1.first.studentId, isNot(equals(page2.first.studentId)));
    });

    test('getAssessmentsOverview returns assessments with P5 provenance',
        () async {
      final assessments = await repo.getAssessmentsOverview(
        schoolId: 'sch-test-01',
      );
      expect(assessments, isNotEmpty);
      expect(assessments.any((a) => a.isOfficialPastExam), isTrue);
    });

    test('getTeacherCoverage returns oversight information without ranking',
        () async {
      final teachers = await repo.getTeacherCoverage(schoolId: 'sch-test-01');
      expect(teachers, isNotEmpty);
      for (final t in teachers) {
        expect(t.classroomName, isNotEmpty);
        expect(t.totalActiveAssignments, greaterThanOrEqualTo(0));
      }
    });

    test('getStudentAcademicSummary returns complete diagnostic profile',
        () async {
      final studentSummary = await repo.getStudentAcademicSummary(
        schoolId: 'sch-test-01',
        studentId: 'stu-p8-001',
      );
      expect(studentSummary.studentId, 'stu-p8-001');
      expect(studentSummary.recentAssessments, isNotEmpty);
      expect(studentSummary.weakTopics, isNotEmpty);
    });
  });

  group(
      'P5 Provenance Fidelity Tests (P7 Teacher Portal vs P8 School Leadership)',
      () {
    test(
        'Official Historical Paper mappings and legacy aliases match between P7 and P8',
        () {
      final p7Summary1 = ClassExamSummary.fromJson(const {
        'exam_id': 'e1',
        'exam_title': 'Exam 1',
        'source_type': 'officialHistoricalPaper',
        'exam_mode': 'historicalPaper',
      });
      final p8Summary1 = SchoolAssessmentSummary.fromJson(const {
        'exam_id': 'e1',
        'exam_title': 'Exam 1',
        'source_type': 'officialHistoricalPaper',
        'exam_mode': 'historicalPaper',
      });
      expect(p7Summary1.provenanceLabel, 'Official Historical Paper');
      expect(p8Summary1.provenanceLabel, 'Official Historical Paper');
      expect(p7Summary1.provenanceLabel, equals(p8Summary1.provenanceLabel));

      // Legacy aliases: officialPastExam, officialPastPaper
      for (final alias in ['officialPastExam', 'officialPastPaper']) {
        final p7 = ClassExamSummary.fromJson({
          'exam_id': 'e2',
          'exam_title': 'Exam 2',
          'source_type': alias,
          'exam_mode': 'historicalPaper',
        });
        final p8 = SchoolAssessmentSummary.fromJson({
          'exam_id': 'e2',
          'exam_title': 'Exam 2',
          'source_type': alias,
          'exam_mode': 'historicalPaper',
        });
        expect(p7.provenanceLabel, 'Official Historical Paper');
        expect(p8.provenanceLabel, 'Official Historical Paper');
        expect(p7.provenanceLabel, equals(p8.provenanceLabel));
      }
    });

    test('Verified Model Exam mappings and aliases match between P7 and P8',
        () {
      for (final src in ['verifiedModelPaper', 'verifiedModel', 'modelexam']) {
        final p7 = ClassExamSummary.fromJson({
          'exam_id': 'm1',
          'exam_title': 'Model 1',
          'source_type': src,
          'exam_mode': 'practice',
        });
        final p8 = SchoolAssessmentSummary.fromJson({
          'exam_id': 'm1',
          'exam_title': 'Model 1',
          'source_type': src,
          'exam_mode': 'practice',
        });
        expect(p7.provenanceLabel, 'Verified Model Exam');
        expect(p8.provenanceLabel, 'Verified Model Exam');
        expect(p7.provenanceLabel, equals(p8.provenanceLabel));
      }
    });

    test('FidelLearn Simulation mappings match between P7 and P8', () {
      final p7 = ClassExamSummary.fromJson(const {
        'exam_id': 's1',
        'exam_title': 'Sim 1',
        'source_type': 'generatedSimulation',
        'exam_mode': 'nationalSimulation',
      });
      final p8 = SchoolAssessmentSummary.fromJson(const {
        'exam_id': 's1',
        'exam_title': 'Sim 1',
        'source_type': 'generatedSimulation',
        'exam_mode': 'nationalSimulation',
      });
      expect(p7.provenanceLabel, 'FidelLearn ESSLCE Simulation');
      expect(p8.provenanceLabel, 'FidelLearn ESSLCE Simulation');
      expect(p7.provenanceLabel, equals(p8.provenanceLabel));

      // Legacy context mock_full
      final p7Mock = ClassExamSummary.fromJson(const {
        'exam_id': 's2',
        'exam_title': 'Sim 2',
        'exam_type': 'mock_full',
      });
      final p8Mock = SchoolAssessmentSummary.fromJson(const {
        'exam_id': 's2',
        'exam_title': 'Sim 2',
        'exam_type': 'mock_full',
      });
      expect(p7Mock.provenanceLabel, 'FidelLearn ESSLCE Simulation');
      expect(p8Mock.provenanceLabel, 'FidelLearn ESSLCE Simulation');
      expect(p7Mock.provenanceLabel, equals(p8Mock.provenanceLabel));
    });

    test(
        'Custom Builder, Unit Test, Teacher Assignment, and Practice match between P7 and P8',
        () {
      // Custom Builder
      final p7Custom = ClassExamSummary.fromJson(const {
        'exam_id': 'c1',
        'exam_title': 'Custom 1',
        'source_type': 'custom',
        'exam_mode': 'custom',
        'exam_type': 'custom_builder',
      });
      final p8Custom = SchoolAssessmentSummary.fromJson(const {
        'exam_id': 'c1',
        'exam_title': 'Custom 1',
        'source_type': 'custom',
        'exam_mode': 'custom',
        'exam_type': 'custom_builder',
      });
      expect(p7Custom.provenanceLabel, 'Custom Exam');
      expect(p8Custom.provenanceLabel, 'Custom Exam');
      expect(p7Custom.provenanceLabel, equals(p8Custom.provenanceLabel));

      // Unit Test
      final p7UnitTest = ClassExamSummary.fromJson(const {
        'exam_id': 'u1',
        'exam_title': 'Unit Test 1',
        'exam_type': 'unit_test',
      });
      final p8UnitTest = SchoolAssessmentSummary.fromJson(const {
        'exam_id': 'u1',
        'exam_title': 'Unit Test 1',
        'exam_type': 'unit_test',
      });
      expect(p7UnitTest.provenanceLabel, 'Unit Test');
      expect(p8UnitTest.provenanceLabel, 'Unit Test');
      expect(p7UnitTest.provenanceLabel, equals(p8UnitTest.provenanceLabel));

      // Teacher Assignment
      final p7Teacher = ClassExamSummary.fromJson(const {
        'exam_id': 't1',
        'exam_title': 'Teacher 1',
        'exam_type': 'teacher_assigned',
      });
      final p8Teacher = SchoolAssessmentSummary.fromJson(const {
        'exam_id': 't1',
        'exam_title': 'Teacher 1',
        'exam_type': 'teacher_assigned',
      });
      expect(p7Teacher.provenanceLabel, 'Teacher Assignment');
      expect(p8Teacher.provenanceLabel, 'Teacher Assignment');
      expect(p7Teacher.provenanceLabel, equals(p8Teacher.provenanceLabel));

      // Practice
      final p7Practice = ClassExamSummary.fromJson(const {
        'exam_id': 'p1',
        'exam_title': 'Practice 1',
        'source_type': 'practice',
        'exam_mode': 'practice',
      });
      final p8Practice = SchoolAssessmentSummary.fromJson(const {
        'exam_id': 'p1',
        'exam_title': 'Practice 1',
        'source_type': 'practice',
        'exam_mode': 'practice',
      });
      expect(p7Practice.provenanceLabel, 'Practice');
      expect(p8Practice.provenanceLabel, 'Practice');
      expect(p7Practice.provenanceLabel, equals(p8Practice.provenanceLabel));
    });
  });

  group('Production Offline Invariant Tests (Section 34 & 35)', () {
    test(
        'SupabaseSchoolLeadershipRepository throws SchoolLeadershipOfflineException on offline network failure and does not invoke mock',
        () async {
      final failingClient = _FailingSupabaseClient();
      final repo = SupabaseSchoolLeadershipRepository(failingClient);

      expect(
        () => repo.getLeadershipSummary(schoolId: 'sch-001'),
        throwsA(isA<SchoolLeadershipOfflineException>()),
      );
      expect(
        () => repo.getStreamSummary(schoolId: 'sch-001'),
        throwsA(isA<SchoolLeadershipOfflineException>()),
      );
      expect(
        () => repo.getSubjectSummary(schoolId: 'sch-001'),
        throwsA(isA<SchoolLeadershipOfflineException>()),
      );
    });

    test(
        'Explicit LocalSchoolLeadershipRepository override supplies synthetic fixture for demo/test environments',
        () async {
      final localRepo = LocalSchoolLeadershipRepository();
      final summary =
          await localRepo.getLeadershipSummary(schoolId: 'sch-test');

      expect(summary, isNotNull);
      expect(summary.totalActiveStudents, greaterThan(0));
      expect(summary.simulationParticipationRate, greaterThan(0));
    });
  });
}
