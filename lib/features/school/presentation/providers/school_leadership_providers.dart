import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env_config.dart';
import '../../data/repositories/local_school_leadership_repository.dart';
import '../../data/repositories/supabase_school_leadership_repository.dart';
export '../../data/repositories/supabase_school_leadership_repository.dart'
    show
        SchoolLeadershipAuthorizationException,
        SchoolLeadershipOfflineException;
import '../../domain/models/school_leadership_models.dart';
import '../../domain/repositories/school_leadership_repository.dart';
import 'active_school_context_provider.dart';

// =============================================================================
// FidelLearn — P8 School Leadership Providers
// Secure, tenant-keyed, auto-disposing providers for School Leadership Dashboard.
// =============================================================================

/// Global provider for [SchoolLeadershipRepository].
///
/// In production and staging, or whenever Supabase is configured, this always
/// resolves to [SupabaseSchoolLeadershipRepository].
/// Real school leadership analytics must NEVER silently fall back to synthetic
/// local mock data when offline or encountering network disruption.
///
/// [LocalSchoolLeadershipRepository] is strictly reserved for:
/// - Explicit test / widget test overrides: `overrides: [schoolLeadershipRepositoryProvider.overrideWithValue(LocalSchoolLeadershipRepository())]`
/// - Storybook / preview fixtures
/// - Local offline development mode when Supabase is deliberately unconfigured.
import '../../../auth/domain/models/user_profile.dart';
import '../../../../core/providers/app_providers.dart';

final schoolLeadershipRepositoryProvider =
    Provider<SchoolLeadershipRepository>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  final isDemoUser = user != null &&
      (user.id.startsWith('00000000-') ||
          user.id.startsWith('usr_') ||
          user.role == UserRole.schoolAdmin);
  if (isDemoUser) {
    return LocalSchoolLeadershipRepository();
  }
  if (EnvConfig.isProductionLike) {
    if (!EnvConfig.isSupabaseConfigured) {
      throw StateError(
        '[FidelLearn] FATAL: Supabase credentials are required in ${EnvConfig.appEnvironment}. '
        'A ${EnvConfig.appEnvironment} build must not activate LocalSchoolLeadershipRepository.',
      );
    }
    return SupabaseSchoolLeadershipRepository();
  }
  if (EnvConfig.isSupabaseConfigured) {
    return SupabaseSchoolLeadershipRepository();
  }
  EnvConfig.assertNoMockInProduction('LocalSchoolLeadershipRepository');
  return LocalSchoolLeadershipRepository();
});

/// Active academic year filter for the leadership dashboard.
/// Default: null (resolves dynamically to the school's most recent active year).
final leadershipAcademicYearFilterProvider =
    StateProvider.autoDispose<String?>((ref) => null);

/// Active stream filter: null (All), 'naturalScience', or 'socialScience'.
final leadershipStreamFilterProvider =
    StateProvider.autoDispose<String?>((ref) => null);

/// Active subject filter: null (All), or specific subject ID.
final leadershipSubjectFilterProvider =
    StateProvider.autoDispose<String?>((ref) => null);

/// Executive leadership summary for Leadership Home.
/// Keyed to the active school and academic year.
final schoolLeadershipSummaryProvider =
    FutureProvider.autoDispose<SchoolLeadershipSummary>((ref) async {
  final activeContext = ref.watch(activeSchoolContextProvider);
  if (!activeContext.isSchoolAdmin || activeContext.school == null) {
    throw const SchoolLeadershipAuthorizationException(
      'Access denied: Active school admin membership required.',
    );
  }
  if (activeContext.isOfflineCached) {
    throw const SchoolLeadershipOfflineException(
      'Leadership analytics require an internet connection. Reconnect to load current school analytics.',
    );
  }

  final schoolId = activeContext.school!.id;
  final academicYear = ref.watch(leadershipAcademicYearFilterProvider);
  final repo = ref.watch(schoolLeadershipRepositoryProvider);

  return await repo.getLeadershipSummary(
    schoolId: schoolId,
    academicYear: academicYear,
  );
});

/// Stream comparison summary (Natural Science vs Social Science).
final schoolStreamSummaryProvider =
    FutureProvider.autoDispose<List<SchoolStreamSummary>>((ref) async {
  final activeContext = ref.watch(activeSchoolContextProvider);
  if (!activeContext.isSchoolAdmin || activeContext.school == null) {
    throw const SchoolLeadershipAuthorizationException(
      'Access denied: Active school admin membership required.',
    );
  }
  if (activeContext.isOfflineCached) {
    throw const SchoolLeadershipOfflineException(
      'Leadership analytics require an internet connection. Reconnect to load current school analytics.',
    );
  }

  final schoolId = activeContext.school!.id;
  final academicYear = ref.watch(leadershipAcademicYearFilterProvider);
  final repo = ref.watch(schoolLeadershipRepositoryProvider);

  return await repo.getStreamSummary(
    schoolId: schoolId,
    academicYear: academicYear,
  );
});

/// Subject performance overview with Math variant segregation.
final schoolSubjectSummaryProvider =
    FutureProvider.autoDispose<List<SchoolSubjectSummary>>((ref) async {
  final activeContext = ref.watch(activeSchoolContextProvider);
  if (!activeContext.isSchoolAdmin || activeContext.school == null) {
    throw const SchoolLeadershipAuthorizationException(
      'Access denied: Active school admin membership required.',
    );
  }
  if (activeContext.isOfflineCached) {
    throw const SchoolLeadershipOfflineException(
      'Leadership analytics require an internet connection. Reconnect to load current school analytics.',
    );
  }

  final schoolId = activeContext.school!.id;
  final academicYear = ref.watch(leadershipAcademicYearFilterProvider);
  final stream = ref.watch(leadershipStreamFilterProvider);
  final repo = ref.watch(schoolLeadershipRepositoryProvider);

  return await repo.getSubjectSummary(
    schoolId: schoolId,
    academicYear: academicYear,
    stream: stream,
  );
});

/// Classroom section comparative metrics (neutral, non-ranking).
final schoolClassSummaryProvider =
    FutureProvider.autoDispose<List<SchoolClassSummary>>((ref) async {
  final activeContext = ref.watch(activeSchoolContextProvider);
  if (!activeContext.isSchoolAdmin || activeContext.school == null) {
    throw const SchoolLeadershipAuthorizationException(
      'Access denied: Active school admin membership required.',
    );
  }
  if (activeContext.isOfflineCached) {
    throw const SchoolLeadershipOfflineException(
      'Leadership analytics require an internet connection. Reconnect to load current school analytics.',
    );
  }

  final schoolId = activeContext.school!.id;
  final academicYear = ref.watch(leadershipAcademicYearFilterProvider);
  final stream = ref.watch(leadershipStreamFilterProvider);
  final subjectId = ref.watch(leadershipSubjectFilterProvider);
  final repo = ref.watch(schoolLeadershipRepositoryProvider);

  return await repo.getClassSummary(
    schoolId: schoolId,
    academicYear: academicYear,
    stream: stream,
    subjectId: subjectId,
  );
});

/// Systemic weak topics across the school derived from mistake records.
final schoolSystemicWeakTopicsProvider =
    FutureProvider.autoDispose<List<SchoolSystemicWeakTopic>>((ref) async {
  final activeContext = ref.watch(activeSchoolContextProvider);
  if (!activeContext.isSchoolAdmin || activeContext.school == null) {
    throw const SchoolLeadershipAuthorizationException(
      'Access denied: Active school admin membership required.',
    );
  }
  if (activeContext.isOfflineCached) {
    throw const SchoolLeadershipOfflineException(
      'Leadership analytics require an internet connection. Reconnect to load current school analytics.',
    );
  }

  final schoolId = activeContext.school!.id;
  final academicYear = ref.watch(leadershipAcademicYearFilterProvider);
  final subjectId = ref.watch(leadershipSubjectFilterProvider);
  final repo = ref.watch(schoolLeadershipRepositoryProvider);

  return await repo.getSystemicWeakTopics(
    schoolId: schoolId,
    academicYear: academicYear,
    subjectId: subjectId,
    limit: 15,
  );
});

/// Recent assessments overview preserving P5 provenance.
final schoolAssessmentsOverviewProvider =
    FutureProvider.autoDispose<List<SchoolAssessmentSummary>>((ref) async {
  final activeContext = ref.watch(activeSchoolContextProvider);
  if (!activeContext.isSchoolAdmin || activeContext.school == null) {
    throw const SchoolLeadershipAuthorizationException(
      'Access denied: Active school admin membership required.',
    );
  }
  if (activeContext.isOfflineCached) {
    throw const SchoolLeadershipOfflineException(
      'Leadership analytics require an internet connection. Reconnect to load current school analytics.',
    );
  }

  final schoolId = activeContext.school!.id;
  final academicYear = ref.watch(leadershipAcademicYearFilterProvider);
  final repo = ref.watch(schoolLeadershipRepositoryProvider);

  return await repo.getAssessmentsOverview(
    schoolId: schoolId,
    academicYear: academicYear,
    limit: 20,
  );
});

/// Teacher subject assignment coverage oversight.
final schoolTeacherCoverageProvider =
    FutureProvider.autoDispose<List<SchoolTeacherCoverageSlot>>((ref) async {
  final activeContext = ref.watch(activeSchoolContextProvider);
  if (!activeContext.isSchoolAdmin || activeContext.school == null) {
    throw const SchoolLeadershipAuthorizationException(
      'Access denied: Active school admin membership required.',
    );
  }
  if (activeContext.isOfflineCached) {
    throw const SchoolLeadershipOfflineException(
      'Leadership analytics require an internet connection. Reconnect to load current school analytics.',
    );
  }

  final schoolId = activeContext.school!.id;
  final academicYear = ref.watch(leadershipAcademicYearFilterProvider);
  final repo = ref.watch(schoolLeadershipRepositoryProvider);

  return await repo.getTeacherCoverage(
    schoolId: schoolId,
    academicYear: academicYear,
  );
});

// =============================================================================
// Paginated Support Population Notifier
// =============================================================================

class SchoolSupportPopulationState {
  final List<SchoolSupportStudent> students;
  final bool isLoading;
  final bool hasMore;
  final int currentOffset;
  final int totalCount;
  final String? severityFilter;
  final String? errorMessage;

  const SchoolSupportPopulationState({
    required this.students,
    required this.isLoading,
    required this.hasMore,
    required this.currentOffset,
    required this.totalCount,
    this.severityFilter,
    this.errorMessage,
  });

  const SchoolSupportPopulationState.initial()
      : this(
          students: const [],
          isLoading: true,
          hasMore: true,
          currentOffset: 0,
          totalCount: 0,
        );

  SchoolSupportPopulationState copyWith({
    List<SchoolSupportStudent>? students,
    bool? isLoading,
    bool? hasMore,
    int? currentOffset,
    int? totalCount,
    String? severityFilter,
    String? errorMessage,
  }) {
    return SchoolSupportPopulationState(
      students: students ?? this.students,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentOffset: currentOffset ?? this.currentOffset,
      totalCount: totalCount ?? this.totalCount,
      severityFilter: severityFilter ?? this.severityFilter,
      errorMessage: errorMessage,
    );
  }
}

final schoolSupportPopulationProvider = StateNotifierProvider.autoDispose<
    SchoolSupportPopulationNotifier, SchoolSupportPopulationState>((ref) {
  final activeContext = ref.watch(activeSchoolContextProvider);
  final schoolId = activeContext.school?.id;
  final academicYear = ref.watch(leadershipAcademicYearFilterProvider);
  final repo = ref.watch(schoolLeadershipRepositoryProvider);

  return SchoolSupportPopulationNotifier(
    repo: repo,
    schoolId: schoolId,
    academicYear: academicYear,
    isSchoolAdmin: activeContext.isSchoolAdmin,
    isOfflineCached: activeContext.isOfflineCached,
  );
});

class SchoolSupportPopulationNotifier
    extends StateNotifier<SchoolSupportPopulationState> {
  final SchoolLeadershipRepository _repo;
  final String? _schoolId;
  final String? _academicYear;
  final bool _isSchoolAdmin;
  final bool _isOfflineCached;

  static const int _pageSize = 25;

  SchoolSupportPopulationNotifier({
    required SchoolLeadershipRepository repo,
    required String? schoolId,
    required String? academicYear,
    required bool isSchoolAdmin,
    required bool isOfflineCached,
  })  : _repo = repo,
        _schoolId = schoolId,
        _academicYear = academicYear,
        _isSchoolAdmin = isSchoolAdmin,
        _isOfflineCached = isOfflineCached,
        super(const SchoolSupportPopulationState.initial()) {
    loadInitial();
  }

  Future<void> loadInitial({String? severity}) async {
    final schoolId = _schoolId;
    if (!_isSchoolAdmin || schoolId == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Access denied: Active school admin membership required.',
      );
      return;
    }
    if (_isOfflineCached) {
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            'Leadership analytics require an internet connection. Reconnect to load current school analytics.',
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      students: const [],
      currentOffset: 0,
      hasMore: true,
      severityFilter: severity,
    );

    try {
      final results = await _repo.getSupportPopulation(
        schoolId: schoolId,
        academicYear: _academicYear,
        severity: severity,
        limit: _pageSize,
        offset: 0,
      );

      final total = results.isNotEmpty ? results.first.totalCount : 0;
      state = state.copyWith(
        students: results,
        isLoading: false,
        currentOffset: results.length,
        totalCount: total,
        hasMore: results.length < total,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    final schoolId = _schoolId;
    if (state.isLoading ||
        !state.hasMore ||
        schoolId == null ||
        _isOfflineCached) {
      return;
    }

    state = state.copyWith(isLoading: true);
    try {
      final results = await _repo.getSupportPopulation(
        schoolId: schoolId,
        academicYear: _academicYear,
        severity: state.severityFilter,
        limit: _pageSize,
        offset: state.currentOffset,
      );

      final updated = [...state.students, ...results];
      state = state.copyWith(
        students: updated,
        isLoading: false,
        currentOffset: updated.length,
        hasMore: updated.length < state.totalCount,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void filterBySeverity(String? severity) {
    loadInitial(severity: severity);
  }
}

/// Student academic detail drill-down provider.
final schoolStudentAcademicDetailProvider = FutureProvider.autoDispose
    .family<SchoolStudentAcademicDetail, String>((ref, studentId) async {
  final activeContext = ref.watch(activeSchoolContextProvider);
  if (!activeContext.isSchoolAdmin || activeContext.school == null) {
    throw const SchoolLeadershipAuthorizationException(
      'Access denied: Active school admin membership required.',
    );
  }
  if (activeContext.isOfflineCached) {
    throw const SchoolLeadershipOfflineException(
      'Leadership analytics require an internet connection. Reconnect to load current school analytics.',
    );
  }

  final schoolId = activeContext.school!.id;
  final repo = ref.watch(schoolLeadershipRepositoryProvider);

  return await repo.getStudentAcademicSummary(
    schoolId: schoolId,
    studentId: studentId,
  );
});
