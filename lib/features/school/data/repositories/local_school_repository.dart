import '../../domain/models/school_models.dart';
import '../../domain/models/tenant_models.dart';
import '../../domain/repositories/school_repository.dart';
import '../../../auth/domain/models/user_profile.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/security/auth_session_storage.dart';

/// Test and preview mock implementation of SchoolRepository.
/// Correctly honors schoolId parameters to prevent test bugs.
class LocalSchoolRepository implements SchoolRepository {
  final List<School> _schools = [];
  final List<SchoolMembership> _memberships = [];
  final AuthSessionStorage? _sessionStorage;
  final UserProfile? _currentUser;
  final bool _hasCustomMemberships;

  LocalSchoolRepository({
    List<School>? initialSchools,
    List<SchoolMembership>? initialMemberships,
    AuthSessionStorage? sessionStorage,
    UserProfile? currentUser,
  })  : _sessionStorage = sessionStorage,
        _currentUser = currentUser,
        _hasCustomMemberships = initialMemberships != null {
    if (initialSchools != null) {
      _schools.addAll(initialSchools);
    } else {
      _seedDefaultSchools();
    }

    if (initialMemberships != null) {
      _memberships.addAll(initialMemberships);
    } else {
      _seedDefaultMemberships();
    }
  }

  void _seedDefaultSchools() {
    final now = DateTime.now();
    _schools.addAll([
      School(
        id: '11111111-1111-1111-1111-111111111111',
        name: 'Bole Senior Secondary School',
        displayName: 'Bole Secondary',
        schoolCode: 'FID-BOL001',
        status: SchoolStatus.active,
        city: 'Addis Ababa',
        region: 'Addis Ababa',
        createdAt: now,
        updatedAt: now,
      ),
      School(
        id: '22222222-2222-2222-2222-222222222222',
        name: 'Hawassa Comprehensive Secondary School',
        displayName: 'Hawassa Secondary',
        schoolCode: 'FID-HAW002',
        status: SchoolStatus.active,
        city: 'Hawassa',
        region: 'Sidama',
        createdAt: now,
        updatedAt: now,
      ),
    ]);
  }

  void _seedDefaultMemberships() {
    final now = DateTime.now();
    _memberships.addAll([
      SchoolMembership(
        id: 'sm-test-1',
        schoolId: '11111111-1111-1111-1111-111111111111',
        userId: 'u-student-1',
        role: SchoolMemberRole.student,
        status: SchoolMembershipStatus.active,
        schoolStudentId: 'STU-BOL-101',
        createdAt: now,
        updatedAt: now,
      ),
      SchoolMembership(
        id: 'sm-student-global',
        schoolId: '11111111-1111-1111-1111-111111111111',
        userId: '00000000-0000-0000-0000-000000000001',
        role: SchoolMemberRole.student,
        status: SchoolMembershipStatus.active,
        schoolStudentId: 'STU-BOL-102',
        createdAt: now,
        updatedAt: now,
      ),
      SchoolMembership(
        id: 'sm-student-tamerat',
        schoolId: '11111111-1111-1111-1111-111111111111',
        userId: '00000000-0000-0000-0000-000000000009',
        role: SchoolMemberRole.student,
        status: SchoolMembershipStatus.active,
        schoolStudentId: 'STU-BOL-103',
        createdAt: now,
        updatedAt: now,
      ),
      SchoolMembership(
        id: 'sm-admin-tenant',
        schoolId: '11111111-1111-1111-1111-111111111111',
        userId: 'usr_school_admin',
        role: SchoolMemberRole.schoolAdmin,
        status: SchoolMembershipStatus.active,
        schoolStudentId: 'DIR-BOL-001',
        createdAt: now,
        updatedAt: now,
      ),
      SchoolMembership(
        id: 'sm-admin-global',
        schoolId: '11111111-1111-1111-1111-111111111111',
        userId: '00000000-0000-0000-0000-000000000004',
        role: SchoolMemberRole.schoolAdmin,
        status: SchoolMembershipStatus.active,
        schoolStudentId: 'DIR-BOL-002',
        createdAt: now,
        updatedAt: now,
      ),
      SchoolMembership(
        id: 'sm-teacher-tenant',
        schoolId: '11111111-1111-1111-1111-111111111111',
        userId: 'usr_teacher',
        role: SchoolMemberRole.teacher,
        status: SchoolMembershipStatus.active,
        schoolStudentId: 'TCH-BOL-001',
        createdAt: now,
        updatedAt: now,
      ),
      SchoolMembership(
        id: 'sm-teacher-global',
        schoolId: '11111111-1111-1111-1111-111111111111',
        userId: '00000000-0000-0000-0000-000000000002',
        role: SchoolMemberRole.teacher,
        status: SchoolMembershipStatus.active,
        schoolStudentId: 'TCH-BOL-002',
        createdAt: now,
        updatedAt: now,
      ),
    ]);
  }

  @override
  Future<List<SchoolMembershipWithSchool>> getMySchools() async {
    List<SchoolMembership> targetMemberships = _memberships;

    if (!_hasCustomMemberships) {
      final activeUser =
          _currentUser ?? await _sessionStorage?.getRememberedUser();
      if (activeUser != null) {
        final matches = _memberships.where((m) {
          if (m.userId == activeUser.id) return true;
          if (activeUser.role == UserRole.schoolAdmin &&
              m.role == SchoolMemberRole.schoolAdmin) {
            return true;
          }
          if (activeUser.role == UserRole.teacher &&
              m.role == SchoolMemberRole.teacher) {
            return true;
          }
          return false;
        }).toList();

        if (matches.isNotEmpty) {
          targetMemberships = matches;
        } else if (activeUser.role == UserRole.schoolAdmin) {
          targetMemberships = [
            SchoolMembership(
              id: 'sm-admin-fallback',
              schoolId: '11111111-1111-1111-1111-111111111111',
              userId: activeUser.id,
              role: SchoolMemberRole.schoolAdmin,
              status: SchoolMembershipStatus.active,
              schoolStudentId: 'DIR-BOL-001',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ];
        } else if (activeUser.role == UserRole.teacher) {
          targetMemberships = [
            SchoolMembership(
              id: 'sm-teacher-fallback',
              schoolId: '11111111-1111-1111-1111-111111111111',
              userId: activeUser.id,
              role: SchoolMemberRole.teacher,
              status: SchoolMembershipStatus.active,
              schoolStudentId: 'TCH-BOL-001',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ];
        }
      }
    }

    final list = <SchoolMembershipWithSchool>[];
    for (final sm in targetMemberships) {
      final school = _schools.cast<School?>().firstWhere(
            (s) => s?.id == sm.schoolId,
            orElse: () => null,
          );
      if (school != null) {
        list.add(SchoolMembershipWithSchool(membership: sm, school: school));
      }
    }
    return list;
  }

  @override
  Future<School?> getSchool(String schoolId) async {
    return _schools.cast<School?>().firstWhere(
          (s) => s?.id == schoolId,
          orElse: () => null,
        );
  }

  @override
  Future<SchoolMembership?> getMyMembership(String schoolId) async {
    final list = await getMySchools();
    return list.cast<SchoolMembershipWithSchool?>().firstWhere(
      (m) => m?.school.id == schoolId,
      orElse: () => null,
    )?.membership;
  }

  @override
  Future<SchoolMembership?> getActiveMembership() async {
    final list = await getMySchools();
    return list.cast<SchoolMembershipWithSchool?>().firstWhere(
      (m) => m?.membership.isActive == true,
      orElse: () => null,
    )?.membership;
  }

  @override
  Future<School?> lookupSchoolByCode(String schoolCode) async {
    final normalized = schoolCode.trim().toUpperCase();
    return _schools.cast<School?>().firstWhere(
          (s) => s?.schoolCode.toUpperCase() == normalized,
          orElse: () => null,
        );
  }

  @override
  Future<SchoolMembership> redeemInvitation(
      {required String inviteCode}) async {
    if (inviteCode.trim() == 'EXPIRED') {
      throw const InvitationExpiredFailure();
    }
    if (inviteCode.trim() == 'INVALID') {
      throw const InvitationInvalidFailure();
    }
    final membership = SchoolMembership(
      id: 'sm-redeemed-${DateTime.now().millisecondsSinceEpoch}',
      schoolId: _schools.isNotEmpty
          ? _schools.first.id
          : '11111111-1111-1111-1111-111111111111',
      userId: 'u-redeemed-user',
      role: SchoolMemberRole.student,
      status: SchoolMembershipStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _memberships.add(membership);
    return membership;
  }

  @override
  Future<void> requestJoinSchool({
    required String schoolCode,
    String? studentIdNumber,
  }) async {
    final school = await lookupSchoolByCode(schoolCode);
    if (school == null) {
      throw SchoolNotFoundFailure(schoolCode);
    }
  }

  // ===========================================================================
  // Preview / Legacy operations (Honoring schoolId correctly!)
  // ===========================================================================

  @override
  Future<SchoolProfile> getSchoolProfile(String schoolId) async {
    final school = await getSchool(schoolId);
    return SchoolProfile(
      id: school?.id ?? schoolId,
      name: school?.displayName ?? school?.name ?? 'School Profile ($schoolId)',
      region: school?.region ?? 'Addis Ababa',
      totalStudents: 420,
      totalTeachers: 18,
      naturalStreamStudents: 240,
      socialStreamStudents: 180,
    );
  }

  @override
  Future<List<RosterTeacher>> getTeacherRoster(String schoolId) async {
    return [
      RosterTeacher(
        id: 't_1_$schoolId',
        name: 'Ato Solomon Mengistu',
        subject: 'Mathematics',
        classroomCount: 3,
        studentCount: 135,
        averageClassAccuracy: 74.8,
      ),
      RosterTeacher(
        id: 't_2_$schoolId',
        name: 'W/ro Tigist Hailu',
        subject: 'Scholastic Aptitude',
        classroomCount: 4,
        studentCount: 170,
        averageClassAccuracy: 81.2,
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
