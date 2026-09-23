import '../models/subject_models.dart';
import '../services/delta_package_service.dart';
import '../../../question_bank/domain/models/question_models.dart';
import '../../../exams/domain/models/exam_availability.dart';

abstract class ContentRepository {
  Future<void> initializeSeedData();
  Future<List<Subject>> getSubjects({
    int? grade,
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
  Future<PackageDelta?> checkPackageUpdate(String packageId);
  Future<void> applyDeltaUpdate(String packageId, PackageDelta delta);
  Future<List<Question>> getQuestions({
    int? grade,
    required String subjectId,
    String? unitId,
    String? topicId,
    String? difficulty,
    int? examYear,
    int? startYear,
    int? endYear,
    List<int>? examYears,
    int? limit,
    bool practiceEligibleOnly = false,
    String? stream,
    ExamVariantCode? examVariant,
  });
  Future<Question?> getQuestionById(String id);
  Future<List<int>> getAvailableExamYears(String subjectId);
  Future<List<ExamAvailability>> getExamAvailabilities(String subjectId);
  Future<Map<String, int>> getUnitQuestionCounts({
    required String subjectId,
    int? examYear,
    int? grade,
  });
}
