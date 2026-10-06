import 'package:equatable/equatable.dart';

// =============================================================================
// P11 Licensing, Seats & Onboarding Domain Enums
// =============================================================================

enum LicenseStatus {
  trial,
  active,
  grace,
  suspended,
  expired,
  cancelled,
  unknown;

  static LicenseStatus fromString(String? val) {
    if (val == null) return LicenseStatus.unknown;
    switch (val.toLowerCase().trim()) {
      case 'trial':
        return LicenseStatus.trial;
      case 'active':
        return LicenseStatus.active;
      case 'grace':
        return LicenseStatus.grace;
      case 'suspended':
        return LicenseStatus.suspended;
      case 'expired':
        return LicenseStatus.expired;
      case 'cancelled':
        return LicenseStatus.cancelled;
      default:
        return LicenseStatus.unknown;
    }
  }

  String toDbString() => name;

  bool get isOperational =>
      this == LicenseStatus.active ||
      this == LicenseStatus.trial ||
      this == LicenseStatus.grace;
}

enum BillingInterval {
  monthly,
  term,
  annual,
  custom,
  unknown;

  static BillingInterval fromString(String? val) {
    if (val == null) return BillingInterval.unknown;
    switch (val.toLowerCase().trim()) {
      case 'monthly':
        return BillingInterval.monthly;
      case 'term':
        return BillingInterval.term;
      case 'annual':
        return BillingInterval.annual;
      case 'custom':
        return BillingInterval.custom;
      default:
        return BillingInterval.unknown;
    }
  }

  String toDbString() => name;
}

enum OnboardingStatus {
  notStarted,
  inProgress,
  readyForActivation,
  completed,
  blocked,
  unknown;

  static OnboardingStatus fromString(String? val) {
    if (val == null) return OnboardingStatus.unknown;
    switch (val.toLowerCase().trim()) {
      case 'not_started':
        return OnboardingStatus.notStarted;
      case 'in_progress':
        return OnboardingStatus.inProgress;
      case 'ready_for_activation':
        return OnboardingStatus.readyForActivation;
      case 'completed':
        return OnboardingStatus.completed;
      case 'blocked':
        return OnboardingStatus.blocked;
      default:
        return OnboardingStatus.unknown;
    }
  }

  String toDbString() {
    switch (this) {
      case OnboardingStatus.notStarted:
        return 'not_started';
      case OnboardingStatus.inProgress:
        return 'in_progress';
      case OnboardingStatus.readyForActivation:
        return 'ready_for_activation';
      case OnboardingStatus.completed:
        return 'completed';
      case OnboardingStatus.blocked:
        return 'blocked';
      case OnboardingStatus.unknown:
        return 'unknown';
    }
  }
}

enum ImportRunStatus {
  validating,
  previewReady,
  completed,
  failed,
  unknown;

  static ImportRunStatus fromString(String? val) {
    if (val == null) return ImportRunStatus.unknown;
    switch (val.toLowerCase().trim()) {
      case 'validating':
        return ImportRunStatus.validating;
      case 'preview_ready':
        return ImportRunStatus.previewReady;
      case 'completed':
        return ImportRunStatus.completed;
      case 'failed':
        return ImportRunStatus.failed;
      default:
        return ImportRunStatus.unknown;
    }
  }

  String toDbString() {
    switch (this) {
      case ImportRunStatus.validating:
        return 'validating';
      case ImportRunStatus.previewReady:
        return 'preview_ready';
      case ImportRunStatus.completed:
        return 'completed';
      case ImportRunStatus.failed:
        return 'failed';
      case ImportRunStatus.unknown:
        return 'unknown';
    }
  }
}

// =============================================================================
// P11 Domain Models
// =============================================================================

class SchoolLicense extends Equatable {
  final String id;
  final String schoolId;
  final String planCode;
  final LicenseStatus status;
  final DateTime startsAt;
  final DateTime? endsAt;
  final DateTime? graceEndsAt;
  final int studentSeatLimit;
  final Map<String, dynamic> featureEntitlements;
  final String? billingCustomerRef;
  final String? billingSubscriptionRef;
  final String source;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SchoolLicense({
    required this.id,
    required this.schoolId,
    required this.planCode,
    required this.status,
    required this.startsAt,
    this.endsAt,
    this.graceEndsAt,
    required this.studentSeatLimit,
    required this.featureEntitlements,
    this.billingCustomerRef,
    this.billingSubscriptionRef,
    required this.source,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  bool hasEntitlement(String key) =>
      status.isOperational && (featureEntitlements[key] == true);

  factory SchoolLicense.fromJson(Map<String, dynamic> json) {
    return SchoolLicense(
      id: json['id'] as String? ?? '',
      schoolId: json['school_id'] as String? ?? '',
      planCode: json['plan_code'] as String? ?? '',
      status: LicenseStatus.fromString(json['status'] as String?),
      startsAt: json['starts_at'] != null
          ? DateTime.parse(json['starts_at'] as String)
          : DateTime.now(),
      endsAt: json['ends_at'] != null
          ? DateTime.parse(json['ends_at'] as String)
          : null,
      graceEndsAt: json['grace_ends_at'] != null
          ? DateTime.parse(json['grace_ends_at'] as String)
          : null,
      studentSeatLimit: (json['student_seat_limit'] as num?)?.toInt() ?? 0,
      featureEntitlements:
          (json['feature_entitlements'] as Map<String, dynamic>?) ?? {},
      billingCustomerRef: json['billing_customer_ref'] as String?,
      billingSubscriptionRef: json['billing_subscription_ref'] as String?,
      source: json['source'] as String? ?? 'manual_contract',
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'school_id': schoolId,
        'plan_code': planCode,
        'status': status.toDbString(),
        'starts_at': startsAt.toIso8601String(),
        'ends_at': endsAt?.toIso8601String(),
        'grace_ends_at': graceEndsAt?.toIso8601String(),
        'student_seat_limit': studentSeatLimit,
        'feature_entitlements': featureEntitlements,
        'billing_customer_ref': billingCustomerRef,
        'billing_subscription_ref': billingSubscriptionRef,
        'source': source,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        id,
        schoolId,
        planCode,
        status,
        startsAt,
        endsAt,
        graceEndsAt,
        studentSeatLimit,
        featureEntitlements,
        billingCustomerRef,
        billingSubscriptionRef,
        source,
        createdBy,
        createdAt,
        updatedAt,
      ];
}

class InstitutionalPlan extends Equatable {
  final String planCode;
  final String displayName;
  final int defaultStudentSeatLimit;
  final Map<String, dynamic> defaultEntitlements;
  final BillingInterval billingInterval;
  final bool isActive;

  const InstitutionalPlan({
    required this.planCode,
    required this.displayName,
    required this.defaultStudentSeatLimit,
    required this.defaultEntitlements,
    required this.billingInterval,
    required this.isActive,
  });

  factory InstitutionalPlan.fromJson(Map<String, dynamic> json) {
    return InstitutionalPlan(
      planCode: json['plan_code'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      defaultStudentSeatLimit:
          (json['default_student_seat_limit'] as num?)?.toInt() ?? 100,
      defaultEntitlements:
          (json['default_entitlements'] as Map<String, dynamic>?) ?? {},
      billingInterval:
          BillingInterval.fromString(json['billing_interval'] as String?),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'plan_code': planCode,
        'display_name': displayName,
        'default_student_seat_limit': defaultStudentSeatLimit,
        'default_entitlements': defaultEntitlements,
        'billing_interval': billingInterval.toDbString(),
        'is_active': isActive,
      };

  @override
  List<Object?> get props => [
        planCode,
        displayName,
        defaultStudentSeatLimit,
        defaultEntitlements,
        billingInterval,
        isActive,
      ];
}

class SchoolSeatUsage extends Equatable {
  final String schoolId;
  final LicenseStatus licenseStatus;
  final int studentSeatLimit;
  final int occupiedSeats;
  final int availableSeats;
  final double seatUtilizationPct;
  final bool isOverCapacity;
  final String
      warningLevel; // 'none', 'warning_80', 'warning_90', 'critical_100'

  const SchoolSeatUsage({
    required this.schoolId,
    required this.licenseStatus,
    required this.studentSeatLimit,
    required this.occupiedSeats,
    required this.availableSeats,
    required this.seatUtilizationPct,
    required this.isOverCapacity,
    required this.warningLevel,
  });

  factory SchoolSeatUsage.fromJson(Map<String, dynamic> json) {
    final limit = (json['student_seat_limit'] as num?)?.toInt() ?? 0;
    final occupied = (json['occupied_seats'] as num?)?.toInt() ?? 0;
    final available = (json['available_seats'] as num?)?.toInt() ?? 0;
    final util = (json['seat_utilization_pct'] as num?)?.toDouble() ??
        (limit > 0 ? (occupied / limit) * 100.0 : 0.0);
    final overCap = json['is_over_capacity'] as bool? ?? (occupied > limit);

    String warn = 'none';
    if (overCap || util >= 100.0) {
      warn = 'critical_100';
    } else if (util >= 90.0) {
      warn = 'warning_90';
    } else if (util >= 80.0) {
      warn = 'warning_80';
    }

    return SchoolSeatUsage(
      schoolId: json['school_id'] as String? ?? '',
      licenseStatus:
          LicenseStatus.fromString(json['license_status'] as String?),
      studentSeatLimit: limit,
      occupiedSeats: occupied,
      availableSeats: available,
      seatUtilizationPct: util,
      isOverCapacity: overCap,
      warningLevel: warn,
    );
  }

  Map<String, dynamic> toJson() => {
        'school_id': schoolId,
        'license_status': licenseStatus.toDbString(),
        'student_seat_limit': studentSeatLimit,
        'occupied_seats': occupiedSeats,
        'available_seats': availableSeats,
        'seat_utilization_pct': seatUtilizationPct,
        'is_over_capacity': isOverCapacity,
        'warning_level': warningLevel,
      };

  @override
  List<Object?> get props => [
        schoolId,
        licenseStatus,
        studentSeatLimit,
        occupiedSeats,
        availableSeats,
        seatUtilizationPct,
        isOverCapacity,
        warningLevel,
      ];
}

class SchoolEntitlements extends Equatable {
  final String schoolId;
  final LicenseStatus licenseStatus;
  final bool studentLearning;
  final bool teacherPortal;
  final bool leadershipDashboard;
  final bool assignmentsInterventions;
  final bool institutionalReporting;
  final bool nationalExamSimulation;
  final Map<String, dynamic> rawEntitlements;

  const SchoolEntitlements({
    required this.schoolId,
    required this.licenseStatus,
    required this.studentLearning,
    required this.teacherPortal,
    required this.leadershipDashboard,
    required this.assignmentsInterventions,
    required this.institutionalReporting,
    required this.nationalExamSimulation,
    required this.rawEntitlements,
  });

  bool has(String key) {
    if (!licenseStatus.isOperational) return false;
    switch (key) {
      case 'student_learning':
        return studentLearning;
      case 'teacher_portal':
        return teacherPortal;
      case 'leadership_dashboard':
        return leadershipDashboard;
      case 'assignments_interventions':
        return assignmentsInterventions;
      case 'institutional_reporting':
        return institutionalReporting;
      case 'national_exam_simulation':
        return nationalExamSimulation;
      default:
        return rawEntitlements[key] == true;
    }
  }

  factory SchoolEntitlements.fromJson(Map<String, dynamic> json) {
    final status = LicenseStatus.fromString(json['license_status'] as String?);
    final ent = (json['entitlements'] as Map<String, dynamic>?) ?? {};
    final isOper = status.isOperational;

    return SchoolEntitlements(
      schoolId: json['school_id'] as String? ?? '',
      licenseStatus: status,
      studentLearning: isOper && (ent['student_learning'] == true),
      teacherPortal: isOper && (ent['teacher_portal'] == true),
      leadershipDashboard: isOper && (ent['leadership_dashboard'] == true),
      assignmentsInterventions:
          isOper && (ent['assignments_interventions'] == true),
      institutionalReporting:
          isOper && (ent['institutional_reporting'] == true),
      nationalExamSimulation:
          isOper && (ent['national_exam_simulation'] == true),
      rawEntitlements: ent,
    );
  }

  @override
  List<Object?> get props => [
        schoolId,
        licenseStatus,
        studentLearning,
        teacherPortal,
        leadershipDashboard,
        assignmentsInterventions,
        institutionalReporting,
        nationalExamSimulation,
        rawEntitlements,
      ];
}

class SchoolOnboardingState extends Equatable {
  final String schoolId;
  final OnboardingStatus status;
  final bool schoolCreated;
  final bool licenseConfigured;
  final bool academicYearConfigured;
  final bool classesConfigured;
  final bool adminConfigured;
  final bool teachersConfigured;
  final bool teacherAssignmentsConfigured;
  final bool studentsConfigured;
  final bool coverageValidated;
  final bool activationReady;
  final DateTime? activatedAt;
  final DateTime updatedAt;

  const SchoolOnboardingState({
    required this.schoolId,
    required this.status,
    required this.schoolCreated,
    required this.licenseConfigured,
    required this.academicYearConfigured,
    required this.classesConfigured,
    required this.adminConfigured,
    required this.teachersConfigured,
    required this.teacherAssignmentsConfigured,
    required this.studentsConfigured,
    required this.coverageValidated,
    required this.activationReady,
    this.activatedAt,
    required this.updatedAt,
  });

  int get completedStepsCount {
    int count = 0;
    if (schoolCreated) count++;
    if (licenseConfigured) count++;
    if (academicYearConfigured) count++;
    if (classesConfigured) count++;
    if (adminConfigured) count++;
    if (teachersConfigured) count++;
    if (teacherAssignmentsConfigured) count++;
    if (studentsConfigured) count++;
    if (coverageValidated) count++;
    if (activationReady) count++;
    return count;
  }

  double get progressPct => (completedStepsCount / 10.0) * 100.0;

  factory SchoolOnboardingState.fromJson(Map<String, dynamic> json) {
    return SchoolOnboardingState(
      schoolId: json['school_id'] as String? ?? '',
      status: OnboardingStatus.fromString(json['status'] as String?),
      schoolCreated: json['school_created'] as bool? ?? true,
      licenseConfigured: json['license_configured'] as bool? ?? false,
      academicYearConfigured:
          json['academic_year_configured'] as bool? ?? false,
      classesConfigured: json['classes_configured'] as bool? ?? false,
      adminConfigured: json['admin_configured'] as bool? ?? false,
      teachersConfigured: json['teachers_configured'] as bool? ?? false,
      teacherAssignmentsConfigured:
          json['teacher_assignments_configured'] as bool? ?? false,
      studentsConfigured: json['students_configured'] as bool? ?? false,
      coverageValidated: json['coverage_validated'] as bool? ?? false,
      activationReady: json['activation_ready'] as bool? ?? false,
      activatedAt: json['activated_at'] != null
          ? DateTime.parse(json['activated_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'school_id': schoolId,
        'status': status.toDbString(),
        'school_created': schoolCreated,
        'license_configured': licenseConfigured,
        'academic_year_configured': academicYearConfigured,
        'classes_configured': classesConfigured,
        'admin_configured': adminConfigured,
        'teachers_configured': teachersConfigured,
        'teacher_assignments_configured': teacherAssignmentsConfigured,
        'students_configured': studentsConfigured,
        'coverage_validated': coverageValidated,
        'activation_ready': activationReady,
        'activated_at': activatedAt?.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        schoolId,
        status,
        schoolCreated,
        licenseConfigured,
        academicYearConfigured,
        classesConfigured,
        adminConfigured,
        teachersConfigured,
        teacherAssignmentsConfigured,
        studentsConfigured,
        coverageValidated,
        activationReady,
        activatedAt,
        updatedAt,
      ];
}

class InstitutionalImportRun extends Equatable {
  final String id;
  final String schoolId;
  final String importType;
  final String requestedBy;
  final ImportRunStatus status;
  final int totalRows;
  final int validRows;
  final int invalidRows;
  final int createdCount;
  final int existingCount;
  final int errorCount;
  final String idempotencyKey;
  final List<dynamic> errors;
  final DateTime createdAt;
  final DateTime? completedAt;

  const InstitutionalImportRun({
    required this.id,
    required this.schoolId,
    required this.importType,
    required this.requestedBy,
    required this.status,
    required this.totalRows,
    required this.validRows,
    required this.invalidRows,
    required this.createdCount,
    required this.existingCount,
    required this.errorCount,
    required this.idempotencyKey,
    required this.errors,
    required this.createdAt,
    this.completedAt,
  });

  factory InstitutionalImportRun.fromJson(Map<String, dynamic> json) {
    return InstitutionalImportRun(
      id: json['id'] as String? ?? '',
      schoolId: json['school_id'] as String? ?? '',
      importType: json['import_type'] as String? ?? 'students',
      requestedBy: json['requested_by'] as String? ?? '',
      status: ImportRunStatus.fromString(json['status'] as String?),
      totalRows: (json['total_rows'] as num?)?.toInt() ?? 0,
      validRows: (json['valid_rows'] as num?)?.toInt() ?? 0,
      invalidRows: (json['invalid_rows'] as num?)?.toInt() ?? 0,
      createdCount: (json['created_count'] as num?)?.toInt() ?? 0,
      existingCount: (json['existing_count'] as num?)?.toInt() ?? 0,
      errorCount: (json['error_count'] as num?)?.toInt() ?? 0,
      idempotencyKey: json['idempotency_key'] as String? ?? '',
      errors: (json['errors'] as List<dynamic>?) ?? [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'school_id': schoolId,
        'import_type': importType,
        'requested_by': requestedBy,
        'status': status.toDbString(),
        'total_rows': totalRows,
        'valid_rows': validRows,
        'invalid_rows': invalidRows,
        'created_count': createdCount,
        'existing_count': existingCount,
        'error_count': errorCount,
        'idempotency_key': idempotencyKey,
        'errors': errors,
        'created_at': createdAt.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        id,
        schoolId,
        importType,
        requestedBy,
        status,
        totalRows,
        validRows,
        invalidRows,
        createdCount,
        existingCount,
        errorCount,
        idempotencyKey,
        errors,
        createdAt,
        completedAt,
      ];
}

class BillingCustomer extends Equatable {
  final String id;
  final String schoolId;
  final String provider;
  final String externalCustomerId;
  final String? billingEmail;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const BillingCustomer({
    required this.id,
    required this.schoolId,
    required this.provider,
    required this.externalCustomerId,
    this.billingEmail,
    this.metadata,
    required this.createdAt,
  });

  factory BillingCustomer.fromJson(Map<String, dynamic> json) {
    return BillingCustomer(
      id: json['id'] as String? ?? '',
      schoolId: json['school_id'] as String? ?? '',
      provider: json['provider'] as String? ?? 'telebirr',
      externalCustomerId: json['external_customer_id'] as String? ?? '',
      billingEmail: json['billing_email'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        provider,
        externalCustomerId,
        billingEmail,
        metadata,
        createdAt,
      ];
}

class BillingSubscription extends Equatable {
  final String id;
  final String schoolId;
  final String provider;
  final String externalSubscriptionId;
  final String planCode;
  final String status;
  final BillingInterval billingInterval;
  final DateTime currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final bool cancelAtPeriodEnd;
  final DateTime createdAt;

  const BillingSubscription({
    required this.id,
    required this.schoolId,
    required this.provider,
    required this.externalSubscriptionId,
    required this.planCode,
    required this.status,
    required this.billingInterval,
    required this.currentPeriodStart,
    this.currentPeriodEnd,
    required this.cancelAtPeriodEnd,
    required this.createdAt,
  });

  factory BillingSubscription.fromJson(Map<String, dynamic> json) {
    return BillingSubscription(
      id: json['id'] as String? ?? '',
      schoolId: json['school_id'] as String? ?? '',
      provider: json['provider'] as String? ?? 'telebirr',
      externalSubscriptionId: json['external_subscription_id'] as String? ?? '',
      planCode: json['plan_code'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      billingInterval:
          BillingInterval.fromString(json['billing_interval'] as String?),
      currentPeriodStart: json['current_period_start'] != null
          ? DateTime.parse(json['current_period_start'] as String)
          : DateTime.now(),
      currentPeriodEnd: json['current_period_end'] != null
          ? DateTime.parse(json['current_period_end'] as String)
          : null,
      cancelAtPeriodEnd: json['cancel_at_period_end'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        provider,
        externalSubscriptionId,
        planCode,
        status,
        billingInterval,
        currentPeriodStart,
        currentPeriodEnd,
        cancelAtPeriodEnd,
        createdAt,
      ];
}
