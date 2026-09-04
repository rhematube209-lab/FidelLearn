import 'package:fidel_learn/features/question_bank/domain/models/question_models.dart';
import '../../domain/models/admin_models.dart';
import '../../domain/repositories/admin_repository.dart';

class LocalAdminRepository implements AdminRepository {
  final List<ContentAuditLog> _auditLogs = [];
  final List<Question> _pendingQuestions = [];

  LocalAdminRepository() {
    _seedData();
  }

  void _seedData() {
    final now = DateTime.now();

    _auditLogs.addAll([
      ContentAuditLog(
        id: 'aud_1',
        actorUserId: 'admin_root',
        actorRole: 'platform_admin',
        actionType: 'PUBLISH_PACKAGE',
        targetEntityType: 'package',
        targetEntityId: 'pkg_g12_math',
        detail:
            'Approved and published Grade 12 Mathematics Official Package v1.0.0',
        timestamp: now.subtract(const Duration(hours: 4)),
      ),
      ContentAuditLog(
        id: 'aud_2',
        actorUserId: 'editor_1',
        actorRole: 'content_editor',
        actionType: 'VERIFY_QUESTION',
        targetEntityType: 'question',
        targetEntityId: 'q_math_seq_1',
        detail:
            'Verified question text, LaTeX notation, and step-by-step rationale',
        timestamp: now.subtract(const Duration(hours: 2)),
      ),
    ]);

    _pendingQuestions.add(
      const Question(
        id: 'q_draft_calc_1',
        subjectId: 'math_g12',
        unitId: 'unit_calc',
        topicId: 'math_integrals',
        grade: 12,
        stream: 'natural',
        difficulty: 'medium',
        questionTextEn:
            r'Evaluate the definite integral: \int_{0}^{2} (3x^2 - 2x + 1) \, dx',
        questionTextAm:
            r'የሚከተለውን ኢንቴግራሊ አስላ: \int_{0}^{2} (3x^2 - 2x + 1) \, dx',
        verificationStatus: VerificationStatus.reviewRequired,
        sourceName: 'FidelLearn Model Exam Prep 2026',
        contentVersion: 1,
        choices: [
          AnswerChoice(
            id: 'c1',
            label: 'A',
            textEn: '6',
            textAm: '6',
            isCorrect: true,
          ),
          AnswerChoice(
            id: 'c2',
            label: 'B',
            textEn: '8',
            textAm: '8',
            isCorrect: false,
          ),
          AnswerChoice(
            id: 'c3',
            label: 'C',
            textEn: '4',
            textAm: '4',
            isCorrect: false,
          ),
          AnswerChoice(
            id: 'c4',
            label: 'D',
            textEn: '10',
            textAm: '10',
            isCorrect: false,
          ),
        ],
        explanation: Explanation(
          solutionTextEn:
              r'Step 1: Find the antiderivative: F(x) = x^3 - x^2 + x.'
              '\n'
              r'Step 2: F(2) = 2^3 - 2^2 + 2 = 8 - 4 + 2 = 6.'
              '\n'
              r'Step 3: F(0) = 0. Result = 6 - 0 = 6.',
          solutionTextAm: r'ደረጃ 1: አንቲዴሪቬቲቩን ፈልግ: F(x) = x^3 - x^2 + x.'
              '\n'
              r'ደረጃ 2: F(2) = 8 - 4 + 2 = 6.'
              '\n'
              r'ደረጃ 3: F(0) = 0. ውጤት = 6.',
          simplerExplanationEn:
              'Integrate term by term, then plug in the bounds.',
          keyConcept: 'Fundamental Theorem of Calculus Part 2',
          commonPitfall: 'Forgetting that integral of x is x^2 / 2.',
        ),
      ),
    );
  }

  @override
  Future<AdminContentOverview> getContentOverview() async {
    return AdminContentOverview(
      totalQuestions: 21,
      publishedQuestions: 20,
      pendingVerificationQuestions: _pendingQuestions.length,
      draftQuestions: 2,
      totalPackages: 2,
    );
  }

  @override
  Future<List<Question>> getPendingReviewQuestions() async {
    return List.unmodifiable(_pendingQuestions);
  }

  @override
  Future<List<ContentAuditLog>> getAuditLogs({int limit = 50}) async {
    return _auditLogs.take(limit).toList();
  }

  @override
  Future<void> updateVerificationStatus({
    required String questionId,
    required String status,
    required String actorUserId,
    required String actorRole,
    String? rejectionReason,
  }) async {
    _pendingQuestions.removeWhere((q) => q.id == questionId);

    _auditLogs.insert(
      0,
      ContentAuditLog(
        id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
        actorUserId: actorUserId,
        actorRole: actorRole,
        actionType: 'STATUS_CHANGE_$status'.toUpperCase(),
        targetEntityType: 'question',
        targetEntityId: questionId,
        detail: rejectionReason != null
            ? 'Status changed to $status. Reason: $rejectionReason'
            : 'Status successfully updated to $status.',
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> saveQuestion({
    required Question question,
    required String actorUserId,
    required String actorRole,
  }) async {
    _pendingQuestions.removeWhere((q) => q.id == question.id);
    _pendingQuestions.insert(0, question);

    _auditLogs.insert(
      0,
      ContentAuditLog(
        id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
        actorUserId: actorUserId,
        actorRole: actorRole,
        actionType: 'SAVE_QUESTION',
        targetEntityType: 'question',
        targetEntityId: question.id,
        detail:
            'Created/Updated question "${question.questionTextEn.substring(0, question.questionTextEn.length.clamp(0, 40))}..."',
        timestamp: DateTime.now(),
      ),
    );
  }
}
