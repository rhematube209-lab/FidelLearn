import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/features/school/data/repositories/supabase_school_repository.dart';
import 'package:fidel_learn/features/school/data/repositories/supabase_classroom_repository.dart';

void main() {
  group('P6 Stage 2 Supabase Repositories Contract & Resilience Tests', () {
    test('SupabaseSchoolRepository handles unauthenticated/null client safely',
        () async {
      final repo = SupabaseSchoolRepository(client: null);

      final mySchools = await repo.getMySchools();
      expect(mySchools, isEmpty);

      final school = await repo.getSchool('');
      expect(school, isNull);

      final membership = await repo.getMyMembership('');
      expect(membership, isNull);

      final active = await repo.getActiveMembership();
      expect(active, isNull);

      final lookup = await repo.lookupSchoolByCode('');
      expect(lookup, isNull);
    });

    test(
        'SupabaseClassroomRepository handles unauthenticated/null client safely',
        () async {
      final repo = SupabaseClassroomRepository(client: null);

      final myClassrooms = await repo.getMyClassrooms();
      expect(myClassrooms, isEmpty);

      final classroom = await repo.getClassroom('');
      expect(classroom, isNull);

      final memberships = await repo.getMyClassroomMemberships();
      expect(memberships, isEmpty);

      final teacherAssignments = await repo.getMyTeacherAssignments();
      expect(teacherAssignments, isEmpty);

      final classroomAssignments = await repo.getAssignmentsForClassroom('');
      expect(classroomAssignments, isEmpty);
    });
  });
}
