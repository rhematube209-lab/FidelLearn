import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/features/admin/data/repositories/local_admin_repository.dart';
import 'package:fidel_learn/features/question_bank/domain/models/question_models.dart';

void main() {
  group('AdminRepository & CMS Verification Tests', () {
    late LocalAdminRepository repository;

    setUp(() {
      repository = LocalAdminRepository();
    });

    test('retrieves content overview and audit logs', () async {
      final overview = await repository.getContentOverview();
      expect(overview.totalQuestions, greaterThan(0));
      expect(overview.publishedQuestions, greaterThan(0));

      final logs = await repository.getAuditLogs();
      expect(logs.isNotEmpty, isTrue);
      expect(logs.first.actorRole, isNotNull);
    });

    test('saves authored question in review state and logs audit trail', () async {
      const question = Question(
        id: 'q_test_author',
        subjectId: 'math_g12',
        unitId: 'unit_1',
        topicId: 'topic_1',
        grade: 12,
        stream: 'natural',
        difficulty: 'medium',
        questionTextEn: 'Test derivative problem',
        questionTextAm: 'የሙከራ ጥያቄ',
        verificationStatus: VerificationStatus.reviewRequired,
        sourceName: 'FidelLearn Model Exam Prep 2026',
        contentVersion: 1,
        choices: [
          AnswerChoice(
            id: 'c1',
            label: 'A',
            textEn: 'Choice A',
            isCorrect: true,
          ),
        ],
        explanation: Explanation(
          solutionTextEn: 'Step 1: Test solution',
        ),
      );

      await repository.saveQuestion(
        question: question,
        actorUserId: 'editor_1',
        actorRole: 'content_editor',
      );

      final pending = await repository.getPendingReviewQuestions();
      expect(pending.any((q) => q.id == 'q_test_author'), isTrue);

      final logs = await repository.getAuditLogs();
      expect(logs.first.actionType, 'SAVE_QUESTION');
      expect(logs.first.targetEntityId, 'q_test_author');
    });

    test('approves question and records status change in immutable audit log', () async {
      await repository.updateVerificationStatus(
        questionId: 'q_draft_calc_1',
        status: 'published',
        actorUserId: 'admin_root',
        actorRole: 'platform_admin',
      );

      final pending = await repository.getPendingReviewQuestions();
      expect(pending.any((q) => q.id == 'q_draft_calc_1'), isFalse);

      final logs = await repository.getAuditLogs();
      expect(logs.first.actionType, 'STATUS_CHANGE_PUBLISHED');
      expect(logs.first.targetEntityId, 'q_draft_calc_1');
    });

    test('rejects question with reason and logs audit detail', () async {
      await repository.updateVerificationStatus(
        questionId: 'q_draft_calc_1',
        status: 'rejected',
        actorUserId: 'admin_root',
        actorRole: 'platform_admin',
        rejectionReason: 'Invalid LaTeX formatting in choice B',
      );

      final logs = await repository.getAuditLogs();
      expect(logs.first.actionType, 'STATUS_CHANGE_REJECTED');
      expect(logs.first.detail, contains('Invalid LaTeX formatting'));
    });
  });
}
