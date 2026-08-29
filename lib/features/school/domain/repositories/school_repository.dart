import '../models/school_models.dart';

abstract class SchoolRepository {
  Future<SchoolProfile> getSchoolProfile(String schoolId);
  Future<List<RosterTeacher>> getTeacherRoster(String schoolId);
  Future<SchoolAnalyticsSummary> getSchoolAnalytics(String schoolId);
}
