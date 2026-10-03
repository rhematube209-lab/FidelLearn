import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/features/teacher/domain/models/teacher_portal_models.dart';
import 'package:fidel_learn/features/teacher/data/repositories/local_teacher_portal_repository.dart';

void main() {
  group('P7 Teacher Portal Models Test', () {
    test('AttentionSeverity parses and formats labels correctly', () {
      expect(AttentionSeverity.fromString('high'), AttentionSeverity.high);
      expect(AttentionSeverity.fromString('MEDIUM'), AttentionSeverity.medium);
      expect(AttentionSeverity.fromString('low'), AttentionSeverity.low);
      expect(AttentionSeverity.fromString('other'), AttentionSeverity.low);
      expect(AttentionSeverity.fromString(null), AttentionSeverity.low);

      expect(AttentionSeverity.high.displayLabel, 'Needs Immediate Support');
      expect(AttentionSeverity.medium.displayLabel, 'Needs Attention');
      expect(AttentionSeverity.low.displayLabel, 'Monitor');
    });

    test('AttentionReasonCode generates accurate educational explanations', () {
      expect(
        AttentionReasonCode.fromString('low_recent_accuracy'),
        AttentionReasonCode.lowRecentAccuracy,
      );
      expect(
        AttentionReasonCode.fromString('high_mistake_count'),
        AttentionReasonCode.highMistakeCount,
      );
      expect(
        AttentionReasonCode.fromString('elevated_mistake_count'),
        AttentionReasonCode.elevatedMistakeCount,
      );
      expect(
        AttentionReasonCode.fromString('no_recent_activity'),
        AttentionReasonCode.noRecentActivity,
      );
      expect(
        AttentionReasonCode.fromString('borderline_accuracy'),
        AttentionReasonCode.borderlineAccuracy,
      );
      expect(
        AttentionReasonCode.fromString('other_unknown'),
        AttentionReasonCode.unknown,
      );

      final expAccuracy =
          AttentionReasonCode.lowRecentAccuracy.toExplanation(accuracy: 42.0);
      expect(expAccuracy, contains('42% average accuracy'));

      final expMistakes =
          AttentionReasonCode.highMistakeCount.toExplanation(mistakeCount: 7);
      expect(expMistakes, contains('7 active unmastered mistakes recorded'));

      final expActivity = AttentionReasonCode.noRecentActivity.toExplanation(
          lastActivity: DateTime.now().subtract(const Duration(days: 10)));
      expect(expActivity, contains('last 10 days'));
    });

    test('ClassExamSummary preserves P5 examType and computes participation',
        () {
      final summary = ClassExamSummary(
        examId: 'ex1',
        examTitle: 'ESSLCE Physics Simulation 2026',
        examType: 'mock_full',
        examMode: 'nationalSimulation',
        sourceType: 'generatedSimulation',
        totalQuestions: 40,
        participantCount: 30,
        enrolledCount: 40,
        avgPercentage: 65.0,
        medianPercentage: 68.0,
        notSubmitted: 10,
        examCreatedAt: DateTime.now(),
      );

      expect(summary.participationRate, 0.75);
      expect(summary.provenanceLabel, 'FidelLearn ESSLCE Simulation');

      // Verify all 5 teacher-facing provenance categories
      final officialPast = ClassExamSummary(
        examId: 'e_hist',
        examTitle: '2014 E.C. Physics Exam',
        examType: 'mock_full',
        examMode: 'historicalPaper',
        sourceType: 'officialHistoricalPaper',
        totalQuestions: 60,
        participantCount: 20,
        enrolledCount: 20,
        avgPercentage: 70,
        medianPercentage: 70,
        notSubmitted: 0,
        examCreatedAt: DateTime(2026, 9, 1),
      );
      expect(officialPast.provenanceLabel, 'Official Historical Paper');

      // Legacy alias mapping: officialPastExam -> Official Historical Paper
      final legacyOfficial = ClassExamSummary(
        examId: 'e_legacy',
        examTitle: '2013 E.C. Exam',
        examType: 'mock_full',
        sourceType: 'officialPastExam',
        totalQuestions: 60,
        participantCount: 20,
        enrolledCount: 20,
        avgPercentage: 70,
        medianPercentage: 70,
        notSubmitted: 0,
        examCreatedAt: DateTime(2026, 9, 1),
      );
      expect(legacyOfficial.provenanceLabel, 'Official Historical Paper');

      final verifiedModel = ClassExamSummary(
        examId: 'e_model',
        examTitle: 'Ministry Model Exam 2026',
        examType: 'mock_full',
        sourceType: 'verifiedModelPaper',
        totalQuestions: 50,
        participantCount: 20,
        enrolledCount: 20,
        avgPercentage: 70,
        medianPercentage: 70,
        notSubmitted: 0,
        examCreatedAt: DateTime(2026, 9, 1),
      );
      expect(verifiedModel.provenanceLabel, 'Verified Model Exam');

      final customExam = ClassExamSummary(
        examId: 'e_custom',
        examTitle: 'Teacher Custom Drill',
        examType: 'custom_builder',
        sourceType: 'custom',
        totalQuestions: 15,
        participantCount: 20,
        enrolledCount: 20,
        avgPercentage: 70,
        medianPercentage: 70,
        notSubmitted: 0,
        examCreatedAt: DateTime(2026, 9, 1),
      );
      expect(customExam.provenanceLabel, 'Custom Exam');

      final practiceExam = ClassExamSummary(
        examId: 'e_practice',
        examTitle: 'Mechanics Practice',
        examType: 'practice',
        sourceType: 'practice',
        totalQuestions: 10,
        participantCount: 20,
        enrolledCount: 20,
        avgPercentage: 70,
        medianPercentage: 70,
        notSubmitted: 0,
        examCreatedAt: DateTime(2026, 9, 1),
      );
      expect(practiceExam.provenanceLabel, 'Practice');
    });

    test(
        'StudentAcademicSummary computes active mistakes and recommended intervention',
        () {
      const summary = StudentAcademicSummary(
        studentId: 's1',
        displayName: 'Abebe Bikila',
        schoolStudentId: 'STU1001',
        subjectId: 'phys_g12',
        subjectName: 'Physics',
        totalAttempts: 15,
        recentAvgPercentage: 42.0,
        overallAccuracyPercentage: 55.0,
        totalMistakes: 10,
        masteredMistakes: 3,
        weakTopics: [],
        recentExams: [],
      );

      expect(summary.activeMistakes, 7);
      expect(
          summary.recommendedAction, contains('7 active unmastered mistakes'));
      expect(summary.masteryAvailabilityNote, contains('device-local'));
    });
  });

  group('LocalTeacherPortalRepository Contract Test', () {
    late LocalTeacherPortalRepository repo;

    setUp(() {
      repo = LocalTeacherPortalRepository();
    });

    test(
        'getAssignedClasses returns authorized classroom assignments with metrics',
        () async {
      final classes = await repo.getAssignedClasses(schoolId: 'school_1');
      expect(classes, isNotEmpty);
      final first = classes.first;
      expect(first.classroom.grade, 12);
      expect(first.subjectName, 'Physics');
      expect(first.enrolledStudentCount, greaterThan(0));
      expect(first.attentionCount, isNotNull);
      expect(first.recentExamAvgPercentage, isNotNull);
    });

    test('getClassRoster paginates and filters by search', () async {
      final page1 = await repo.getClassRoster(
        classroomId: 'cls_12A',
        subjectId: 'physics_g12',
        pageSize: 10,
        offset: 0,
      );

      expect(page1.students.length, 10);
      expect(page1.totalCount, 44);
      expect(page1.hasMore, isTrue);

      final searchPage = await repo.getClassRoster(
        classroomId: 'cls_12A',
        subjectId: 'physics_g12',
        search: 'Almaz',
      );
      expect(searchPage.students, isNotEmpty);
      expect(
        searchPage.students.every((s) => s.displayName.contains('Almaz')),
        isTrue,
      );
    });

    test('getClassWeakTopics returns cloud-derived mistake topics', () async {
      final topics = await repo.getClassWeakTopics(
        classroomId: 'cls_12A',
        subjectId: 'physics_g12',
      );

      expect(topics, isNotEmpty);
      for (final t in topics) {
        expect(t.topicId, isNotEmpty);
        expect(t.affectedStudentCount, greaterThan(0));
        expect(t.activeMistakeCount, greaterThan(0));
      }
    });

    test('getClassExamSummary preserves P5 exam provenance', () async {
      final exams = await repo.getClassExamSummary(
        classroomId: 'cls_12A',
        subjectId: 'physics_g12',
      );

      expect(exams, isNotEmpty);
      final types = exams.map((e) => e.examType).toList();
      expect(types, contains('mock_full'));
    });

    test('getAttentionStudents returns prioritized items with reasons',
        () async {
      final page = await repo.getAttentionStudents(
        classroomId: 'cls_12A',
        subjectId: 'physics_g12',
      );

      expect(page.items, isNotEmpty);
      for (final item in page.items) {
        expect(item.studentId, isNotEmpty);
        expect(item.reasonCodes, isNotEmpty);
        expect(item.reasonExplanations, isNotEmpty);
        expect(item.recommendedAction, isNotEmpty);
      }
    });

    test(
        'getStudentSummary returns detailed academic metrics without private data',
        () async {
      final summary = await repo.getStudentSummary(
        studentId: 'student_3',
        classroomId: 'cls_12A',
        subjectId: 'physics_g12',
        subjectName: 'Physics',
      );

      expect(summary, isNotNull);
      expect(summary!.displayName, 'Almaz Tesfaye');
      expect(summary.weakTopics, isNotEmpty);
      expect(summary.recentExams, isNotEmpty);
      expect(summary.activeMistakes, greaterThan(0));
    });
  });
}
