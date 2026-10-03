import '../../domain/models/school_leadership_models.dart';
import '../../domain/repositories/school_leadership_repository.dart';
import '../../../teacher/domain/models/teacher_portal_models.dart';

/// Local offline / mock implementation of [SchoolLeadershipRepository].
///
/// Used for offline testing, local unit tests, and demo verification.
class LocalSchoolLeadershipRepository implements SchoolLeadershipRepository {
  final String mockSchoolId;

  LocalSchoolLeadershipRepository({
    this.mockSchoolId = 'sch_bole_1',
  });

  @override
  Future<SchoolLeadershipSummary> getLeadershipSummary({
    required String schoolId,
    String? academicYear,
  }) async {
    return SchoolLeadershipSummary(
      schoolId: schoolId,
      schoolName: 'Bole Senior Secondary School',
      academicYear: academicYear ?? '2026/27',
      totalActiveStudents: 840,
      naturalStreamStudents: 480,
      socialStreamStudents: 360,
      totalActiveTeachers: 42,
      totalActiveClassrooms: 16,
      recentSimulationCount: 12,
      recentSimulationAvgPct: 68.4,
      recentSimulationMedianPct: 70.0,
      simulationParticipationRate: 0.82,
      uniqueStudentsNeedingHelp: 48,
      highSeverityStudentCount: 14,
      staleSyncStudentCount: 28,
      topWeakSubjectName: 'Physics',
      topWeakSubjectMistakes: 142,
      teacherAssignmentCoverage: 0.94,
      unassignedSubjectSlots: 3,
      freshDataCoverageRate: 0.85,
    );
  }

  @override
  Future<List<SchoolStreamSummary>> getStreamSummary({
    required String schoolId,
    String? academicYear,
  }) async {
    return const [
      SchoolStreamSummary(
        stream: 'naturalScience',
        streamLabel: 'Natural Science',
        enrolledStudents: 480,
        activeClassrooms: 9,
        recentSimulationAvgPct: 71.2,
        recentSimulationMedianPct: 72.0,
        simulationParticipationRate: 0.86,
        activeMistakeCount: 310,
        freshDataCoverageRate: 0.88,
      ),
      SchoolStreamSummary(
        stream: 'socialScience',
        streamLabel: 'Social Science',
        enrolledStudents: 360,
        activeClassrooms: 7,
        recentSimulationAvgPct: 64.8,
        recentSimulationMedianPct: 66.0,
        simulationParticipationRate: 0.77,
        activeMistakeCount: 245,
        freshDataCoverageRate: 0.81,
      ),
    ];
  }

  @override
  Future<List<SchoolSubjectSummary>> getSubjectSummary({
    required String schoolId,
    String? academicYear,
    String? stream,
  }) async {
    final all = [
      const SchoolSubjectSummary(
        subjectId: 'math_g12',
        subjectName: 'Mathematics',
        examVariant: 'naturalScience',
        displayName: 'Mathematics — Natural Science',
        stream: 'naturalScience',
        enrolledStudentCount: 480,
        attemptCount: 920,
        participantCount: 420,
        participationRate: 0.88,
        avgPercentage: 66.5,
        medianPercentage: 68.0,
        activeMistakeCount: 184,
        affectedStudentCount: 62,
        teacherAssignedCount: 4,
        hasTeacherCoverage: true,
      ),
      const SchoolSubjectSummary(
        subjectId: 'math_g12',
        subjectName: 'Mathematics',
        examVariant: 'socialScience',
        displayName: 'Mathematics — Social Science',
        stream: 'socialScience',
        enrolledStudentCount: 360,
        attemptCount: 610,
        participantCount: 290,
        participationRate: 0.81,
        avgPercentage: 58.2,
        medianPercentage: 60.0,
        activeMistakeCount: 156,
        affectedStudentCount: 54,
        teacherAssignedCount: 3,
        hasTeacherCoverage: true,
      ),
      const SchoolSubjectSummary(
        subjectId: 'physics_g12',
        subjectName: 'Physics',
        displayName: 'Physics',
        stream: 'naturalScience',
        enrolledStudentCount: 480,
        attemptCount: 840,
        participantCount: 395,
        participationRate: 0.82,
        avgPercentage: 62.4,
        medianPercentage: 64.0,
        activeMistakeCount: 198,
        affectedStudentCount: 74,
        teacherAssignedCount: 4,
        hasTeacherCoverage: true,
      ),
      const SchoolSubjectSummary(
        subjectId: 'chemistry_g12',
        subjectName: 'Chemistry',
        displayName: 'Chemistry',
        stream: 'naturalScience',
        enrolledStudentCount: 480,
        attemptCount: 780,
        participantCount: 380,
        participationRate: 0.79,
        avgPercentage: 65.0,
        medianPercentage: 66.0,
        activeMistakeCount: 142,
        affectedStudentCount: 48,
        teacherAssignedCount: 3,
        hasTeacherCoverage: true,
      ),
      const SchoolSubjectSummary(
        subjectId: 'biology_g12',
        subjectName: 'Biology',
        displayName: 'Biology',
        stream: 'naturalScience',
        enrolledStudentCount: 480,
        attemptCount: 810,
        participantCount: 405,
        participationRate: 0.84,
        avgPercentage: 74.2,
        medianPercentage: 76.0,
        activeMistakeCount: 96,
        affectedStudentCount: 32,
        teacherAssignedCount: 4,
        hasTeacherCoverage: true,
      ),
      const SchoolSubjectSummary(
        subjectId: 'english_g12',
        subjectName: 'English',
        displayName: 'English',
        stream: 'common',
        enrolledStudentCount: 840,
        attemptCount: 1540,
        participantCount: 710,
        participationRate: 0.85,
        avgPercentage: 72.8,
        medianPercentage: 74.0,
        activeMistakeCount: 130,
        affectedStudentCount: 52,
        teacherAssignedCount: 6,
        hasTeacherCoverage: true,
      ),
      const SchoolSubjectSummary(
        subjectId: 'aptitude_g12',
        subjectName: 'Scholastic Aptitude',
        displayName: 'Scholastic Aptitude',
        stream: 'common',
        enrolledStudentCount: 840,
        attemptCount: 1420,
        participantCount: 680,
        participationRate: 0.81,
        avgPercentage: 69.4,
        medianPercentage: 70.0,
        activeMistakeCount: 172,
        affectedStudentCount: 68,
        teacherAssignedCount: 4,
        hasTeacherCoverage: true,
      ),
      const SchoolSubjectSummary(
        subjectId: 'economics_g12',
        subjectName: 'Economics',
        displayName: 'Economics',
        stream: 'socialScience',
        enrolledStudentCount: 360,
        attemptCount: 580,
        participantCount: 285,
        participationRate: 0.79,
        avgPercentage: 67.2,
        medianPercentage: 68.0,
        activeMistakeCount: 110,
        affectedStudentCount: 38,
        teacherAssignedCount: 2,
        hasTeacherCoverage: true,
      ),
      const SchoolSubjectSummary(
        subjectId: 'history_g12',
        subjectName: 'History',
        displayName: 'History',
        stream: 'socialScience',
        enrolledStudentCount: 360,
        attemptCount: 600,
        participantCount: 295,
        participationRate: 0.82,
        avgPercentage: 70.1,
        medianPercentage: 72.0,
        activeMistakeCount: 88,
        affectedStudentCount: 30,
        teacherAssignedCount: 3,
        hasTeacherCoverage: true,
      ),
      const SchoolSubjectSummary(
        subjectId: 'geography_g12',
        subjectName: 'Geography',
        displayName: 'Geography',
        stream: 'socialScience',
        enrolledStudentCount: 360,
        attemptCount: 570,
        participantCount: 280,
        participationRate: 0.78,
        avgPercentage: 68.5,
        medianPercentage: 70.0,
        activeMistakeCount: 104,
        affectedStudentCount: 36,
        teacherAssignedCount: 2,
        hasTeacherCoverage: true,
      ),
    ];

    if (stream != null && stream.isNotEmpty) {
      return all
          .where((s) => s.stream == stream || s.stream == 'common')
          .toList();
    }
    return all;
  }

  @override
  Future<List<SchoolClassSummary>> getClassSummary({
    required String schoolId,
    String? academicYear,
    String? stream,
    String? subjectId,
  }) async {
    final classes = [
      const SchoolClassSummary(
        classroomId: 'c_nat_a',
        classroomName: 'Grade 12 Natural A',
        grade: 12,
        stream: 'naturalScience',
        section: 'A',
        enrolledStudents: 54,
        recentAttemptCount: 160,
        participantCount: 48,
        participationRate: 0.89,
        avgPercentage: 74.2,
        medianPercentage: 76.0,
        activeMistakeCount: 24,
        assignedTeacherCount: 6,
        freshDataCoverageRate: 0.92,
      ),
      const SchoolClassSummary(
        classroomId: 'c_nat_b',
        classroomName: 'Grade 12 Natural B',
        grade: 12,
        stream: 'naturalScience',
        section: 'B',
        enrolledStudents: 52,
        recentAttemptCount: 110,
        participantCount: 34,
        participationRate: 0.65,
        avgPercentage: 59.8,
        medianPercentage: 60.0,
        activeMistakeCount: 68,
        assignedTeacherCount: 5,
        freshDataCoverageRate: 0.74,
      ),
      const SchoolClassSummary(
        classroomId: 'c_nat_c',
        classroomName: 'Grade 12 Natural C',
        grade: 12,
        stream: 'naturalScience',
        section: 'C',
        enrolledStudents: 55,
        recentAttemptCount: 145,
        participantCount: 46,
        participationRate: 0.84,
        avgPercentage: 68.0,
        medianPercentage: 70.0,
        activeMistakeCount: 38,
        assignedTeacherCount: 6,
        freshDataCoverageRate: 0.86,
      ),
      const SchoolClassSummary(
        classroomId: 'c_soc_a',
        classroomName: 'Grade 12 Social A',
        grade: 12,
        stream: 'socialScience',
        section: 'A',
        enrolledStudents: 50,
        recentAttemptCount: 130,
        participantCount: 42,
        participationRate: 0.84,
        avgPercentage: 69.5,
        medianPercentage: 71.0,
        activeMistakeCount: 32,
        assignedTeacherCount: 5,
        freshDataCoverageRate: 0.88,
      ),
      const SchoolClassSummary(
        classroomId: 'c_soc_b',
        classroomName: 'Grade 12 Social B',
        grade: 12,
        stream: 'socialScience',
        section: 'B',
        enrolledStudents: 51,
        recentAttemptCount: 95,
        participantCount: 31,
        participationRate: 0.61,
        avgPercentage: 56.4,
        medianPercentage: 58.0,
        activeMistakeCount: 62,
        assignedTeacherCount: 5,
        freshDataCoverageRate: 0.70,
      ),
    ];

    if (stream != null && stream.isNotEmpty) {
      return classes.where((c) => c.stream == stream).toList();
    }
    return classes;
  }

  @override
  Future<List<SchoolSystemicWeakTopic>> getSystemicWeakTopics({
    required String schoolId,
    String? academicYear,
    String? subjectId,
    int limit = 10,
  }) async {
    final list = [
      const SchoolSystemicWeakTopic(
        topicId: 'top_phys_elec',
        topicNameEn: 'Electric Circuits & Alternating Current',
        unitId: 'u_phys_3',
        unitNameEn: 'Electromagnetism',
        subjectId: 'physics_g12',
        subjectName: 'Physics',
        affectedStudentCount: 78,
        activeMistakeCount: 184,
      ),
      const SchoolSystemicWeakTopic(
        topicId: 'top_math_calc',
        topicNameEn: 'Integral Calculus & Area Under Curve',
        unitId: 'u_math_4',
        unitNameEn: 'Calculus',
        subjectId: 'math_g12',
        subjectName: 'Mathematics',
        affectedStudentCount: 71,
        activeMistakeCount: 162,
      ),
      const SchoolSystemicWeakTopic(
        topicId: 'top_chem_equil',
        topicNameEn: 'Chemical Equilibrium & Le Chatelier Principle',
        unitId: 'u_chem_2',
        unitNameEn: 'Physical Chemistry',
        subjectId: 'chemistry_g12',
        subjectName: 'Chemistry',
        affectedStudentCount: 56,
        activeMistakeCount: 128,
      ),
      const SchoolSystemicWeakTopic(
        topicId: 'top_econ_macro',
        topicNameEn: 'Fiscal Policy & Aggregate Demand',
        unitId: 'u_econ_3',
        unitNameEn: 'Macroeconomics',
        subjectId: 'economics_g12',
        subjectName: 'Economics',
        affectedStudentCount: 44,
        activeMistakeCount: 96,
      ),
      const SchoolSystemicWeakTopic(
        topicId: 'top_apt_quan',
        topicNameEn: 'Quantitative Data Interpretation & Ratios',
        unitId: 'u_apt_2',
        unitNameEn: 'Quantitative Reasoning',
        subjectId: 'aptitude_g12',
        subjectName: 'Scholastic Aptitude',
        affectedStudentCount: 42,
        activeMistakeCount: 88,
      ),
    ];

    if (subjectId != null && subjectId.isNotEmpty) {
      return list.where((t) => t.subjectId == subjectId).take(limit).toList();
    }
    return list.take(limit).toList();
  }

  @override
  Future<List<SchoolSupportStudent>> getSupportPopulation({
    required String schoolId,
    String? academicYear,
    String? severity,
    int limit = 25,
    int offset = 0,
  }) async {
    final students = [
      SchoolSupportStudent(
        userId: 'stu_nat_b_01',
        displayName: 'Eyerusalem Haile',
        schoolStudentId: 'STU-BOL-204',
        classroomName: 'Grade 12 Natural B',
        stream: 'naturalScience',
        recentAccuracyPercentage: 42.5,
        activeMistakeCount: 8,
        recentAttemptCount: 3,
        lastActivityAt: DateTime.now().subtract(const Duration(days: 3)),
        lastSyncedAt: DateTime.now().subtract(const Duration(days: 3)),
        syncFreshness: 'moderate',
        severity: AttentionSeverity.high,
        reasonCodes: const [
          AttentionReasonCode.highMistakeCount,
          AttentionReasonCode.lowRecentAccuracy,
        ],
        totalCount: 4,
      ),
      SchoolSupportStudent(
        userId: 'stu_soc_b_02',
        displayName: 'Kidus Tadesse',
        schoolStudentId: 'STU-BOL-311',
        classroomName: 'Grade 12 Social B',
        stream: 'socialScience',
        recentAccuracyPercentage: 46.0,
        activeMistakeCount: 6,
        recentAttemptCount: 2,
        lastActivityAt: DateTime.now().subtract(const Duration(days: 4)),
        lastSyncedAt: DateTime.now().subtract(const Duration(days: 4)),
        syncFreshness: 'moderate',
        severity: AttentionSeverity.high,
        reasonCodes: const [
          AttentionReasonCode.highMistakeCount,
          AttentionReasonCode.lowRecentAccuracy,
        ],
        totalCount: 4,
      ),
      SchoolSupportStudent(
        userId: 'stu_nat_b_03',
        displayName: 'Yosef Bekele',
        schoolStudentId: 'STU-BOL-219',
        classroomName: 'Grade 12 Natural B',
        stream: 'naturalScience',
        recentAccuracyPercentage: 56.0,
        activeMistakeCount: 4,
        recentAttemptCount: 4,
        lastActivityAt: DateTime.now().subtract(const Duration(days: 16)),
        lastSyncedAt: DateTime.now().subtract(const Duration(days: 16)),
        syncFreshness: 'very_stale',
        severity: AttentionSeverity.medium,
        reasonCodes: const [
          AttentionReasonCode.elevatedMistakeCount,
          AttentionReasonCode.noRecentActivity,
        ],
        totalCount: 4,
      ),
      const SchoolSupportStudent(
        userId: 'stu_soc_b_04',
        displayName: 'Genet Alemu',
        schoolStudentId: 'STU-BOL-340',
        classroomName: 'Grade 12 Social B',
        stream: 'socialScience',
        recentAccuracyPercentage: null,
        activeMistakeCount: 0,
        recentAttemptCount: 0,
        lastActivityAt: null,
        lastSyncedAt: null,
        syncFreshness: 'unknown',
        severity: AttentionSeverity.low,
        reasonCodes: [
          AttentionReasonCode.noPracticeData,
        ],
        totalCount: 4,
      ),
    ];

    if (severity != null && severity.isNotEmpty) {
      return students
          .where((s) => s.severity.name.toLowerCase() == severity.toLowerCase())
          .skip(offset)
          .take(limit)
          .toList();
    }
    return students.skip(offset).take(limit).toList();
  }

  @override
  Future<List<SchoolAssessmentSummary>> getAssessmentsOverview({
    required String schoolId,
    String? academicYear,
    int limit = 15,
  }) async {
    return [
      SchoolAssessmentSummary(
        examId: 'sim_phys_2026',
        examTitle: '2026 National ESSLCE Simulation — Physics',
        subjectId: 'physics_g12',
        subjectName: 'Physics',
        examType: 'mock_full',
        examMode: 'nationalSimulation',
        sourceType: 'generatedSimulation',
        totalQuestions: 50,
        participantCount: 395,
        eligibleCount: 480,
        participationPct: 82.3,
        avgPercentage: 62.4,
        medianPercentage: 64.0,
        latestAttemptAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      SchoolAssessmentSummary(
        examId: 'sim_math_nat_2026',
        examTitle: '2026 National ESSLCE Simulation — Mathematics (Natural)',
        subjectId: 'math_g12',
        subjectName: 'Mathematics',
        examType: 'mock_full',
        examMode: 'nationalSimulation',
        sourceType: 'generatedSimulation',
        totalQuestions: 65,
        participantCount: 420,
        eligibleCount: 480,
        participationPct: 87.5,
        avgPercentage: 66.5,
        medianPercentage: 68.0,
        latestAttemptAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
      SchoolAssessmentSummary(
        examId: 'hist_paper_2014_chem',
        examTitle: '2014 E.C. Ministry Official Past Paper — Chemistry',
        subjectId: 'chemistry_g12',
        subjectName: 'Chemistry',
        examType: 'mock_full',
        examMode: 'historicalPaper',
        sourceType: 'officialHistoricalPaper',
        totalQuestions: 60,
        participantCount: 360,
        eligibleCount: 480,
        participationPct: 75.0,
        avgPercentage: 68.2,
        medianPercentage: 70.0,
        latestAttemptAt: DateTime.now().subtract(const Duration(days: 8)),
      ),
      SchoolAssessmentSummary(
        examId: 'sim_econ_2026',
        examTitle: '2026 National ESSLCE Simulation — Economics',
        subjectId: 'economics_g12',
        subjectName: 'Economics',
        examType: 'mock_full',
        examMode: 'nationalSimulation',
        sourceType: 'generatedSimulation',
        totalQuestions: 50,
        participantCount: 285,
        eligibleCount: 360,
        participationPct: 79.2,
        avgPercentage: 67.2,
        medianPercentage: 68.0,
        latestAttemptAt: DateTime.now().subtract(const Duration(days: 6)),
      ),
    ].take(limit).toList();
  }

  @override
  Future<List<SchoolTeacherCoverageSlot>> getTeacherCoverage({
    required String schoolId,
    String? academicYear,
  }) async {
    return const [
      SchoolTeacherCoverageSlot(
        classroomId: 'c_nat_a',
        classroomName: 'Grade 12 Natural A',
        grade: 12,
        stream: 'naturalScience',
        section: 'A',
        subjectId: 'physics_g12',
        subjectName: 'Physics',
        examVariant: 'naturalScience',
        teacherUserId: 't_phys_01',
        teacherName: 'Abebe Kebede',
        isAssigned: true,
      ),
      SchoolTeacherCoverageSlot(
        classroomId: 'c_nat_a',
        classroomName: 'Grade 12 Natural A',
        grade: 12,
        stream: 'naturalScience',
        section: 'A',
        subjectId: 'math_g12',
        subjectName: 'Mathematics',
        examVariant: 'naturalScience',
        teacherUserId: 't_math_01',
        teacherName: 'Selamawit Tilahun',
        isAssigned: true,
      ),
      SchoolTeacherCoverageSlot(
        classroomId: 'c_nat_b',
        classroomName: 'Grade 12 Natural B',
        grade: 12,
        stream: 'naturalScience',
        section: 'B',
        subjectId: 'chemistry_g12',
        subjectName: 'Chemistry',
        teacherUserId: null,
        teacherName: null,
        isAssigned: false,
      ),
      SchoolTeacherCoverageSlot(
        classroomId: 'c_soc_b',
        classroomName: 'Grade 12 Social B',
        grade: 12,
        stream: 'socialScience',
        section: 'B',
        subjectId: 'economics_g12',
        subjectName: 'Economics',
        teacherUserId: null,
        teacherName: null,
        isAssigned: false,
      ),
    ];
  }

  @override
  Future<SchoolStudentAcademicDetail> getStudentAcademicSummary({
    required String schoolId,
    required String studentId,
  }) async {
    return SchoolStudentAcademicDetail(
      studentId: studentId,
      displayName: 'Eyerusalem Haile',
      schoolStudentId: 'STU-BOL-204',
      classroomName: 'Grade 12 Natural B',
      grade: 12,
      stream: 'naturalScience',
      totalAttempts: 14,
      recentAvgPercentage: 42.5,
      overallAccuracyPct: 48.0,
      lastActivityAt: DateTime.now().subtract(const Duration(days: 3)),
      lastSyncedAt: DateTime.now().subtract(const Duration(days: 3)),
      syncFreshness: 'moderate',
      totalMistakes: 12,
      masteredMistakes: 4,
      weakTopics: const [
        ClassWeakTopic(
          topicId: 'top_phys_elec',
          topicName: 'Electric Circuits',
          unitId: 'u_phys_3',
          unitName: 'Electromagnetism',
          affectedStudentCount: 1,
          activeMistakeCount: 5,
        ),
      ],
      recentExams: [
        StudentExamResult(
          examId: 'sim_phys_2026',
          examTitle: 'Physics National Simulation 2026',
          examType: 'mock_full',
          examMode: 'nationalSimulation',
          sourceType: 'generatedSimulation',
          totalQuestions: 50,
          percentage: 42.0,
          completedAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
      ],
      masteryAvailabilityNote:
          'Mastery data (P4 fidel_spaced_v1.0) and national exam readiness are device-local to the student phone. Institutional summaries reflect cloud-synced attempts and mistake records only.',
    );
  }
}
