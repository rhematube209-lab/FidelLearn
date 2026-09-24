import '../../../subjects/domain/models/subject_models.dart';
import '../../domain/models/mastery_models.dart';
import '../../domain/repositories/mastery_repository.dart';

/// In-memory implementation of [MasteryRepository] for unit tests and offline mock fallback.
class LocalMasteryRepository implements MasteryRepository {
  final Map<String, QuestionMasteryRecord> _questionMastery = {};
  final Map<String, LearningTargetMasteryRecord> _targetMastery = {};
  final List<ReviewEventRecord> _reviewEvents = [];

  @override
  Future<QuestionMasteryRecord?> getQuestionMastery(
    String userId,
    String questionId,
  ) async {
    return _questionMastery['${userId}_$questionId'];
  }

  @override
  Future<List<QuestionMasteryRecord>> getQuestionMasteryList(
    String userId, {
    String? subjectId,
    ExamVariantCode? examVariant,
  }) async {
    return _questionMastery.values.where((r) {
      if (r.userId != userId) return false;
      if (subjectId != null && r.subjectId != subjectId) return false;
      if (examVariant != null && r.examVariant != examVariant) return false;
      return true;
    }).toList();
  }

  @override
  Future<void> saveQuestionMastery(QuestionMasteryRecord record) async {
    _questionMastery[record.id] = record;
  }

  @override
  Future<void> saveQuestionMasteryBatch(
      List<QuestionMasteryRecord> records) async {
    for (final r in records) {
      _questionMastery[r.id] = r;
    }
  }

  @override
  Future<LearningTargetMasteryRecord?> getTargetMastery(
    String userId,
    String targetKey,
  ) async {
    return _targetMastery['${userId}_$targetKey'];
  }

  @override
  Future<List<LearningTargetMasteryRecord>> getTargetMasteryList(
    String userId, {
    String? subjectId,
    ExamVariantCode? examVariant,
  }) async {
    return _targetMastery.values.where((r) {
      if (r.userId != userId) return false;
      if (subjectId != null && r.subjectId != subjectId) return false;
      if (examVariant != null && r.examVariant != examVariant) return false;
      return true;
    }).toList();
  }

  @override
  Future<void> saveTargetMastery(LearningTargetMasteryRecord record) async {
    _targetMastery[record.id] = record;
  }

  @override
  Future<void> saveTargetMasteryBatch(
      List<LearningTargetMasteryRecord> records) async {
    for (final r in records) {
      _targetMastery[r.id] = r;
    }
  }

  @override
  Future<List<QuestionMasteryRecord>> getDueQuestionReviews(
    String userId, {
    DateTime? asOf,
    int? limit,
  }) async {
    final effectiveDate = asOf ?? DateTime.now();

    final due = _questionMastery.values.where((r) {
      if (r.userId != userId) return false;
      if (r.nextReviewAt == null) return false;
      return r.nextReviewAt!.isBefore(effectiveDate) ||
          r.nextReviewAt!.isAtSameMomentAs(effectiveDate);
    }).toList()
      ..sort((a, b) => (a.nextReviewAt ?? DateTime.now())
          .compareTo(b.nextReviewAt ?? DateTime.now()));

    if (limit != null && limit > 0) {
      return due.take(limit).toList();
    }
    return due;
  }

  @override
  Future<List<LearningTargetMasteryRecord>> getDueTargetReviews(
    String userId, {
    DateTime? asOf,
    int? limit,
  }) async {
    final effectiveDate = asOf ?? DateTime.now();

    final due = _targetMastery.values.where((r) {
      if (r.userId != userId) return false;
      if (r.nextReviewAt == null) return false;
      return r.nextReviewAt!.isBefore(effectiveDate) ||
          r.nextReviewAt!.isAtSameMomentAs(effectiveDate);
    }).toList()
      ..sort((a, b) => (a.nextReviewAt ?? DateTime.now())
          .compareTo(b.nextReviewAt ?? DateTime.now()));

    if (limit != null && limit > 0) {
      return due.take(limit).toList();
    }
    return due;
  }

  @override
  Future<void> recordReviewEvent(ReviewEventRecord event) async {
    _reviewEvents.add(event);
  }

  @override
  Future<List<ReviewEventRecord>> getReviewEvents(
    String userId, {
    String? targetKey,
    int? limit,
  }) async {
    final events = _reviewEvents.where((e) {
      if (e.userId != userId) return false;
      if (targetKey != null && e.targetKey != targetKey) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.reviewedAt.compareTo(a.reviewedAt));

    if (limit != null && limit > 0) {
      return events.take(limit).toList();
    }
    return events;
  }

  void clear() {
    _questionMastery.clear();
    _targetMastery.clear();
    _reviewEvents.clear();
  }
}
