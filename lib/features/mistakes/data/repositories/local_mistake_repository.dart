import '../../domain/models/mistake_model.dart';
import '../../domain/repositories/mistake_repository.dart';

class LocalMistakeRepository implements MistakeRepository {
  final Map<String, MistakeRecord> _mistakes = {}; // Key: "userId_questionId"

  @override
  Future<void> recordMistake({
    required String userId,
    required String questionId,
    required String subjectId,
  }) async {
    final key = '${userId}_$questionId';
    final existing = _mistakes[key];

    if (existing != null) {
      _mistakes[key] = existing.copyWith(
        mistakeCount: existing.mistakeCount + 1,
        isMastered: false,
        lastFailedAt: DateTime.now(),
      );
    } else {
      _mistakes[key] = MistakeRecord(
        id: 'mst_$key',
        userId: userId,
        questionId: questionId,
        subjectId: subjectId,
        mistakeCount: 1,
        isMastered: false,
        lastFailedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> markMastered({
    required String userId,
    required String questionId,
  }) async {
    final key = '${userId}_$questionId';
    final existing = _mistakes[key];
    if (existing != null) {
      _mistakes[key] = existing.copyWith(
        isMastered: true,
        masteredAt: DateTime.now(),
      );
    }
  }

  @override
  Future<List<MistakeRecord>> getMistakes(
    String userId, {
    String? subjectId,
    bool onlyUnmastered = true,
  }) async {
    return _mistakes.values.where((m) {
      if (m.userId != userId) return false;
      if (onlyUnmastered && m.isMastered) return false;
      if (subjectId != null && m.subjectId != subjectId) return false;
      return true;
    }).toList()..sort((a, b) => b.lastFailedAt.compareTo(a.lastFailedAt));
  }
}
