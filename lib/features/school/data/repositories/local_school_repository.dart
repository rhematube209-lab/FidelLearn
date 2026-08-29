import '../../domain/models/school_models.dart';
import '../../domain/repositories/school_repository.dart';

class LocalSchoolRepository implements SchoolRepository {
  @override
  Future<SchoolProfile> getSchoolProfile(String schoolId) async {
    return const SchoolProfile(
      id: 'sch_bole_1',
      name: 'Bole Senior Secondary School',
      region: 'Addis Ababa',
      totalStudents: 420,
      totalTeachers: 18,
      naturalStreamStudents: 240,
      socialStreamStudents: 180,
    );
  }

  @override
  Future<List<RosterTeacher>> getTeacherRoster(String schoolId) async {
    return const [
      RosterTeacher(
        id: 't_1',
        name: 'Ato Solomon Mengistu',
        subject: 'Mathematics',
        classroomCount: 3,
        studentCount: 135,
        averageClassAccuracy: 74.8,
      ),
      RosterTeacher(
        id: 't_2',
        name: 'W/ro Tigist Hailu',
        subject: 'Scholastic Aptitude',
        classroomCount: 4,
        studentCount: 170,
        averageClassAccuracy: 81.2,
      ),
      RosterTeacher(
        id: 't_3',
        name: 'Ato Dawit Kebede',
        subject: 'Physics',
        classroomCount: 2,
        studentCount: 90,
        averageClassAccuracy: 62.4,
      ),
    ];
  }

  @override
  Future<SchoolAnalyticsSummary> getSchoolAnalytics(String schoolId) async {
    return const SchoolAnalyticsSummary(
      overallReadinessScore: 73.5,
      naturalStreamReadiness: 76.2,
      socialStreamReadiness: 69.8,
      topPerformingSubject: 'Scholastic Aptitude',
      priorityWeakSubject: 'Physics',
      totalMockExamsCompleted: 1240,
    );
  }
}
