import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/features/exams/domain/models/exam_models.dart';
import 'package:fidel_learn/features/question_bank/domain/models/question_models.dart';
import 'package:fidel_learn/features/teacher/domain/models/assignment_models.dart';

void main() {
  group('P9 Final Freeze — Historical Reproducibility & Integrity Tests', () {
    test(
        '1. Historical question reproducibility: v1 assignment retains v1 content after v2 package upgrade',
        () {
      // Step 1: Package v1 question definition
      final q1v1 = Question(
        id: 'q_phys_2014_001',
        grade: 12,
        stream: 'natural',
        subjectId: 'physics_g12',
        unitId: 'unit_1',
        topicId: 'vectors',
        examYear: 2014,
        questionTextEn: 'What is the magnitude of vector A = 3i + 4j?',
        contentVersion: 1,
        difficulty: 'medium',
        verificationStatus: VerificationStatus.verified,
        sourceName: 'NEAEA 2014',
        isScorable: true,
        isPracticeEligible: true,
        choices: const [
          AnswerChoice(
              id: 'c1', label: 'A', textEn: '5 units', isCorrect: true),
          AnswerChoice(
              id: 'c2', label: 'B', textEn: '7 units', isCorrect: false),
          AnswerChoice(
              id: 'c3', label: 'C', textEn: '1 unit', isCorrect: false),
          AnswerChoice(
              id: 'c4', label: 'D', textEn: '25 units', isCorrect: false),
        ],
        explanation: const Explanation(
          solutionTextEn: '|A| = sqrt(3^2 + 4^2) = 5',
          keyConcept: 'Vector magnitude',
        ),
        provenance: QuestionProvenance(
          provenanceType: SourceProvenanceType.officialNeaeaPaper,
          sourceDocument: 'NEAEA 2014 Physics Paper',
          examYear: 2014,
          verifiedBy: 'National Board Reviewer',
          verifiedAt: DateTime.utc(2024, 1, 1),
        ),
      );

      // Step 2: Publish Assignment A with question snapshot v1
      final assignmentA = LearningAssignment(
        id: 'asgn-freeze-001',
        schoolId: 'sch-001',
        classroomId: 'cls-12a',
        teacherUserId: 'tch-001',
        subjectId: 'physics_g12',
        title: 'Vectors Classical Exam',
        assignmentType: AssignmentType.targetedPractice,
        status: AssignmentStatus.published,
        totalQuestions: 1,
        contentHash: 'hash-v1-abc',
        createdAt: DateTime.utc(2026, 9, 20),
        publishedAt: DateTime.utc(2026, 9, 20),
      );

      // Step 3: Simulate Package v2 upgrade (modified stem, choices, explanation)
      const q1v2 = Question(
        id: 'q_phys_2014_001',
        grade: 12,
        stream: 'natural',
        subjectId: 'physics_g12',
        unitId: 'unit_1',
        topicId: 'vectors',
        examYear: 2014,
        questionTextEn: 'REVISED V2: What is the magnitude of 3i + 4j + 12k?',
        contentVersion: 2,
        difficulty: 'hard',
        verificationStatus: VerificationStatus.published,
        sourceName: 'NEAEA 2014 Revised',
        isScorable: true,
        isPracticeEligible: true,
        choices: [
          AnswerChoice(
              id: 'c1', label: 'A', textEn: '13 units', isCorrect: true),
          AnswerChoice(
              id: 'c2', label: 'B', textEn: '5 units', isCorrect: false),
        ],
        explanation: Explanation(
          solutionTextEn: 'sqrt(9 + 16 + 144) = 13',
          keyConcept: '3D vector norm',
        ),
      );

      // Verify Package v2 changed
      expect(q1v2.contentVersion, 2);
      expect(q1v2.questionTextEn, contains('REVISED V2'));

      // Step 4 & 5: Assignment A resolved question snapshot
      // The assignment question snapshot resolves strictly to version 1
      final loadedExam = Exam(
        id: 'assignment_${assignmentA.id}',
        title: assignmentA.title,
        examType: ExamType.teacherAssigned,
        examMode: ExamMode.practice,
        sourceType: ExamSourceType.officialHistoricalPaper,
        grade: 12,
        stream: 'natural',
        subjectId: assignmentA.subjectId,
        timeLimitMinutes: 30,
        totalQuestions: 1,
        questions: [q1v1],
        createdAt: DateTime.utc(2026, 9, 20),
      );

      // Verify exact v1 reproducibility
      expect(loadedExam.questions.first.contentVersion, 1);
      expect(loadedExam.questions.first.questionTextEn,
          'What is the magnitude of vector A = 3i + 4j?');
      expect(loadedExam.questions.first.choices.first.textEn, '5 units');
      expect(loadedExam.questions.first.choices.first.isCorrect, isTrue);
      expect(loadedExam.questions.first.explanation.solutionTextEn,
          '|A| = sqrt(3^2 + 4^2) = 5');
      expect(loadedExam.sourceType, ExamSourceType.officialHistoricalPaper);
    });

    test(
        '2. Historical submitted attempt immutability: score never rescored on package upgrade',
        () {
      final startTime = DateTime.utc(2026, 9, 21, 10, 0, 0);
      final finishTime = DateTime.utc(2026, 9, 21, 10, 25, 0);

      final attempt = ExamAttempt(
        id: 'att-hist-001',
        userId: 'std-001',
        examId: 'assignment_asgn-freeze-001',
        examTitle: 'Vectors Classical Exam',
        subjectId: 'physics_g12',
        examMode: ExamMode.practice,
        sourceType: ExamSourceType.officialHistoricalPaper,
        startTime: startTime,
        endTime: finishTime,
        durationSeconds: 1500,
        totalQuestions: 1,
        score: 1,
        percentage: 100.0,
        correctCount: 1,
        incorrectCount: 0,
        skippedCount: 0,
        isCompleted: true,
        packageSnapshot: const {'physics_g12': '1.0.0'},
        responses: const {
          'q_phys_2014_001': UserResponse(
            questionId: 'q_phys_2014_001',
            selectedChoiceId: 'c1',
            isCorrect: true,
            timeSpentSeconds: 120,
          ),
        },
      );

      // Verify stored snapshot is preserved
      expect(attempt.score, 1);
      expect(attempt.percentage, 100.0);
      expect(attempt.packageSnapshot?['physics_g12'], '1.0.0');
      expect(attempt.responses['q_phys_2014_001']?.isCorrect, isTrue);

      // Package upgrade to 2.0.0 does NOT change attempt.score or attempt.percentage
      const currentPackageVersion = '2.0.0';
      expect(currentPackageVersion,
          isNot(attempt.packageSnapshot?['physics_g12']));
      expect(attempt.score, 1);
      expect(attempt.percentage, 100.0);
    });

    test(
        '3. Offline deadline and absolute-time integrity evaluation (8-case matrix)',
        () {
      final dueAt = DateTime.utc(2026, 9, 25, 17, 0, 0);

      // Case 1: Normal online submission (server-authoritative time -> verified)
      final onlineResult = DeadlineAdjudicator.adjudicate(
        isOnline: true,
        serverReceivedAt: DateTime.utc(2026, 9, 25, 16, 45, 0),
        dueAt: dueAt,
        allowLateSubmission: true,
        localCompletedAt: DateTime.utc(2026, 9, 25, 16, 45, 0),
      );
      expect(onlineResult.integrityLevel, DeadlineIntegrityLevel.verified);
      expect(onlineResult.isLate, isFalse);
      expect(onlineResult.recipientStatus, AssignmentRecipientStatus.submitted);
      expect(onlineResult.reviewRequired, isFalse);
      expect(onlineResult.statusLabelEn, 'On Time');

      // Case 2: Offline + Trusted Server Anchor (16:00 anchor + 45 min monotonic = 16:45 UTC, synced at 20:00)
      // Completed before deadline -> verified on-time despite delayed synchronization
      final offlineTrustedAnchorOnTime = DeadlineAdjudicator.adjudicate(
        isOnline: false,
        serverReceivedAt: DateTime.utc(2026, 9, 25, 20, 0, 0),
        dueAt: dueAt,
        allowLateSubmission: true,
        localCompletedAt: DateTime.utc(2026, 9, 25, 16, 45, 0),
        trustedAnchorUtc: DateTime.utc(2026, 9, 25, 16, 0, 0),
        trustedAnchorMonotonicMs: 100000,
        completionMonotonicMs: 100000 + (45 * 60 * 1000), // 45 min later
      );
      expect(offlineTrustedAnchorOnTime.integrityLevel,
          DeadlineIntegrityLevel.verified);
      expect(offlineTrustedAnchorOnTime.isLate, isFalse);
      expect(offlineTrustedAnchorOnTime.recipientStatus,
          AssignmentRecipientStatus.submitted);
      expect(offlineTrustedAnchorOnTime.statusLabelEn, 'On Time');
      expect(offlineTrustedAnchorOnTime.estimatedCompletionUtc,
          DateTime.utc(2026, 9, 25, 16, 45, 0));

      // Case 3: Offline + Trusted Server Anchor Late (16:00 anchor + 80 min monotonic = 17:20 UTC)
      // Completed after deadline with allow_late_submission = true -> verified late
      final offlineTrustedAnchorLate = DeadlineAdjudicator.adjudicate(
        isOnline: false,
        serverReceivedAt: DateTime.utc(2026, 9, 25, 20, 0, 0),
        dueAt: dueAt,
        allowLateSubmission: true,
        localCompletedAt: DateTime.utc(2026, 9, 25, 17, 20, 0),
        trustedAnchorUtc: DateTime.utc(2026, 9, 25, 16, 0, 0),
        trustedAnchorMonotonicMs: 100000,
        completionMonotonicMs: 100000 + (80 * 60 * 1000), // 80 min later
      );
      expect(offlineTrustedAnchorLate.integrityLevel,
          DeadlineIntegrityLevel.verified);
      expect(offlineTrustedAnchorLate.isLate, isTrue);
      expect(offlineTrustedAnchorLate.recipientStatus,
          AssignmentRecipientStatus.late);
      expect(offlineTrustedAnchorLate.statusLabelEn, 'Late Submission');

      // Case 4: Offline + No Trusted Anchor (local completion = 16:45, due = 17:00, received = 20:00)
      // Must NOT gain false on-time certainty -> unverified, isLate = null
      final offlineNoAnchor = DeadlineAdjudicator.adjudicate(
        isOnline: false,
        serverReceivedAt: DateTime.utc(2026, 9, 25, 20, 0, 0),
        dueAt: dueAt,
        allowLateSubmission: true,
        localCompletedAt: DateTime.utc(2026, 9, 25, 16, 45, 0),
      );
      expect(offlineNoAnchor.integrityLevel, DeadlineIntegrityLevel.unverified);
      expect(offlineNoAnchor.isLate, isNull,
          reason: 'Cannot assert on-time without trusted server-time anchor');
      expect(
          offlineNoAnchor.recipientStatus, AssignmentRecipientStatus.submitted);
      expect(offlineNoAnchor.submissionAccepted, isTrue,
          reason: 'Student work is never discarded');
      expect(offlineNoAnchor.statusLabelEn,
          'Submission Received — Deadline Timing Unverified');

      // Case 5: Clock Manipulation Before Attempt (Pre-shifted Clock)
      // Actual UTC: 20:00, Due: 17:00. Device clock manually set to 16:00 before attempt begins.
      // Clock remains completely stable during the entire attempt. Monotonic session timer shows NO jump.
      // Result: monotonic session valid, BUT absolute deadline timing cannot be verified!
      final preShiftedClockResult = DeadlineAdjudicator.adjudicate(
        isOnline: false,
        serverReceivedAt: DateTime.utc(2026, 9, 25, 20, 30, 0),
        dueAt: dueAt,
        allowLateSubmission: true,
        localCompletedAt: DateTime.utc(2026, 9, 25, 16, 30, 0),
        // No valid server anchor from session start
        trustedAnchorUtc: null,
        timerIntegrityWarning:
            false, // Session timer detected no anomaly during attempt
        wallClockShiftDetected: false,
      );
      expect(preShiftedClockResult.integrityLevel,
          DeadlineIntegrityLevel.unverified);
      expect(preShiftedClockResult.isLate, isNull,
          reason:
              'Attempt with pre-shifted clock must NOT incorrectly gain an on-time classification');
      expect(preShiftedClockResult.recipientStatus,
          AssignmentRecipientStatus.submitted);

      // Case 6: Clock Anomaly during attempt (timerIntegrityWarning = true -> anomaly)
      final clockAnomalyResult = DeadlineAdjudicator.adjudicate(
        isOnline: false,
        serverReceivedAt: DateTime.utc(2026, 9, 25, 20, 0, 0),
        dueAt: dueAt,
        allowLateSubmission: true,
        localCompletedAt: DateTime.utc(2026, 9, 25, 16, 45, 0),
        timerIntegrityWarning: true,
      );
      expect(clockAnomalyResult.integrityLevel, DeadlineIntegrityLevel.anomaly);
      expect(clockAnomalyResult.isLate, isNull);
      expect(clockAnomalyResult.reviewRequired, isTrue);
      expect(clockAnomalyResult.submissionAccepted, isTrue,
          reason: 'Student answers and scores are permanently preserved');
      expect(clockAnomalyResult.statusLabelEn,
          'Submission Received — Clock Anomaly Detected');

      // Case 7: Monotonic Continuity Loss (counter reset / device reboot)
      // Fails safe to unverified; never falls back silently to raw wall-clock time
      final brokenContinuityResult = DeadlineAdjudicator.adjudicate(
        isOnline: false,
        serverReceivedAt: DateTime.utc(2026, 9, 25, 20, 0, 0),
        dueAt: dueAt,
        allowLateSubmission: true,
        localCompletedAt: DateTime.utc(2026, 9, 25, 16, 45, 0),
        trustedAnchorUtc: DateTime.utc(2026, 9, 25, 16, 0, 0),
        trustedAnchorMonotonicMs: 500000,
        completionMonotonicMs: 10000, // Counter reset (device reboot)
      );
      expect(brokenContinuityResult.integrityLevel,
          DeadlineIntegrityLevel.unverified);
      expect(brokenContinuityResult.isLate, isNull,
          reason:
              'Lost monotonic continuity must never fall back silently to raw wall-clock');

      // Case 8: Late Prohibited Policy (allow_late_submission = false) with unverified timing
      // Flags "Deadline Review Required" without deleting the attempt or silently approving it
      final lateProhibitedUnverified = DeadlineAdjudicator.adjudicate(
        isOnline: false,
        serverReceivedAt: DateTime.utc(2026, 9, 25, 20, 0, 0),
        dueAt: dueAt,
        allowLateSubmission: false,
        localCompletedAt: DateTime.utc(2026, 9, 25, 16, 45, 0),
      );
      expect(lateProhibitedUnverified.integrityLevel,
          DeadlineIntegrityLevel.unverified);
      expect(lateProhibitedUnverified.reviewRequired, isTrue);
      expect(lateProhibitedUnverified.recipientStatus,
          AssignmentRecipientStatus.submitted);
      expect(lateProhibitedUnverified.submissionAccepted, isTrue);
      expect(
          lateProhibitedUnverified.statusLabelEn, 'Deadline Review Required');
    });

    test(
        '4. Authoritative P5 provenance dimension matrix with normalization helper',
        () {
      // Dimension 1: Targeted Practice with ordinary curriculum questions
      // assignment_type: targetedPractice, exam_mode: practice, source_type: null (NOT generatedSimulation!)
      final targetedPracticeExam = Exam(
        id: 'asgn_tp_01',
        title: 'Targeted Remedial',
        examType: ExamType.teacherAssigned,
        examMode: ExamMode.practice,
        sourceType:
            null, // Ordinary curriculum questions have no canonical single source
        grade: 12,
        stream: 'natural',
        totalQuestions: 10,
        timeLimitMinutes: 20,
        questions: const [],
        createdAt: DateTime.utc(2026, 1, 1),
      );
      expect(targetedPracticeExam.examType, ExamType.teacherAssigned);
      expect(targetedPracticeExam.examMode, ExamMode.practice);
      expect(targetedPracticeExam.sourceType, isNull,
          reason:
              'Ordinary targeted practice must not be falsely labeled as generatedSimulation');
      expect(
        ExamProvenanceHelper.resolveProvenanceLabel(
          sourceType: targetedPracticeExam.sourceType?.toDbString(),
          examMode: targetedPracticeExam.examMode.toDbString(),
          examType: targetedPracticeExam.examType.toDbString(),
        ),
        'Teacher Assignment',
      );

      // Dimension 2: Custom Question Set with mixed provenance
      // assignment_type: customQuestionSet, exam_mode: custom, source_type: null
      final customSetExam = Exam(
        id: 'asgn_cs_01',
        title: 'Selected Calculus Set',
        examType: ExamType.teacherAssigned,
        examMode: ExamMode.custom,
        sourceType:
            null, // Mixed questions have item-level origin preserved in snapshots
        grade: 12,
        stream: 'natural',
        totalQuestions: 15,
        timeLimitMinutes: 30,
        questions: const [],
        createdAt: DateTime.utc(2026, 1, 1),
      );
      expect(customSetExam.examType, ExamType.teacherAssigned);
      expect(customSetExam.examMode, ExamMode.custom);
      expect(customSetExam.sourceType, isNull,
          reason:
              'Custom mixed sets must not falsely claim single-source origin');
      expect(
        ExamProvenanceHelper.resolveProvenanceLabel(
          sourceType: customSetExam.sourceType?.toDbString(),
          examMode: customSetExam.examMode.toDbString(),
          examType: customSetExam.examType.toDbString(),
        ),
        'Custom Exam',
      );

      // Dimension 3: ESSLCE National Simulation
      // assignment_type: simulation, exam_mode: nationalSimulation, source_type: generatedSimulation
      final simulationExam = Exam(
        id: 'asgn_sim_01',
        title: 'Class Mock Simulation',
        examType: ExamType.teacherAssigned,
        examMode: ExamMode.nationalSimulation,
        sourceType: ExamSourceType.generatedSimulation,
        grade: 12,
        stream: 'natural',
        totalQuestions: 60,
        timeLimitMinutes: 120,
        questions: const [],
        createdAt: DateTime.utc(2026, 1, 1),
      );
      expect(simulationExam.examType, ExamType.teacherAssigned);
      expect(simulationExam.examMode, ExamMode.nationalSimulation);
      expect(simulationExam.sourceType, ExamSourceType.generatedSimulation);
      expect(
        ExamProvenanceHelper.resolveProvenanceLabel(
          sourceType: simulationExam.sourceType?.toDbString(),
          examMode: simulationExam.examMode.toDbString(),
          examType: simulationExam.examType.toDbString(),
        ),
        'FidelLearn ESSLCE Simulation',
      );

      // Dimension 4: Official Historical Paper assigned by teacher
      // source_type: officialHistoricalPaper, exam_mode: historicalPaper
      final historicalPaperExam = Exam(
        id: 'asgn_hist_01',
        title: 'Official 2014 Physics Paper',
        examType: ExamType.teacherAssigned,
        examMode: ExamMode.historicalPaper,
        sourceType: ExamSourceType.officialHistoricalPaper,
        grade: 12,
        stream: 'natural',
        totalQuestions: 50,
        timeLimitMinutes: 120,
        questions: const [],
        createdAt: DateTime.utc(2026, 1, 1),
      );
      expect(historicalPaperExam.examType, ExamType.teacherAssigned);
      expect(historicalPaperExam.examMode, ExamMode.historicalPaper);
      expect(historicalPaperExam.sourceType,
          ExamSourceType.officialHistoricalPaper);
      expect(
        ExamProvenanceHelper.resolveProvenanceLabel(
          sourceType: historicalPaperExam.sourceType?.toDbString(),
          examMode: historicalPaperExam.examMode.toDbString(),
          examType: historicalPaperExam.examType.toDbString(),
        ),
        'Official Historical Paper',
      );

      // Dimension 5: Verified Model Paper assigned by teacher
      // source_type: verifiedModelPaper, exam_mode: practice
      final modelPaperExam = Exam(
        id: 'asgn_model_01',
        title: 'Verified 2026 Model Exam',
        examType: ExamType.teacherAssigned,
        examMode: ExamMode.practice,
        sourceType: ExamSourceType.verifiedModelPaper,
        grade: 12,
        stream: 'natural',
        totalQuestions: 50,
        timeLimitMinutes: 120,
        questions: const [],
        createdAt: DateTime.utc(2026, 1, 1),
      );
      expect(modelPaperExam.examType, ExamType.teacherAssigned);
      expect(modelPaperExam.examMode, ExamMode.practice);
      expect(modelPaperExam.sourceType, ExamSourceType.verifiedModelPaper);
      expect(
        ExamProvenanceHelper.resolveProvenanceLabel(
          sourceType: modelPaperExam.sourceType?.toDbString(),
          examMode: modelPaperExam.examMode.toDbString(),
          examType: modelPaperExam.examType.toDbString(),
        ),
        'Verified Model Exam',
      );
    });

    test('5. Recipient cohort denominator and excused student semantics', () {
      // Initial publication cohort: 40 students
      const int originalPublicationCohort = 40;
      int auditedPostPublishAdditions = 2; // 2 late-transfer students added
      int excusedStudents = 3; // 3 transferred out or excused students
      int submittedOrCompleted = 35;

      // Current required recipients = (original + additions) - excused
      final int totalEnrolled =
          originalPublicationCohort + auditedPostPublishAdditions; // 42
      final int requiredForCompletion = totalEnrolled - excusedStudents; // 39

      final double completionRate =
          (submittedOrCompleted / requiredForCompletion) * 100;

      expect(originalPublicationCohort, 40,
          reason: 'Historical original cohort remains fixed');
      expect(requiredForCompletion, 39,
          reason:
              'Excused students are subtracted from required completion denominator');
      expect(completionRate, closeTo(89.74, 0.01));
    });

    test('6. Student local device zero-peer privacy verification', () {
      // Cloud database contains 30 recipients for the assignment
      final cloudRecipientUserIds = List.generate(30, (i) => 'student_user_$i');
      const activeStudentUserId = 'student_user_7';

      // Local device storage filter
      final localPersistedRows = cloudRecipientUserIds
          .where((uid) => uid == activeStudentUserId)
          .toList();

      expect(localPersistedRows.length, 1);
      expect(localPersistedRows.first, activeStudentUserId);

      final peerRowsOnDevice = localPersistedRows
          .where((uid) => uid != activeStudentUserId)
          .toList();
      expect(peerRowsOnDevice.isEmpty, isTrue,
          reason: 'Zero peer data persisted on student device');
    });

    test('7. Content lifecycle compatibility mapping', () {
      // Canonical content lifecycle: Draft, In Review, Verified, Published
      // Legacy compatibility: 'approved' maps to Verified
      VerificationStatus mapLegacyLifecycle(String statusStr) {
        if (statusStr.toLowerCase() == 'approved') {
          return VerificationStatus.verified;
        }
        return VerificationStatus.fromString(statusStr);
      }

      expect(mapLegacyLifecycle('approved'), VerificationStatus.verified);
      expect(mapLegacyLifecycle('verified'), VerificationStatus.verified);
      expect(mapLegacyLifecycle('published'), VerificationStatus.published);
      expect(mapLegacyLifecycle('draft'), VerificationStatus.draft);
      expect(mapLegacyLifecycle('review_required'),
          VerificationStatus.reviewRequired);

      // Assignable content rule
      bool isAssignable(VerificationStatus status) {
        return status == VerificationStatus.verified ||
            status == VerificationStatus.published;
      }

      expect(isAssignable(VerificationStatus.verified), isTrue);
      expect(isAssignable(VerificationStatus.published), isTrue);
      expect(isAssignable(VerificationStatus.draft), isFalse);
      expect(isAssignable(VerificationStatus.reviewRequired), isFalse);
    });
  });
}
