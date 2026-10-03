import '../../domain/models/teacher_portal_models.dart';
import '../../domain/repositories/teacher_portal_repository.dart';
import '../../../school/domain/models/tenant_models.dart';

/// Offline / test mock implementation of [TeacherPortalRepository].
///
/// Returns plausible seed data matching real schema shapes.
/// Used when Supabase is not configured (offline, CI, unit tests).
///
/// Security note: this implementation does NOT enforce authorization.
/// Authorization is only enforced by [SupabaseTeacherPortalRepository].
class LocalTeacherPortalRepository implements TeacherPortalRepository {
  static final _now = DateTime.now();

  static final _mockClassroomA = Classroom(
    id: 'cls_12A',
    schoolId: '11111111-1111-1111-1111-111111111111',
    name: 'Grade 12 Natural — Section A',
    grade: 12,
    stream: 'naturalScience',
    section: 'A',
    academicYear: '2026/27',
    studentCount: 44,
    createdAt: _now.subtract(const Duration(days: 180)),
    updatedAt: _now.subtract(const Duration(days: 1)),
  );

  static final _mockClassroomB = Classroom(
    id: 'cls_12B',
    schoolId: '11111111-1111-1111-1111-111111111111',
    name: 'Grade 12 Natural — Section B',
    grade: 12,
    stream: 'naturalScience',
    section: 'B',
    academicYear: '2026/27',
    studentCount: 38,
    createdAt: _now.subtract(const Duration(days: 180)),
    updatedAt: _now.subtract(const Duration(days: 1)),
  );

  @override
  Future<List<TeacherAssignedClass>> getAssignedClasses({
    required String schoolId,
  }) async {
    return [
      TeacherAssignedClass(
        assignmentId: 'tsa_physics_A',
        classroom: _mockClassroomA,
        subjectId: 'physics_g12',
        subjectName: 'Physics',
        examVariant: 'naturalScience',
        enrolledStudentCount: 44,
        attentionCount: 8,
        recentExamAvgPercentage: 63.4,
        activeMistakeCount: 142,
      ),
      TeacherAssignedClass(
        assignmentId: 'tsa_physics_B',
        classroom: _mockClassroomB,
        subjectId: 'physics_g12',
        subjectName: 'Physics',
        examVariant: 'naturalScience',
        enrolledStudentCount: 38,
        attentionCount: 5,
        recentExamAvgPercentage: 71.2,
        activeMistakeCount: 89,
      ),
    ];
  }

  @override
  Future<ClassRosterPage> getClassRoster({
    required String classroomId,
    required String subjectId,
    int pageSize = 25,
    int offset = 0,
    String? search,
  }) async {
    final allStudents = List.generate(44, (i) {
      final idx = i + 1;
      return ClassRosterStudent(
        userId: 'student_$idx',
        displayName: _mockNames[i % _mockNames.length],
        schoolStudentId: 'STU${(1000 + idx).toString()}',
        recentAttemptCount: (idx % 5 == 0) ? 0 : (idx % 8) + 1,
        recentAvgPercentage: (idx % 5 == 0) ? null : 40.0 + (idx % 40),
        activeMistakeCount: idx % 7,
        lastActivityAt: (idx % 5 == 0)
            ? _now.subtract(Duration(days: 18 + idx))
            : _now.subtract(Duration(days: idx % 10)),
      );
    });

    var filtered = search != null && search.isNotEmpty
        ? allStudents
            .where((s) =>
                s.displayName.toLowerCase().contains(search.toLowerCase()) ||
                (s.schoolStudentId?.contains(search) ?? false))
            .toList()
        : allStudents;

    final total = filtered.length;
    final page = filtered.skip(offset).take(pageSize).toList();
    return ClassRosterPage(
      students: page,
      totalCount: total,
      currentOffset: offset,
      pageSize: pageSize,
    );
  }

  @override
  Future<List<ClassWeakTopic>> getClassWeakTopics({
    required String classroomId,
    required String subjectId,
    int limit = 10,
  }) async {
    return [
      const ClassWeakTopic(
        topicId: 'phys_electricity',
        topicName: 'Electricity & Circuits',
        unitId: 'phys_unit4',
        unitName: 'Unit 4: Electromagnetism',
        affectedStudentCount: 18,
        activeMistakeCount: 72,
      ),
      const ClassWeakTopic(
        topicId: 'phys_optics',
        topicName: 'Geometrical Optics',
        unitId: 'phys_unit5',
        unitName: 'Unit 5: Light & Optics',
        affectedStudentCount: 12,
        activeMistakeCount: 41,
      ),
      const ClassWeakTopic(
        topicId: 'phys_waves',
        topicName: 'Wave Motion',
        unitId: 'phys_unit3',
        unitName: 'Unit 3: Waves',
        affectedStudentCount: 9,
        activeMistakeCount: 28,
      ),
      const ClassWeakTopic(
        topicId: 'phys_mechanics',
        topicName: 'Newton\'s Laws of Motion',
        unitId: 'phys_unit1',
        unitName: 'Unit 1: Mechanics',
        affectedStudentCount: 4,
        activeMistakeCount: 11,
      ),
    ].take(limit).toList();
  }

  @override
  Future<List<ClassExamSummary>> getClassExamSummary({
    required String classroomId,
    required String subjectId,
    int limit = 5,
  }) async {
    return [
      ClassExamSummary(
        examId: 'exam_mock_sep18',
        examTitle: 'Physics Simulation — Sep 18',
        examType: 'mock_full',
        totalQuestions: 32,
        participantCount: 38,
        enrolledCount: 44,
        avgPercentage: 67.4,
        medianPercentage: 69.0,
        notSubmitted: 6,
        examCreatedAt: _now.subtract(const Duration(days: 7)),
      ),
      ClassExamSummary(
        examId: 'exam_unit4_sep10',
        examTitle: 'Unit 4: Electromagnetism Test',
        examType: 'unit_test',
        totalQuestions: 20,
        participantCount: 42,
        enrolledCount: 44,
        avgPercentage: 58.2,
        medianPercentage: 57.5,
        notSubmitted: 2,
        examCreatedAt: _now.subtract(const Duration(days: 15)),
      ),
      ClassExamSummary(
        examId: 'exam_practice_aug28',
        examTitle: 'Mechanics Practice',
        examType: 'practice',
        totalQuestions: 15,
        participantCount: 44,
        enrolledCount: 44,
        avgPercentage: 76.1,
        medianPercentage: 78.0,
        notSubmitted: 0,
        examCreatedAt: _now.subtract(const Duration(days: 28)),
      ),
    ].take(limit).toList();
  }

  @override
  Future<AttentionPage> getAttentionStudents({
    required String classroomId,
    required String subjectId,
    int pageSize = 20,
    int offset = 0,
  }) async {
    final items = [
      StudentAttentionItem(
        studentId: 'student_3',
        studentName: 'Almaz Tesfaye',
        schoolStudentId: 'STU1003',
        subjectId: subjectId,
        severity: AttentionSeverity.high,
        reasonCodes: const [
          AttentionReasonCode.lowRecentAccuracy,
          AttentionReasonCode.highMistakeCount,
        ],
        recentAccuracyPercentage: 41.0,
        activeMistakeCount: 7,
        recentAttemptCount: 3,
        lastActivityAt: _now.subtract(const Duration(days: 4)),
      ),
      StudentAttentionItem(
        studentId: 'student_11',
        studentName: 'Biruk Hailu',
        schoolStudentId: 'STU1011',
        subjectId: subjectId,
        severity: AttentionSeverity.high,
        reasonCodes: const [
          AttentionReasonCode.lowRecentAccuracy,
          AttentionReasonCode.elevatedMistakeCount,
        ],
        recentAccuracyPercentage: 48.5,
        activeMistakeCount: 5,
        recentAttemptCount: 2,
        lastActivityAt: _now.subtract(const Duration(days: 6)),
      ),
      StudentAttentionItem(
        studentId: 'student_7',
        studentName: 'Mekdes Girma',
        schoolStudentId: 'STU1007',
        subjectId: subjectId,
        severity: AttentionSeverity.medium,
        reasonCodes: const [
          AttentionReasonCode.borderlineAccuracy,
          AttentionReasonCode.elevatedMistakeCount,
        ],
        recentAccuracyPercentage: 62.0,
        activeMistakeCount: 4,
        recentAttemptCount: 5,
        lastActivityAt: _now.subtract(const Duration(days: 3)),
      ),
      StudentAttentionItem(
        studentId: 'student_19',
        studentName: 'Dawit Solomon',
        schoolStudentId: 'STU1019',
        subjectId: subjectId,
        severity: AttentionSeverity.medium,
        reasonCodes: const [AttentionReasonCode.noRecentActivity],
        recentAccuracyPercentage: null,
        activeMistakeCount: 2,
        recentAttemptCount: 0,
        lastActivityAt: _now.subtract(const Duration(days: 19)),
      ),
      StudentAttentionItem(
        studentId: 'student_23',
        studentName: 'Tigist Alemu',
        schoolStudentId: 'STU1023',
        subjectId: subjectId,
        severity: AttentionSeverity.low,
        reasonCodes: const [AttentionReasonCode.elevatedMistakeCount],
        recentAccuracyPercentage: 74.0,
        activeMistakeCount: 3,
        recentAttemptCount: 7,
        lastActivityAt: _now.subtract(const Duration(days: 2)),
      ),
    ];

    final paginated = items.skip(offset).take(pageSize).toList();
    return AttentionPage(
      items: paginated,
      totalCount: items.length,
      currentOffset: offset,
      pageSize: pageSize,
    );
  }

  @override
  Future<StudentAcademicSummary?> getStudentSummary({
    required String studentId,
    required String classroomId,
    required String subjectId,
    required String subjectName,
  }) async {
    return StudentAcademicSummary(
      studentId: studentId,
      displayName: 'Almaz Tesfaye',
      schoolStudentId: 'STU1003',
      subjectId: subjectId,
      subjectName: subjectName,
      totalAttempts: 12,
      recentAvgPercentage: 41.0,
      overallAccuracyPercentage: 54.3,
      lastActivityAt: _now.subtract(const Duration(days: 4)),
      totalMistakes: 14,
      masteredMistakes: 7,
      weakTopics: const [
        ClassWeakTopic(
          topicId: 'phys_electricity',
          topicName: 'Electricity & Circuits',
          unitName: 'Unit 4: Electromagnetism',
          affectedStudentCount: 1,
          activeMistakeCount: 5,
        ),
        ClassWeakTopic(
          topicId: 'phys_optics',
          topicName: 'Geometrical Optics',
          unitName: 'Unit 5: Light & Optics',
          affectedStudentCount: 1,
          activeMistakeCount: 2,
        ),
      ],
      recentExams: [
        StudentExamResult(
          examId: 'exam_mock_sep18',
          examTitle: 'Physics Simulation — Sep 18',
          examType: 'mock_full',
          totalQuestions: 32,
          percentage: 41.0,
          completedAt: _now.subtract(const Duration(days: 4)),
        ),
        StudentExamResult(
          examId: 'exam_unit4_sep10',
          examTitle: 'Unit 4: Electromagnetism Test',
          examType: 'unit_test',
          totalQuestions: 20,
          percentage: 45.0,
          completedAt: _now.subtract(const Duration(days: 15)),
        ),
      ],
    );
  }

  static const _mockNames = [
    'Abebe Bekele',
    'Almaz Tesfaye',
    'Biruk Hailu',
    'Chaltu Gemechu',
    'Dawit Solomon',
    'Eden Tadesse',
    'Fikru Alemu',
    'Genet Yonas',
    'Henok Girma',
    'Iman Hassan',
    'Jonas Kifle',
    'Kaleb Mekonen',
    'Liya Habtamu',
    'Mekdes Girma',
    'Naod Tekeste',
    'Obsa Fayisa',
    'Priya Girma',
    'Rediet Asefa',
    'Saron Berhe',
    'Tigist Alemu',
    'Urael Teshome',
    'Vivian Bekele',
    'Wondwosen Lema',
    'Yemisi Alemu',
    'Zewditu Tadesse',
  ];
}
