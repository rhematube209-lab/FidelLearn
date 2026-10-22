import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env_config.dart';
import '../../../school/presentation/providers/active_school_context_provider.dart';
import '../../data/repositories/local_teacher_portal_repository.dart';
import '../../data/repositories/supabase_teacher_portal_repository.dart';
import '../../domain/models/teacher_portal_models.dart';
import '../../domain/repositories/teacher_portal_repository.dart';

// =============================================================================
// Repository
// =============================================================================

final teacherPortalRepositoryProvider =
    Provider<TeacherPortalRepository>((ref) {
  if (EnvConfig.isProductionLike) {
    if (!EnvConfig.isSupabaseConfigured) {
      throw StateError(
        '[FidelLearn] FATAL: Supabase credentials are required in ${EnvConfig.appEnvironment}. '
        'A ${EnvConfig.appEnvironment} build must not activate LocalTeacherPortalRepository.',
      );
    }
    return SupabaseTeacherPortalRepository();
  }
  if (EnvConfig.isSupabaseConfigured) {
    try {
      return SupabaseTeacherPortalRepository();
    } catch (_) {}
  }
  EnvConfig.assertNoMockInProduction('LocalTeacherPortalRepository');
  return LocalTeacherPortalRepository();
});

// =============================================================================
// Teacher Dashboard Summary
// =============================================================================

/// Loads the teacher's assigned classes for the currently active school.
/// Returns null when:
///   - No active school context
///   - User is not an active teacher in the active school
final teacherAssignedClassesProvider =
    FutureProvider.autoDispose<List<TeacherAssignedClass>>((ref) async {
  final context = ref.watch(activeSchoolContextProvider);
  if (!context.hasActiveSchool || !context.isTeacher) return [];

  final repo = ref.watch(teacherPortalRepositoryProvider);
  return repo.getAssignedClasses(schoolId: context.school!.id);
});

// =============================================================================
// Class-Level Providers
// =============================================================================

/// Roster provider. Paginated.
/// State is a [ClassRosterPage] wrapped in AsyncValue.
/// Use [ClassRosterNotifier.loadNext] to load the next page.
final classRosterProvider = StateNotifierProvider.autoDispose.family<
    ClassRosterNotifier,
    AsyncValue<ClassRosterPage?>,
    ({String classroomId, String subjectId})>(
  (ref, params) {
    final repo = ref.watch(teacherPortalRepositoryProvider);
    return ClassRosterNotifier(repo, params.classroomId, params.subjectId);
  },
);

class ClassRosterNotifier extends StateNotifier<AsyncValue<ClassRosterPage?>> {
  final TeacherPortalRepository _repo;
  final String _classroomId;
  final String _subjectId;
  static const _pageSize = 25;

  ClassRosterNotifier(this._repo, this._classroomId, this._subjectId)
      : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load({String? search}) async {
    state = const AsyncValue.loading();
    try {
      final page = await _repo.getClassRoster(
        classroomId: _classroomId,
        subjectId: _subjectId,
        pageSize: _pageSize,
        offset: 0,
        search: search,
      );
      if (mounted) state = AsyncValue.data(page);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadNext() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore) return;

    try {
      final nextPage = await _repo.getClassRoster(
        classroomId: _classroomId,
        subjectId: _subjectId,
        pageSize: _pageSize,
        offset: current.currentOffset + _pageSize,
      );
      if (mounted) {
        state = AsyncValue.data(ClassRosterPage(
          students: [...current.students, ...nextPage.students],
          totalCount: nextPage.totalCount,
          currentOffset: nextPage.currentOffset,
          pageSize: nextPage.pageSize,
        ));
      }
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }
}

/// Class weak topics.
final classWeakTopicsProvider = FutureProvider.autoDispose
    .family<List<ClassWeakTopic>, ({String classroomId, String subjectId})>(
  (ref, params) async {
    final repo = ref.watch(teacherPortalRepositoryProvider);
    return repo.getClassWeakTopics(
      classroomId: params.classroomId,
      subjectId: params.subjectId,
    );
  },
);

/// Class exam summaries.
final classExamSummaryProvider = FutureProvider.autoDispose
    .family<List<ClassExamSummary>, ({String classroomId, String subjectId})>(
  (ref, params) async {
    final repo = ref.watch(teacherPortalRepositoryProvider);
    return repo.getClassExamSummary(
      classroomId: params.classroomId,
      subjectId: params.subjectId,
    );
  },
);

/// Attention students (paginated notifier).
final attentionStudentsProvider = StateNotifierProvider.autoDispose.family<
    AttentionStudentsNotifier,
    AsyncValue<AttentionPage?>,
    ({String classroomId, String subjectId})>(
  (ref, params) {
    final repo = ref.watch(teacherPortalRepositoryProvider);
    return AttentionStudentsNotifier(
        repo, params.classroomId, params.subjectId);
  },
);

class AttentionStudentsNotifier
    extends StateNotifier<AsyncValue<AttentionPage?>> {
  final TeacherPortalRepository _repo;
  final String _classroomId;
  final String _subjectId;
  static const _pageSize = 20;

  AttentionStudentsNotifier(this._repo, this._classroomId, this._subjectId)
      : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final page = await _repo.getAttentionStudents(
        classroomId: _classroomId,
        subjectId: _subjectId,
        pageSize: _pageSize,
        offset: 0,
      );
      if (mounted) state = AsyncValue.data(page);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadNext() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore) return;

    try {
      final nextPage = await _repo.getAttentionStudents(
        classroomId: _classroomId,
        subjectId: _subjectId,
        pageSize: _pageSize,
        offset: current.currentOffset + _pageSize,
      );
      if (mounted) {
        state = AsyncValue.data(AttentionPage(
          items: [...current.items, ...nextPage.items],
          totalCount: nextPage.totalCount,
          currentOffset: nextPage.currentOffset,
          pageSize: nextPage.pageSize,
        ));
      }
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }
}

// =============================================================================
// Student Summary Provider
// =============================================================================

final studentAcademicSummaryProvider = FutureProvider.autoDispose.family<
    StudentAcademicSummary?,
    ({
      String studentId,
      String classroomId,
      String subjectId,
      String subjectName
    })>(
  (ref, params) async {
    final repo = ref.watch(teacherPortalRepositoryProvider);
    return repo.getStudentSummary(
      studentId: params.studentId,
      classroomId: params.classroomId,
      subjectId: params.subjectId,
      subjectName: params.subjectName,
    );
  },
);
