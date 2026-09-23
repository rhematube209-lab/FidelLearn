import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/features/subjects/domain/models/subject_models.dart';
import 'package:fidel_learn/features/subjects/domain/services/curriculum_coverage_service.dart';
import 'package:fidel_learn/features/question_bank/domain/models/question_models.dart';

void main() {
  group('CurriculumCoverageService - Readiness & Metrics Evaluation', () {
    late CurriculumCoverageService service;

    setUp(() {
      service = CurriculumCoverageService();
    });

    const testSubject = Subject(
      id: 'physics_g12',
      code: 'PHYS12',
      nameEn: 'Physics',
      nameAm: 'ፊዚክስ',
      grade: 12,
      stream: 'natural',
      sortOrder: 1,
    );

    const testUnits = [
      Unit(
        id: 'phys_u1',
        subjectId: 'physics_g12',
        unitNumber: 1,
        titleEn: 'Kinematics',
        titleAm: 'ኪነማቲክስ',
      ),
      Unit(
        id: 'phys_u2',
        subjectId: 'physics_g12',
        unitNumber: 2,
        titleEn: 'Dynamics',
        titleAm: 'ዳይናሚክስ',
      ),
    ];

    Question makeQuestion({
      required String id,
      required String unitId,
      VerificationStatus status = VerificationStatus.published,
      String solution =
          'Valid step-by-step solution text explaining the concept.',
      String? keyConcept = 'Newtonian Mechanics',
      String? commonPitfall = 'Confusing velocity with acceleration',
      String? amharicText = 'የአማርኛ ጥያቄ ጽሁፍ',
    }) {
      return Question(
        id: id,
        subjectId: 'physics_g12',
        unitId: unitId,
        topicId: 'topic_test',
        grade: 12,
        stream: 'natural',
        difficulty: 'medium',
        questionTextEn: 'What is the velocity of a particle in uniform motion?',
        questionTextAm: amharicText,
        verificationStatus: status,
        sourceName: 'ESSLCE 2014 E.C.',
        examYear: 2014,
        contentVersion: 1,
        choices: const [
          AnswerChoice(
              id: 'c1', label: 'A', textEn: 'Constant', isCorrect: true),
          AnswerChoice(id: 'c2', label: 'B', textEn: 'Zero', isCorrect: false),
        ],
        explanation: Explanation(
          solutionTextEn: solution,
          solutionTextAm: 'የተሟላ ማብራሪያ',
          keyConcept: keyConcept,
          commonPitfall: commonPitfall,
        ),
      );
    }

    test('evaluates NOT STARTED when zero questions exist', () {
      final metrics = service.evaluateSubject(
        subject: testSubject,
        units: testUnits,
        questions: [],
      );

      expect(metrics.readiness, equals(SubjectLaunchReadiness.notStarted));
      expect(metrics.totalQuestions, equals(0));
      expect(metrics.unitCoveragePercent, equals(0.0));
      expect(metrics.blockingGaps, isNotEmpty);
    });

    test(
        'evaluates IN PROGRESS when question count is below minimum threshold (< 5)',
        () {
      final questions = [
        makeQuestion(id: 'q1', unitId: 'phys_u1'),
        makeQuestion(id: 'q2', unitId: 'phys_u2'),
      ];

      final metrics = service.evaluateSubject(
        subject: testSubject,
        units: testUnits,
        questions: questions,
      );

      expect(metrics.readiness, equals(SubjectLaunchReadiness.inProgress));
      expect(metrics.totalQuestions, equals(2));
      expect(metrics.blockingGaps.any((g) => g.contains('need at least 5')),
          isTrue);
    });

    test(
        'evaluates CONTENT REVIEW when questions have drafts or pending review',
        () {
      final questions = List.generate(
        6,
        (i) => makeQuestion(
          id: 'q$i',
          unitId: i.isEven ? 'phys_u1' : 'phys_u2',
          status: i == 0
              ? VerificationStatus.reviewRequired
              : VerificationStatus.published,
        ),
      );

      final metrics = service.evaluateSubject(
        subject: testSubject,
        units: testUnits,
        questions: questions,
      );

      expect(metrics.readiness, equals(SubjectLaunchReadiness.contentReview));
      expect(metrics.reviewRequiredQuestions, equals(1));
    });

    test('evaluates QA when rationale coverage is below 85%', () {
      final questions = List.generate(
        10,
        (i) => makeQuestion(
          id: 'q$i',
          unitId: i < 5 ? 'phys_u1' : 'phys_u2',
          status: VerificationStatus.published,
          solution: i < 5 ? 'Good explanation' : 'No explanation available.',
        ),
      );

      final metrics = service.evaluateSubject(
        subject: testSubject,
        units: testUnits,
        questions: questions,
      );

      expect(metrics.readiness, equals(SubjectLaunchReadiness.qa));
      expect(metrics.rationaleCoveragePercent, equals(50.0));
    });

    test(
        'evaluates READY FOR LAUNCH when all curriculum, verification, and rationale criteria pass',
        () {
      final questions = List.generate(
        10,
        (i) => makeQuestion(
          id: 'q$i',
          unitId: i < 5 ? 'phys_u1' : 'phys_u2',
          status: VerificationStatus.published,
          solution:
              'Complete step-by-step verified rationale with formula derivation.',
        ),
      );

      final metrics = service.evaluateSubject(
        subject: testSubject,
        units: testUnits,
        questions: questions,
      );

      expect(metrics.readiness, equals(SubjectLaunchReadiness.readyForLaunch));
      expect(metrics.totalQuestions, equals(10));
      expect(metrics.publishedQuestions, equals(10));
      expect(metrics.unitCoveragePercent, equals(100.0));
      expect(metrics.rationaleCoveragePercent, equals(100.0));
      expect(metrics.blockingGaps, isEmpty);
    });

    test(
        'generateReport aggregates readiness metrics across multiple launch subjects',
        () {
      final readyQuestions = List.generate(
        10,
        (i) => makeQuestion(
          id: 'q_ready_$i',
          unitId: 'phys_u1',
          status: VerificationStatus.published,
        ),
      );

      const subject2 = Subject(
        id: 'biology_g12',
        code: 'BIO12',
        nameEn: 'Biology',
        nameAm: 'ባዮሎጂ',
        grade: 12,
        stream: 'natural',
        sortOrder: 2,
      );

      final report = service.generateReport(
        subjects: [testSubject, subject2],
        units: testUnits,
        questions:
            readyQuestions, // subject 1 has questions, subject 2 has none
      );

      expect(report.subjectMetrics.length, equals(2));
      expect(report.totalQuestions, equals(10));
      expect(report.readySubjectsCount, equals(1));
      expect(report.allLaunchSubjectsReady, isFalse);
    });
  });
}
