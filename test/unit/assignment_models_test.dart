import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/features/teacher/domain/models/assignment_models.dart';

void main() {
  group('P9 Assignments & Interventions Models Test Suite', () {
    test('AssignmentType parses strings and provides correct labels', () {
      expect(AssignmentType.fromString('targetedPractice'),
          AssignmentType.targetedPractice);
      expect(AssignmentType.fromString('customQuestionSet'),
          AssignmentType.customQuestionSet);
      expect(
          AssignmentType.fromString('simulation'), AssignmentType.simulation);
      expect(AssignmentType.fromString('targeted_practice'),
          AssignmentType.targetedPractice);
      expect(AssignmentType.fromString('unknown_type'),
          AssignmentType.targetedPractice);
      expect(AssignmentType.fromString(null), AssignmentType.targetedPractice);

      expect(AssignmentType.targetedPractice.displayLabel, 'Targeted Practice');
      expect(AssignmentType.customQuestionSet.displayLabel,
          'Selected Question Set');
      expect(AssignmentType.simulation.displayLabel, 'ESSLCE Exam Simulation');
    });

    test('AssignmentStatus parses and checks states correctly', () {
      expect(AssignmentStatus.fromString('draft'), AssignmentStatus.draft);
      expect(
          AssignmentStatus.fromString('published'), AssignmentStatus.published);
      expect(AssignmentStatus.fromString('closed'), AssignmentStatus.closed);
      expect(
          AssignmentStatus.fromString('archived'), AssignmentStatus.archived);
      expect(AssignmentStatus.fromString(null), AssignmentStatus.draft);

      expect(AssignmentStatus.draft.displayLabel, 'Draft');
      expect(AssignmentStatus.published.displayLabel, 'Active');
      expect(AssignmentStatus.closed.displayLabel, 'Closed');
      expect(AssignmentStatus.archived.displayLabel, 'Archived');
    });

    test('AssignmentRecipientStatus parses and computes completion', () {
      expect(AssignmentRecipientStatus.fromString('assigned'),
          AssignmentRecipientStatus.assigned);
      expect(AssignmentRecipientStatus.fromString('inProgress'),
          AssignmentRecipientStatus.inProgress);
      expect(AssignmentRecipientStatus.fromString('submitted'),
          AssignmentRecipientStatus.submitted);
      expect(AssignmentRecipientStatus.fromString('completed'),
          AssignmentRecipientStatus.completed);
      expect(AssignmentRecipientStatus.fromString('late'),
          AssignmentRecipientStatus.late);
      expect(AssignmentRecipientStatus.fromString('excused'),
          AssignmentRecipientStatus.excused);
      expect(AssignmentRecipientStatus.fromString(null),
          AssignmentRecipientStatus.assigned);
    });

    test('Intervention enums parse and format correctly', () {
      expect(InterventionSource.fromString('p7Attention'),
          InterventionSource.p7Attention);
      expect(InterventionSource.fromString('teacherObservation'),
          InterventionSource.teacherObservation);
      expect(InterventionSource.fromString('assessmentReview'),
          InterventionSource.assessmentReview);
      expect(InterventionSource.fromString('mistakeReview'),
          InterventionSource.mistakeReview);

      expect(InterventionActionType.fromString('targetedPractice'),
          InterventionActionType.targetedPractice);
      expect(InterventionActionType.fromString('reviewMistakes'),
          InterventionActionType.reviewMistakes);
      expect(InterventionActionType.fromString('simulation'),
          InterventionActionType.simulation);
      expect(InterventionActionType.fromString('teacherFollowUp'),
          InterventionActionType.teacherFollowUp);

      expect(InterventionStatus.fromString('open'), InterventionStatus.open);
      expect(
          InterventionStatus.fromString('active'), InterventionStatus.active);
      expect(InterventionStatus.fromString('completed'),
          InterventionStatus.completed);
      expect(
          InterventionStatus.fromString('closed'), InterventionStatus.closed);
    });

    test('LearningAssignment JSON serialization and Math variant isolation',
        () {
      final now = DateTime.now().toUtc();
      final assignment = LearningAssignment(
        id: 'asgn-math-nat-001',
        schoolId: 'sch-001',
        classroomId: 'cls-12a',
        classroomName: '12-A Natural',
        teacherUserId: 'tch-001',
        subjectId: 'math_g12',
        title: 'Calculus & Vectors Deep Dive',
        instructions: 'Focus on 2014 exam questions',
        assignmentType: AssignmentType.targetedPractice,
        status: AssignmentStatus.published,
        dueAt: now.add(const Duration(days: 3)),
        allowLateSubmission: true,
        timeLimitMinutes: 45,
        totalQuestions: 15,
        contentHash: 'hash-abc-123',
        examVariant: 'naturalScience',
        createdAt: now,
        publishedAt: now,
      );

      final json = assignment.toJson();
      expect(json['id'], 'asgn-math-nat-001');
      expect(json['subject_id'], 'math_g12');
      expect(json['exam_variant'], 'naturalScience');
      expect(json['assignment_type'], 'targetedPractice');
      expect(json['status'], 'published');
      expect(json['total_questions'], 15);
      expect(json['allow_late_submission'], true);
      expect(json['time_limit_minutes'], 45);

      final revived = LearningAssignment.fromJson(json);
      expect(revived.id, assignment.id);
      expect(revived.subjectId, 'math_g12');
      expect(revived.examVariant, 'naturalScience');
      expect(revived.isPublished, isTrue);
      expect(revived.isClosed, isFalse);
      expect(revived.isMathNatural, isTrue);
      expect(revived.isMathSocial, isFalse);
    });

    test('LearningAssignment correctly identifies Social Math variant', () {
      final assignment = LearningAssignment(
        id: 'asgn-math-soc-001',
        schoolId: 'sch-001',
        classroomId: 'cls-12c',
        teacherUserId: 'tch-002',
        subjectId: 'math_g12',
        title: 'Business Calculus',
        assignmentType: AssignmentType.targetedPractice,
        status: AssignmentStatus.draft,
        totalQuestions: 10,
        examVariant: 'socialScience',
        createdAt: DateTime.now(),
      );

      expect(assignment.isMathNatural, isFalse);
      expect(assignment.isMathSocial, isTrue);
      expect(assignment.isDraft, isTrue);
    });

    test('AssignmentRecipient JSON roundtrip and score calculations', () {
      final now = DateTime.now().toUtc();
      final recipient = AssignmentRecipient(
        id: 'rcp-001',
        assignmentId: 'asgn-001',
        studentUserId: 'std-001',
        studentName: 'Abebe Bikila',
        schoolStudentId: 'R-101',
        status: AssignmentRecipientStatus.submitted,
        assignedAt: now.subtract(const Duration(days: 2)),
        submittedAt: now,
        score: 18,
        percentage: 90.0,
        attemptId: 'att-999',
      );

      final json = recipient.toJson();
      expect(json['student_user_id'], 'std-001');
      expect(json['status'], 'submitted');
      expect(json['score'], 18);
      expect(json['percentage'], 90.0);

      final revived = AssignmentRecipient.fromJson(json);
      expect(revived.studentName, 'Abebe Bikila');
      expect(revived.isCompleted, isTrue);
      expect(revived.percentage, 90.0);
    });

    test('AssignmentProgressSummary calculates completion rates accurately',
        () {
      final now = DateTime.now().toUtc();
      final assignment = LearningAssignment(
        id: 'asgn-001',
        schoolId: 'sch-001',
        classroomId: 'cls-1',
        teacherUserId: 'tch-001',
        subjectId: 'physics_g12',
        title: 'Kinematics Drill',
        assignmentType: AssignmentType.targetedPractice,
        status: AssignmentStatus.published,
        totalQuestions: 20,
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      );

      final summary = AssignmentProgressSummary(
        assignment: assignment,
        recipients: const [],
        totalAssigned: 50,
        notStartedCount: 10,
        inProgressCount: 5,
        submittedCount: 35,
        lateCount: 0,
        excusedCount: 0,
        lastSyncedAt: now,
      );

      expect(summary.totalAssigned, 50);
      expect(summary.submittedCount, 35);
      expect(summary.completionRate, 70.0);
      expect(summary.pendingCount, 15);
      expect(summary.overdueCount, 15);
    });

    test('StudentAssignment deadline rules and overdue detection', () {
      final now = DateTime.now().toUtc();

      // Case 1: Active with 2 days remaining
      final active = StudentAssignment(
        assignmentId: 'asgn-1',
        recipientId: 'rcp-1',
        schoolId: 'sch-1',
        classroomId: 'cls-1',
        classroomName: '12-A',
        teacherName: 'Ato Kebede',
        subjectId: 'chemistry_g12',
        title: 'Atomic Models',
        assignmentType: AssignmentType.targetedPractice,
        assignmentStatus: AssignmentStatus.published,
        studentStatus: AssignmentRecipientStatus.assigned,
        totalQuestions: 12,
        timeLimitMinutes: 30,
        dueAt: now.add(const Duration(days: 2)),
        allowLateSubmission: false,
      );

      expect(active.isCompleted, isFalse);
      expect(active.isOverdue, isFalse);
      expect(active.isPastDueWithGrace, isFalse);
      expect(active.canStartOrResume, isTrue);

      // Case 2: Past due, but late submission allowed
      final inGrace = StudentAssignment(
        assignmentId: 'asgn-2',
        recipientId: 'rcp-2',
        schoolId: 'sch-1',
        classroomId: 'cls-1',
        classroomName: '12-A',
        teacherName: 'Dr. Hailu',
        subjectId: 'physics_g12',
        title: 'Wave Optics',
        assignmentType: AssignmentType.targetedPractice,
        assignmentStatus: AssignmentStatus.published,
        studentStatus: AssignmentRecipientStatus.assigned,
        totalQuestions: 20,
        dueAt: now.subtract(const Duration(minutes: 30)),
        allowLateSubmission: true,
      );

      expect(inGrace.isOverdue, isTrue);
      expect(inGrace.isPastDueWithGrace, isTrue);
      expect(inGrace.isLockedDueToPastGrace, isFalse);
      expect(inGrace.canStartOrResume, isTrue);

      // Case 3: Past due and late submission disallowed (locked)
      final locked = StudentAssignment(
        assignmentId: 'asgn-3',
        recipientId: 'rcp-3',
        schoolId: 'sch-1',
        classroomId: 'cls-1',
        classroomName: '12-A',
        teacherName: 'W/ro Almaz',
        subjectId: 'biology_g12',
        title: 'Genetics Review',
        assignmentType: AssignmentType.customQuestionSet,
        assignmentStatus: AssignmentStatus.published,
        studentStatus: AssignmentRecipientStatus.assigned,
        totalQuestions: 25,
        dueAt: now.subtract(const Duration(hours: 5)),
        allowLateSubmission: false,
      );

      expect(locked.isOverdue, isTrue);
      expect(locked.isLockedDueToPastGrace, isTrue);
      expect(locked.canStartOrResume, isFalse);
    });

    test('StudentIntervention captures reason code snapshot and lifecycle', () {
      final now = DateTime.now().toUtc();
      final intervention = StudentIntervention(
        id: 'itv-001',
        schoolId: 'sch-001',
        teacherUserId: 'tch-001',
        studentUserId: 'std-001',
        classroomId: 'cls-12a',
        classroomName: '12-A Natural',
        subjectId: 'math_g12',
        examVariant: 'naturalScience',
        source: InterventionSource.p7Attention,
        sourceReasonCodes: const ['lowRecentAccuracy', 'highMistakeCount'],
        severityAtCreation: 'high',
        actionType: InterventionActionType.targetedPractice,
        linkedAssignmentId: 'asgn-math-nat-001',
        linkedAssignmentTitle: 'Grade 12 Calculus remedial drill',
        status: InterventionStatus.active,
        teacherNote: 'Assign Grade 12 Calculus remedial drill',
        createdAt: now,
        studentName: 'Chala Tadesse',
      );

      final json = intervention.toJson();
      expect(json['id'], 'itv-001');
      expect(json['severity_at_creation'], 'high');
      expect(json['source_reason_codes'], contains('lowRecentAccuracy'));
      expect(json['action_type'], 'targetedPractice');
      expect(json['linked_assignment_id'], 'asgn-math-nat-001');
      expect(json['status'], 'active');

      final revived = StudentIntervention.fromJson(json);
      expect(revived.studentName, 'Chala Tadesse');
      expect(revived.severityAtCreation, 'high');
      expect(revived.sourceReasonCodes.length, 2);
      expect(revived.isCompleted, isFalse);
    });
  });
}
