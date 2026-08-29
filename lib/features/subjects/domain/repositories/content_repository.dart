import '../models/subject_models.dart';
import '../../../question_bank/domain/models/question_models.dart';

abstract class ContentRepository {
  Future<void> initializeSeedData();
  Future<List<Subject>> getSubjects({
    required int grade,
    required String stream,
  });
  Future<List<Unit>> getUnits(String subjectId);
  Future<List<Topic>> getTopics(String unitId);
  Future<List<ContentPackage>> getPackages({
    required int grade,
    required String stream,
  });
  Future<void> downloadPackage(String packageId);
  Future<void> removePackage(String packageId);
  Future<List<Question>> getQuestions({
    required int grade,
    required String subjectId,
    String? unitId,
    String? topicId,
    String? difficulty,
    int? examYear,
    int? limit,
  });
  Future<Question?> getQuestionById(String id);
}
