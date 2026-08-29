import '../models/mistake_model.dart';

abstract class MistakeRepository {
  Future<void> recordMistake({
    required String userId,
    required String questionId,
    required String subjectId,
  });
  Future<void> markMastered({
    required String userId,
    required String questionId,
  });
  Future<List<MistakeRecord>> getMistakes(
    String userId, {
    String? subjectId,
    bool onlyUnmastered = true,
  });
}
