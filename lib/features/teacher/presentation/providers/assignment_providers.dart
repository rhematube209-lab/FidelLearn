import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/supabase_intervention_repository.dart';
import '../../data/repositories/supabase_student_assignment_repository.dart';
import '../../data/repositories/supabase_teacher_assignment_repository.dart';
import '../../domain/models/assignment_models.dart';
import '../../domain/repositories/intervention_repository.dart';
import '../../domain/repositories/student_assignment_repository.dart';
import '../../domain/repositories/teacher_assignment_repository.dart';

// =============================================================================
// Repositories Providers
// =============================================================================

final teacherAssignmentRepositoryProvider =
    Provider<TeacherAssignmentRepository>((ref) {
  return SupabaseTeacherAssignmentRepository();
});

final studentAssignmentRepositoryProvider =
    Provider<StudentAssignmentRepository>((ref) {
  return SupabaseStudentAssignmentRepository();
});

final interventionRepositoryProvider = Provider<InterventionRepository>((ref) {
  return SupabaseInterventionRepository();
});

// =============================================================================
// Teacher State Providers
// =============================================================================

typedef TeacherAssignmentParams = ({
  String schoolId,
  String? classroomId,
  String? subjectId,
  AssignmentStatus? status,
});

final teacherAssignmentsProvider =
    FutureProvider.family<List<LearningAssignment>, TeacherAssignmentParams>(
        (ref, params) async {
  final repo = ref.watch(teacherAssignmentRepositoryProvider);
  return repo.getTeacherAssignments(
    schoolId: params.schoolId,
    classroomId: params.classroomId,
    subjectId: params.subjectId,
    status: params.status,
  );
});

final assignmentProgressProvider =
    FutureProvider.family<AssignmentProgressSummary, String>(
        (ref, assignmentId) async {
  final repo = ref.watch(teacherAssignmentRepositoryProvider);
  return repo.getAssignmentProgress(assignmentId: assignmentId);
});

// =============================================================================
// Student State Providers
// =============================================================================

final studentAssignmentsProvider =
    FutureProvider.family<List<StudentAssignment>, AssignmentRecipientStatus?>(
        (ref, status) async {
  final repo = ref.watch(studentAssignmentRepositoryProvider);
  return repo.getStudentAssignments(status: status);
});

final studentAssignmentDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>(
        (ref, assignmentId) async {
  final repo = ref.watch(studentAssignmentRepositoryProvider);
  return repo.getAssignmentDetail(assignmentId);
});

// =============================================================================
// Interventions State Providers
// =============================================================================

typedef TeacherInterventionParams = ({
  String schoolId,
  String? classroomId,
  String? subjectId,
  InterventionStatus? status,
});

final teacherInterventionsProvider =
    FutureProvider.family<List<StudentIntervention>, TeacherInterventionParams>(
        (ref, params) async {
  final repo = ref.watch(interventionRepositoryProvider);
  return repo.getTeacherInterventions(
    schoolId: params.schoolId,
    classroomId: params.classroomId,
    subjectId: params.subjectId,
    status: params.status,
  );
});
