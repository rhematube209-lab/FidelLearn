import '../../domain/models/institutional_reporting_models.dart';
import '../../domain/repositories/institutional_reporting_repository.dart';

/// In-memory/local repository implementation for institutional reporting.
/// STRICTLY FOR TESTS AND EXPLICIT DEVELOPER DEMONSTRATIONS ONLY.
/// Production strictly uses [SupabaseInstitutionalReportingRepository] and
/// presents offline reconnection notices without synthetic reporting fallbacks.
class LocalInstitutionalReportingRepository
    implements InstitutionalReportingRepository {
  final List<InstitutionalReportRun> _runs = [];

  LocalInstitutionalReportingRepository() {
    // Seed initial demo run
    _runs.add(
      InstitutionalReportRun(
        id: 'run-demo-01',
        schoolId: 'demo-school-id',
        requestedBy: 'demo-user-id',
        requestedByName: 'Director Abebe',
        reportType: InstitutionalReportType.executive,
        status: ReportRunStatus.completed,
        academicYear: '2026/27',
        periodStart: DateTime.now().toUtc().subtract(const Duration(days: 30)),
        periodEnd: DateTime.now().toUtc(),
        filtersJson: const {'period': 'last_30_days'},
        analyticsVersion: kInstitutionalAnalyticsVersion,
        reportSchemaVersion: kInstitutionalReportSchemaVersion,
        dataAsOf: DateTime.now().toUtc(),
        fileFormat: 'csv',
        rowCount: 1,
        createdAt: DateTime.now().toUtc().subtract(const Duration(minutes: 10)),
      ),
    );
  }

  @override
  Future<InstitutionalReportRun> createReportRun({
    required String schoolId,
    required InstitutionalReportType reportType,
    required String academicYear,
    required DateTime periodStart,
    required DateTime periodEnd,
    Map<String, dynamic> filters = const {},
    String fileFormat = 'csv',
  }) async {
    final run = InstitutionalReportRun(
      id: 'run-${DateTime.now().millisecondsSinceEpoch}',
      schoolId: schoolId,
      requestedBy: 'current-user',
      requestedByName: 'School Administrator',
      reportType: reportType,
      status: ReportRunStatus.completed,
      academicYear: academicYear,
      periodStart: periodStart,
      periodEnd: periodEnd,
      filtersJson: filters,
      analyticsVersion: kInstitutionalAnalyticsVersion,
      reportSchemaVersion: kInstitutionalReportSchemaVersion,
      dataAsOf: DateTime.now().toUtc(),
      fileFormat: fileFormat,
      rowCount: 25,
      createdAt: DateTime.now().toUtc(),
    );
    _runs.insert(0, run);
    return run;
  }

  @override
  Future<List<InstitutionalReportRun>> getReportRuns({
    required String schoolId,
    InstitutionalReportType? reportType,
    int limit = 50,
    int offset = 0,
  }) async {
    return _runs
        .where((r) =>
            r.schoolId == schoolId &&
            (reportType == null || r.reportType == reportType))
        .skip(offset)
        .take(limit)
        .toList();
  }

  @override
  Future<ExecutiveReport> getExecutiveReport({
    required String schoolId,
    String? academicYear,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) async {
    final now = DateTime.now().toUtc();
    return ExecutiveReport(
      schoolId: schoolId,
      schoolName: 'Bole Secondary School',
      academicYear: academicYear ?? '2026/27',
      periodStart: periodStart ?? now.subtract(const Duration(days: 90)),
      periodEnd: periodEnd ?? now,
      dataAsOf: now,
      studentPopulation: 1200,
      naturalStreamStudents: 750,
      socialStreamStudents: 450,
      teacherPopulation: 64,
      classPopulation: 30,
      assessmentEligibleStudents: 1200,
      assessmentParticipants: 980,
      assessmentParticipationRate: 81.67,
      recentAssessmentAverage: 71.4,
      recentAssessmentMedian: 73.0,
      simulationParticipants: 720,
      simulationParticipationRate: 60.0,
      simulationAverage: 68.2,
      simulationMedian: 69.5,
      requiredForCompletion: 540,
      submittedCount: 460,
      completedCount: 450,
      completionRate: 85.19,
      verifiedLateCount: 35,
      lateRateVerified: 7.61,
      timingUnverifiedCount: 12,
      clockAnomalyCount: 3,
      interventionsCreated: 42,
      interventionsCompleted: 35,
      interventionsWithFollowupEvidence: 28,
      teacherCoverageRate: 98.4,
      freshSyncCount: 950,
      moderateSyncCount: 150,
      staleSyncCount: 80,
      veryStaleSyncCount: 20,
      freshDataCoverageRate: 91.67,
    );
  }

  @override
  Future<List<SubjectPerformanceRow>> getSubjectPerformanceReport({
    required String schoolId,
    String? academicYear,
    DateTime? periodStart,
    DateTime? periodEnd,
    String? stream,
  }) async {
    final now = DateTime.now().toUtc();
    return [
      SubjectPerformanceRow(
        subjectId: 'physics_g12',
        subjectName: 'Physics',
        examVariant: null,
        stream: 'natural',
        eligibleStudents: 750,
        participants: 620,
        participationRate: 82.67,
        attemptCount: 1450,
        averageScore: 68.5,
        medianScore: 70.0,
        affectedStudents: 85,
        activeMistakes: 320,
        assignmentCompletion: 88.0,
        interventionsCount: 14,
        dataAsOf: now,
        privacySuppressed: false,
      ),
      SubjectPerformanceRow(
        subjectId: 'math_g12',
        subjectName: 'Mathematics (Natural Science)',
        examVariant: 'naturalScience',
        stream: 'natural',
        eligibleStudents: 750,
        participants: 640,
        participationRate: 85.33,
        attemptCount: 1680,
        averageScore: 72.3,
        medianScore: 74.0,
        affectedStudents: 72,
        activeMistakes: 280,
        assignmentCompletion: 89.5,
        interventionsCount: 12,
        dataAsOf: now,
        privacySuppressed: false,
      ),
      SubjectPerformanceRow(
        subjectId: 'math_g12',
        subjectName: 'Mathematics (Social Science)',
        examVariant: 'socialScience',
        stream: 'social',
        eligibleStudents: 450,
        participants: 360,
        participationRate: 80.0,
        attemptCount: 920,
        averageScore: 64.8,
        medianScore: 66.0,
        affectedStudents: 65,
        activeMistakes: 240,
        assignmentCompletion: 82.0,
        interventionsCount: 10,
        dataAsOf: now,
        privacySuppressed: false,
      ),
    ];
  }

  @override
  Future<List<StreamPerformanceRow>> getStreamPerformanceReport({
    required String schoolId,
    String? academicYear,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) async {
    final now = DateTime.now().toUtc();
    return [
      StreamPerformanceRow(
        stream: 'natural',
        streamLabel: 'Natural Science',
        studentCount: 750,
        activeClassrooms: 18,
        assessmentParticipants: 640,
        assessmentParticipation: 85.33,
        assessmentAverage: 73.2,
        assessmentMedian: 75.0,
        simulationParticipants: 510,
        simulationParticipation: 68.0,
        simulationAverage: 70.5,
        simulationMedian: 72.0,
        assignmentCompletion: 88.4,
        interventionsCount: 26,
        freshDataCoverage: 92.5,
        dataAsOf: now,
      ),
      StreamPerformanceRow(
        stream: 'social',
        streamLabel: 'Social Science',
        studentCount: 450,
        activeClassrooms: 12,
        assessmentParticipants: 340,
        assessmentParticipation: 75.56,
        assessmentAverage: 67.8,
        assessmentMedian: 69.0,
        simulationParticipants: 210,
        simulationParticipation: 46.67,
        simulationAverage: 64.2,
        simulationMedian: 65.0,
        assignmentCompletion: 81.2,
        interventionsCount: 16,
        freshDataCoverage: 89.0,
        dataAsOf: now,
      ),
    ];
  }

  @override
  Future<List<ClassPerformanceRow>> getClassPerformanceReport({
    required String schoolId,
    String? academicYear,
    DateTime? periodStart,
    DateTime? periodEnd,
    String? classroomId,
    String? subjectId,
  }) async {
    final now = DateTime.now().toUtc();
    return [
      ClassPerformanceRow(
        classroomId: classroomId ?? 'class-12-a',
        classroomName: '12-A Natural',
        grade: 12,
        stream: 'natural',
        enrolledStudents: 45,
        subjectId: subjectId ?? 'physics_g12',
        subjectName: 'Physics',
        assignedTeacherId: 'teacher-dawit',
        assignedTeacherName: 'Teacher Dawit',
        participants: 42,
        participationRate: 93.33,
        averageScore: 74.5,
        medianScore: 76.0,
        mistakeCount: 28,
        assignmentCompletion: 92.0,
        supportStudentsCount: 4,
        dataAsOf: now,
      ),
    ];
  }

  @override
  Future<List<AssessmentReportRow>> getAssessmentReport({
    required String schoolId,
    String? academicYear,
    DateTime? periodStart,
    DateTime? periodEnd,
    String? subjectId,
    String? examId,
  }) async {
    final now = DateTime.now().toUtc();
    return [
      AssessmentReportRow(
        examId: examId ?? 'exam-bio-2013',
        examTitle: 'Biology ESSLCE 2013 National Simulation',
        subjectId: 'biology_g12',
        examVariant: null,
        sourceType: 'officialHistoricalPaper',
        examMode: 'nationalSimulation',
        examType: 'mock_full',
        eligibleStudents: 750,
        participants: 610,
        participationRate: 81.33,
        attemptCount: 840,
        averageScore: 74.2,
        medianScore: 75.0,
        bandBelow50: 35,
        band50to59: 65,
        band60to69: 120,
        band70to79: 190,
        band80to89: 140,
        band90Plus: 60,
        dataAsOf: now,
      ),
    ];
  }

  @override
  Future<List<AssignmentOutcomeRow>> getAssignmentOutcomesReport({
    required String schoolId,
    String? academicYear,
    DateTime? periodStart,
    DateTime? periodEnd,
    String? classroomId,
    String? subjectId,
  }) async {
    final now = DateTime.now().toUtc();
    return [
      AssignmentOutcomeRow(
        assignmentId: 'assign-mech-01',
        assignmentTitle: 'Mechanics Kinematics Problem Set',
        assignmentType: 'targetedPractice',
        classroomId: 'class-12-a',
        classroomName: '12-A Natural',
        subjectId: 'physics_g12',
        examVariant: null,
        teacherName: 'Teacher Dawit',
        publicationCohort: 45,
        requiredDenominator: 44,
        submittedCount: 40,
        completedCount: 39,
        excusedCount: 1,
        verifiedOnTimeCount: 34,
        verifiedLateCount: 4,
        timingUnverifiedCount: 2,
        clockAnomalyCount: 0,
        completionRate: 90.91,
        averageScore: 78.5,
        medianScore: 80.0,
        dataAsOf: now,
      ),
    ];
  }

  @override
  Future<List<InterventionFollowUpRow>> getInterventionFollowUpReport({
    required String schoolId,
    String? academicYear,
    DateTime? periodStart,
    DateTime? periodEnd,
    String? classroomId,
    String? subjectId,
  }) async {
    final now = DateTime.now().toUtc();
    return [
      InterventionFollowUpRow(
        interventionId: 'interv-01',
        studentId: 'student-almaz',
        studentName: 'Almaz Kebede',
        classroomId: 'class-12-a',
        classroomName: '12-A Natural',
        subjectId: 'physics_g12',
        examVariant: null,
        teacherName: 'Teacher Dawit',
        source: 'p7Attention',
        severityAtCreation: 'high',
        reasonCodes: const ['low_accuracy', 'high_mistakes'],
        actionType: 'targetedPractice',
        status: 'completed',
        createdAt: now.subtract(const Duration(days: 20)),
        completedAt: now.subtract(const Duration(days: 10)),
        baselineAccuracy: 52.0,
        followupAccuracy: 68.0,
        observedChangePp: 16.0,
        evidenceStatus: 'evidence_available',
        evidenceInterpretation:
            'Higher follow-up performance observed; causation not established.',
        dataAsOf: now,
      ),
    ];
  }

  @override
  Future<List<StudentSupportRow>> getStudentSupportReport({
    required String schoolId,
    String? academicYear,
    DateTime? periodStart,
    DateTime? periodEnd,
    String? classroomId,
    String? subjectId,
    String? severity,
  }) async {
    final now = DateTime.now().toUtc();
    return [
      StudentSupportRow(
        studentId: 'student-chala',
        studentName: 'Chala Gemechu',
        classroomId: 'class-12-a',
        classroomName: '12-A Natural',
        subjectId: 'physics_g12',
        severity: 'high',
        attentionReasons: const ['high_mistake_concentration', 'stale_sync'],
        recentAccuracy: 48.0,
        activeMistakes: 14,
        openInterventions: 1,
        dataFreshness: 'moderate',
        dataAsOf: now,
      ),
    ];
  }

  @override
  Future<DataCoverageReport> getDataCoverageReport({
    required String schoolId,
    String? academicYear,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) async {
    final now = DateTime.now().toUtc();
    return DataCoverageReport(
      schoolId: schoolId,
      academicYear: academicYear ?? '2026/27',
      periodStart: periodStart ?? now.subtract(const Duration(days: 90)),
      periodEnd: periodEnd ?? now,
      dataAsOf: now,
      totalActiveStudents: 1200,
      freshSyncCount: 950,
      moderateSyncCount: 150,
      staleSyncCount: 75,
      veryStaleSyncCount: 25,
      freshCoverageRate: 91.67,
      timingUnverifiedCount: 12,
      clockAnomalyCount: 3,
    );
  }

  @override
  Future<StudentAcademicReport> getStudentAcademicReport({
    required String schoolId,
    required String studentId,
    String? academicYear,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) async {
    final now = DateTime.now().toUtc();
    return StudentAcademicReport(
      studentId: studentId,
      studentName: 'Almaz Kebede',
      grade: 12,
      stream: 'natural',
      classroomName: '12-A Natural',
      academicYear: academicYear ?? '2026/27',
      periodStart: periodStart ?? now.subtract(const Duration(days: 90)),
      periodEnd: periodEnd ?? now,
      dataAsOf: now,
      totalAttempts: 24,
      averageScore: 74.2,
      medianScore: 76.0,
      activeMistakes: 6,
      assignmentsAssigned: 8,
      assignmentsCompleted: 7,
      interventionsReceived: 1,
      lastSyncTimestamp: now.subtract(const Duration(hours: 3)),
    );
  }

  @override
  Future<TeacherCoverageReport> getTeacherCoverageReport({
    required String schoolId,
    String? academicYear,
  }) async {
    final now = DateTime.now().toUtc();
    return TeacherCoverageReport(
      schoolId: schoolId,
      academicYear: academicYear ?? '2026/27',
      dataAsOf: now,
      totalClassrooms: 4,
      totalSubjects: 6,
      totalRequiredSlots: 24,
      assignedSlots: 22,
      unassignedSlots: 2,
      coveragePercentage: 91.67,
      slots: const [
        TeacherCoverageSlotRow(
          classroomId: 'c-101',
          classroomName: '12-A Natural',
          grade: 12,
          stream: 'natural',
          subjectId: 'sub-math-nat',
          subjectName: 'Mathematics (Natural)',
          isAssigned: true,
          teacherId: 't-001',
          teacherName: 'Teacher Haile',
        ),
        TeacherCoverageSlotRow(
          classroomId: 'c-101',
          classroomName: '12-A Natural',
          grade: 12,
          stream: 'natural',
          subjectId: 'sub-phy',
          subjectName: 'Physics',
          isAssigned: true,
          teacherId: 't-002',
          teacherName: 'Teacher Sara',
        ),
        TeacherCoverageSlotRow(
          classroomId: 'c-102',
          classroomName: '12-B Social',
          grade: 12,
          stream: 'social',
          subjectId: 'sub-math-soc',
          subjectName: 'Mathematics (Social)',
          isAssigned: false,
        ),
      ],
    );
  }
}
