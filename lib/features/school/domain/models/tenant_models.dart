import 'package:equatable/equatable.dart';
import '../../../subjects/domain/models/subject_models.dart';

// =============================================================================
// School Tenancy Enums
// =============================================================================

enum SchoolStatus {
  active,
  suspended,
  archived,
  unknown;

  static SchoolStatus fromString(String? val) {
    if (val == null) return SchoolStatus.unknown;
    switch (val.toLowerCase().trim()) {
      case 'active':
        return SchoolStatus.active;
      case 'suspended':
        return SchoolStatus.suspended;
      case 'archived':
        return SchoolStatus.archived;
      default:
        return SchoolStatus.unknown;
    }
  }

  String toDbString() => name;
}

enum SchoolMemberRole {
  student,
  teacher,
  schoolAdmin,
  unknown;

  static SchoolMemberRole fromString(String? val) {
    if (val == null) return SchoolMemberRole.unknown;
    switch (val.toLowerCase().trim()) {
      case 'student':
        return SchoolMemberRole.student;
      case 'teacher':
        return SchoolMemberRole.teacher;
      case 'school_admin':
      case 'schooladmin':
        return SchoolMemberRole.schoolAdmin;
      default:
        return SchoolMemberRole.unknown;
    }
  }

  String toDbString() {
    switch (this) {
      case SchoolMemberRole.teacher:
        return 'teacher';
      case SchoolMemberRole.schoolAdmin:
        return 'school_admin';
      case SchoolMemberRole.student:
        return 'student';
      case SchoolMemberRole.unknown:
        return 'unknown';
    }
  }
}

enum SchoolMembershipStatus {
  invited,
  active,
  inactive,
  removed,
  unknown;

  static SchoolMembershipStatus fromString(String? val) {
    if (val == null) return SchoolMembershipStatus.unknown;
    switch (val.toLowerCase().trim()) {
      case 'invited':
        return SchoolMembershipStatus.invited;
      case 'active':
        return SchoolMembershipStatus.active;
      case 'inactive':
        return SchoolMembershipStatus.inactive;
      case 'removed':
        return SchoolMembershipStatus.removed;
      default:
        return SchoolMembershipStatus.unknown;
    }
  }

  String toDbString() => name;
}

enum ClassroomMemberRole {
  student,
  teacher,
  unknown;

  static ClassroomMemberRole fromString(String? val) {
    if (val == null) return ClassroomMemberRole.unknown;
    switch (val.toLowerCase().trim()) {
      case 'student':
        return ClassroomMemberRole.student;
      case 'teacher':
        return ClassroomMemberRole.teacher;
      default:
        return ClassroomMemberRole.unknown;
    }
  }

  String toDbString() => name;
}

// Backward-compatibility aliases for Stage 1 code & tests
typedef SchoolRole = SchoolMemberRole;
typedef MembershipStatus = SchoolMembershipStatus;
typedef SchoolTenant = School;
typedef ClassroomEntity = Classroom;
typedef ClassroomMembershipEntity = ClassroomMembership;
typedef TeacherSubjectAssignmentEntity = TeacherSubjectAssignment;
typedef SchoolInvitationEntity = SchoolInvitation;

// =============================================================================
// Canonical Pure-Dart Domain Models
// =============================================================================

/// Canonical institutional school entity.
class School extends Equatable {
  final String id;
  final String name;
  final String? displayName;
  final String schoolCode;
  final SchoolStatus status;
  final String? city;
  final String? region;
  final String timezone;
  final String? logoUrl;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const School({
    required this.id,
    required this.name,
    this.displayName,
    required this.schoolCode,
    this.status = SchoolStatus.active,
    this.city,
    this.region,
    this.timezone = 'Africa/Addis_Ababa',
    this.logoUrl,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == SchoolStatus.active;
  bool get isSuspended => status == SchoolStatus.suspended;
  bool get isArchived => status == SchoolStatus.archived;

  factory School.fromJson(Map<String, dynamic> json) {
    return School(
      id: json['id'] as String,
      name: json['name'] as String,
      displayName: json['display_name'] as String?,
      schoolCode: json['school_code'] as String,
      status: SchoolStatus.fromString(json['status'] as String?),
      city: json['city'] as String?,
      region: json['region'] as String?,
      timezone: json['timezone'] as String? ?? 'Africa/Addis_Ababa',
      logoUrl: json['logo_url'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'display_name': displayName,
      'school_code': schoolCode,
      'status': status.toDbString(),
      'city': city,
      'region': region,
      'timezone': timezone,
      'logo_url': logoUrl,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        displayName,
        schoolCode,
        status,
        city,
        region,
        timezone,
        logoUrl,
        createdBy,
        createdAt,
        updatedAt,
      ];
}

/// Canonical institutional school membership.
/// Uniquely scoped to (school_id, user_id).
class SchoolMembership extends Equatable {
  final String id;
  final String schoolId;
  final String userId;
  final SchoolMemberRole role;
  final SchoolMembershipStatus status;
  final String? schoolStudentId;
  final DateTime? joinedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SchoolMembership({
    required this.id,
    required this.schoolId,
    required this.userId,
    required this.role,
    this.status = SchoolMembershipStatus.active,
    this.schoolStudentId,
    this.joinedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == SchoolMembershipStatus.active;
  bool get isTeacher => role == SchoolMemberRole.teacher && isActive;
  bool get isSchoolAdmin => role == SchoolMemberRole.schoolAdmin && isActive;
  bool get isStudent => role == SchoolMemberRole.student && isActive;

  factory SchoolMembership.fromJson(Map<String, dynamic> json) {
    return SchoolMembership(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      userId: json['user_id'] as String,
      role: SchoolMemberRole.fromString(json['role'] as String?),
      status: SchoolMembershipStatus.fromString(json['status'] as String?),
      schoolStudentId: json['school_student_id'] as String?,
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'user_id': userId,
      'role': role.toDbString(),
      'status': status.toDbString(),
      'school_student_id': schoolStudentId,
      'joined_at': joinedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        userId,
        role,
        status,
        schoolStudentId,
        joinedAt,
        createdAt,
        updatedAt,
      ];
}

/// Relational aggregate joining a SchoolMembership with its parent School.
class SchoolMembershipWithSchool extends Equatable {
  final SchoolMembership membership;
  final School school;

  const SchoolMembershipWithSchool({
    required this.membership,
    required this.school,
  });

  bool get isActive => membership.isActive && school.isActive;

  factory SchoolMembershipWithSchool.fromJson(Map<String, dynamic> json) {
    final membership = SchoolMembership.fromJson(json);
    final schoolJson = json['schools'] as Map<String, dynamic>? ??
        json['school'] as Map<String, dynamic>? ??
        <String, dynamic>{};
    final school = School.fromJson(schoolJson);
    return SchoolMembershipWithSchool(
      membership: membership,
      school: school,
    );
  }

  Map<String, dynamic> toJson() {
    final json = membership.toJson();
    json['schools'] = school.toJson();
    return json;
  }

  @override
  List<Object?> get props => [membership, school];
}

/// Canonical institutional classroom belonging to a school.
/// Architectural update: NO single teacherId. Teacher relations come from TeacherSubjectAssignment.
class Classroom extends Equatable {
  final String id;
  final String schoolId;
  final String name;
  final int grade;
  final String? stream;
  final String? section;
  final String academicYear;
  final String status;
  final int studentCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Classroom({
    required this.id,
    required this.schoolId,
    required this.name,
    required this.grade,
    this.stream,
    this.section,
    required this.academicYear,
    this.status = 'active',
    this.studentCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == 'active';

  /// Reuses frozen stream semantics: 'naturalScience' and 'socialScience'.
  /// Normalizes legacy stream strings if encountered.
  static String? normalizeStream(String? raw) {
    if (raw == null) return null;
    switch (raw.toLowerCase().trim()) {
      case 'natural':
      case 'naturalscience':
        return 'naturalScience';
      case 'social':
      case 'socialscience':
        return 'socialScience';
      case 'common':
      case 'general':
        return 'common';
      default:
        return raw;
    }
  }

  factory Classroom.fromJson(Map<String, dynamic> json) {
    return Classroom(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? '',
      name: json['name'] as String,
      grade: json['grade'] as int? ?? 12,
      stream: normalizeStream(json['stream'] as String?),
      section: json['section'] as String?,
      academicYear: json['academic_year'] as String? ?? '2026/27',
      status: json['status'] as String? ?? 'active',
      studentCount: json['student_count'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'name': name,
      'grade': grade,
      'stream': stream,
      'section': section,
      'academic_year': academicYear,
      'status': status,
      'student_count': studentCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        name,
        grade,
        stream,
        section,
        academicYear,
        status,
        studentCount,
        createdAt,
        updatedAt,
      ];
}

/// Classroom membership for students or homeroom staff.
class ClassroomMembership extends Equatable {
  final String id;
  final String classroomId;
  final String userId;
  final ClassroomMemberRole role;
  final SchoolMembershipStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ClassroomMembership({
    required this.id,
    required this.classroomId,
    required this.userId,
    required this.role,
    this.status = SchoolMembershipStatus.active,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == SchoolMembershipStatus.active;

  factory ClassroomMembership.fromJson(Map<String, dynamic> json) {
    return ClassroomMembership(
      id: json['id'] as String,
      classroomId: json['classroom_id'] as String,
      userId: json['user_id'] as String,
      role: ClassroomMemberRole.fromString(json['role'] as String?),
      status: SchoolMembershipStatus.fromString(json['status'] as String?),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'classroom_id': classroomId,
      'user_id': userId,
      'role': role.toDbString(),
      'status': status.toDbString(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        classroomId,
        userId,
        role,
        status,
        createdAt,
        updatedAt,
      ];
}

/// Scopes a teacher's subject authority within a classroom.
/// Reuses frozen ExamVariantCode from subject_models.dart.
class TeacherSubjectAssignment extends Equatable {
  final String id;
  final String schoolId;
  final String teacherUserId;
  final String classroomId;
  final String subjectId;
  final ExamVariantCode? examVariant;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TeacherSubjectAssignment({
    required this.id,
    required this.schoolId,
    required this.teacherUserId,
    required this.classroomId,
    required this.subjectId,
    this.examVariant,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == 'active';

  factory TeacherSubjectAssignment.fromJson(Map<String, dynamic> json) {
    return TeacherSubjectAssignment(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      teacherUserId: json['teacher_user_id'] as String,
      classroomId: json['classroom_id'] as String,
      subjectId: json['subject_id'] as String,
      examVariant: json['exam_variant'] != null
          ? ExamVariantCode.fromString(json['exam_variant'] as String?)
          : null,
      status: json['status'] as String? ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'teacher_user_id': teacherUserId,
      'classroom_id': classroomId,
      'subject_id': subjectId,
      'exam_variant': examVariant?.name,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        teacherUserId,
        classroomId,
        subjectId,
        examVariant,
        status,
        createdAt,
        updatedAt,
      ];
}

/// School invitation domain model.
/// Note: Plaintext token_hash is strictly NOT exposed in student/teacher-facing domain objects.
class SchoolInvitation extends Equatable {
  final String id;
  final String schoolId;
  final SchoolMemberRole role;
  final String? emailOrIdentifier;
  final String? tokenHash;
  final DateTime expiresAt;
  final String status; // 'pending', 'accepted', 'revoked', 'expired'
  final String? createdBy;
  final DateTime createdAt;

  const SchoolInvitation({
    required this.id,
    required this.schoolId,
    required this.role,
    this.emailOrIdentifier,
    this.tokenHash,
    required this.expiresAt,
    this.status = 'pending',
    this.createdBy,
    required this.createdAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isPending => status == 'pending' && !isExpired;

  factory SchoolInvitation.fromJson(Map<String, dynamic> json) {
    return SchoolInvitation(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      role: SchoolMemberRole.fromString(json['role'] as String?),
      emailOrIdentifier: json['email_or_identifier'] as String?,
      tokenHash: json['token_hash'] as String?,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      status: json['status'] as String? ?? 'pending',
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'role': role.toDbString(),
      'email_or_identifier': emailOrIdentifier,
      if (tokenHash != null) 'token_hash': tokenHash,
      'expires_at': expiresAt.toIso8601String(),
      'status': status,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        role,
        emailOrIdentifier,
        tokenHash,
        expiresAt,
        status,
        createdBy,
        createdAt,
      ];
}

// =============================================================================
// Offline Affiliation Cache & ActiveSchoolContext Models
// =============================================================================

/// Lightweight snapshot of institutional affiliation stored locally for offline display.
/// NOTE: This cached context is strictly for UI display and NEVER grants backend authorization.
class CachedSchoolContext extends Equatable {
  final String schoolId;
  final String schoolName;
  final String schoolCode;
  final String membershipId;
  final SchoolMemberRole membershipRole;
  final SchoolMembershipStatus membershipStatus;
  final String? activeClassroomId;
  final String? activeClassroomName;
  final String? userId;
  final DateTime cachedAt;

  const CachedSchoolContext({
    required this.schoolId,
    required this.schoolName,
    required this.schoolCode,
    required this.membershipId,
    required this.membershipRole,
    required this.membershipStatus,
    this.activeClassroomId,
    this.activeClassroomName,
    this.userId,
    required this.cachedAt,
  });

  factory CachedSchoolContext.fromSchoolAndMembership({
    required School school,
    required SchoolMembership membership,
    Classroom? classroom,
  }) {
    return CachedSchoolContext(
      schoolId: school.id,
      schoolName: school.displayName ?? school.name,
      schoolCode: school.schoolCode,
      membershipId: membership.id,
      membershipRole: membership.role,
      membershipStatus: membership.status,
      activeClassroomId: classroom?.id,
      activeClassroomName: classroom?.name,
      userId: membership.userId,
      cachedAt: DateTime.now(),
    );
  }

  factory CachedSchoolContext.fromJson(Map<String, dynamic> json) {
    return CachedSchoolContext(
      schoolId: json['school_id'] as String,
      schoolName: json['school_name'] as String,
      schoolCode: json['school_code'] as String,
      membershipId: json['membership_id'] as String,
      membershipRole:
          SchoolMemberRole.fromString(json['membership_role'] as String?),
      membershipStatus: SchoolMembershipStatus.fromString(
          json['membership_status'] as String?),
      activeClassroomId: json['active_classroom_id'] as String?,
      activeClassroomName: json['active_classroom_name'] as String?,
      userId: json['user_id'] as String?,
      cachedAt: DateTime.parse(json['cached_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'school_id': schoolId,
      'school_name': schoolName,
      'school_code': schoolCode,
      'membership_id': membershipId,
      'membership_role': membershipRole.toDbString(),
      'membership_status': membershipStatus.toDbString(),
      'active_classroom_id': activeClassroomId,
      'active_classroom_name': activeClassroomName,
      'user_id': userId,
      'cached_at': cachedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        schoolId,
        schoolName,
        schoolCode,
        membershipId,
        membershipRole,
        membershipStatus,
        activeClassroomId,
        activeClassroomName,
        userId,
        cachedAt,
      ];
}

/// Status of the application ActiveSchoolContext state machine.
enum ActiveSchoolContextStatus {
  loading,
  independent, // 0 school memberships (pure personal learner)
  active, // Active school context verified and loaded from backend
  offlineCached, // Active school loaded from local storage while offline
  permissionRevoked, // Server indicated membership became inactive or removed
  error,
}

/// Application-level ActiveSchoolContext.
/// IMPORTANT: ActiveSchoolContext represents UI/display context only, NOT backend authorization.
/// Supabase PostgreSQL Row Level Security (RLS) is the sole authoritative gatekeeper.
class ActiveSchoolContext extends Equatable {
  final ActiveSchoolContextStatus status;
  final School? school;
  final SchoolMembership? membership;
  final List<ClassroomMembership> classroomMemberships;
  final Classroom? selectedClassroom;
  final String? errorMessage;
  final bool isOfflineCached;

  const ActiveSchoolContext({
    required this.status,
    this.school,
    this.membership,
    this.classroomMemberships = const [],
    this.selectedClassroom,
    this.errorMessage,
    this.isOfflineCached = false,
  });

  const ActiveSchoolContext.loading()
      : this(status: ActiveSchoolContextStatus.loading);

  const ActiveSchoolContext.independent()
      : this(status: ActiveSchoolContextStatus.independent);

  const ActiveSchoolContext.error(String message)
      : this(
          status: ActiveSchoolContextStatus.error,
          errorMessage: message,
        );

  const ActiveSchoolContext.permissionRevoked([String? message])
      : this(
          status: ActiveSchoolContextStatus.permissionRevoked,
          errorMessage: message ?? 'School membership is inactive or removed.',
        );

  bool get isLoading => status == ActiveSchoolContextStatus.loading;

  School? get activeSchool => school;

  bool get isIndependent =>
      status == ActiveSchoolContextStatus.independent ||
      (school == null && membership == null);

  bool get hasActiveSchool =>
      (status == ActiveSchoolContextStatus.active ||
          status == ActiveSchoolContextStatus.offlineCached) &&
      school != null &&
      membership != null &&
      membership!.isActive;

  bool get isTeacher =>
      hasActiveSchool && membership!.role == SchoolMemberRole.teacher;

  bool get isSchoolAdmin =>
      hasActiveSchool && membership!.role == SchoolMemberRole.schoolAdmin;

  bool get isStudent =>
      hasActiveSchool && membership!.role == SchoolMemberRole.student;

  String get displaySchoolName =>
      school?.displayName ?? school?.name ?? 'Independent Study';

  ActiveSchoolContext copyWith({
    ActiveSchoolContextStatus? status,
    School? school,
    SchoolMembership? membership,
    List<ClassroomMembership>? classroomMemberships,
    Classroom? selectedClassroom,
    String? errorMessage,
    bool? isOfflineCached,
  }) {
    return ActiveSchoolContext(
      status: status ?? this.status,
      school: school ?? this.school,
      membership: membership ?? this.membership,
      classroomMemberships: classroomMemberships ?? this.classroomMemberships,
      selectedClassroom: selectedClassroom ?? this.selectedClassroom,
      errorMessage: errorMessage ?? this.errorMessage,
      isOfflineCached: isOfflineCached ?? this.isOfflineCached,
    );
  }

  @override
  List<Object?> get props => [
        status,
        school,
        membership,
        classroomMemberships,
        selectedClassroom,
        errorMessage,
        isOfflineCached,
      ];
}

/// Application UI helper for inspecting institutional access capabilities.
/// UI helper != security boundary.
class InstitutionalAccess {
  final SchoolMemberRole role;
  final SchoolMembershipStatus status;

  const InstitutionalAccess({
    required this.role,
    required this.status,
  });

  bool get isActive => status == SchoolMembershipStatus.active;
  bool get canTeach => role == SchoolMemberRole.teacher && isActive;
  bool get canAdministerSchool =>
      role == SchoolMemberRole.schoolAdmin && isActive;
  bool get isSchoolStudent => role == SchoolMemberRole.student && isActive;
}
