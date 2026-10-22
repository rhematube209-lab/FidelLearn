import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/security/auth_session_storage.dart';
import '../../../auth/domain/models/user_profile.dart';
import '../../domain/models/tenant_models.dart';
import '../../domain/repositories/classroom_repository.dart';
import '../../domain/repositories/school_repository.dart';

/// StateNotifier that coordinates and resolves the application-level ActiveSchoolContext.
///
/// CRITICAL ARCHITECTURAL PRINCIPLE:
/// ActiveSchoolContext represents UI and display context only. It is NOT a security boundary.
/// PostgreSQL Row Level Security (RLS) is the sole authoritative gatekeeper for tenant data.
class ActiveSchoolContextNotifier extends StateNotifier<ActiveSchoolContext> {
  final SchoolRepository _schoolRepo;
  final ClassroomRepository _classroomRepo;
  final AuthSessionStorage _storage;
  final Ref _ref;

  int _activeLoadEpoch = 0;

  ActiveSchoolContextNotifier({
    required SchoolRepository schoolRepo,
    required ClassroomRepository classroomRepo,
    required AuthSessionStorage storage,
    required Ref ref,
  })  : _schoolRepo = schoolRepo,
        _classroomRepo = classroomRepo,
        _storage = storage,
        _ref = ref,
        super(const ActiveSchoolContext.loading()) {
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _ref.listen<AsyncValue<UserProfile?>>(currentUserProvider,
        (previous, next) {
      final prevUser = previous?.valueOrNull;
      final nextUser = next.valueOrNull;

      if (nextUser == null) {
        _activeLoadEpoch++;
        state = const ActiveSchoolContext.independent();
        _storage.clearSchoolContext();
      } else if (prevUser?.id != nextUser.id) {
        resolveContext(user: nextUser);
      }
    });

    final initialUser = _ref.read(currentUserProvider).valueOrNull;
    if (initialUser != null) {
      resolveContext(user: initialUser);
    } else {
      state = const ActiveSchoolContext.independent();
    }
  }

  /// Resolve school context for a user, using offline cache first, followed by online sync.
  Future<ActiveSchoolContext> resolveContext({UserProfile? user}) async {
    final activeUser = user ?? _ref.read(currentUserProvider).valueOrNull;
    if (activeUser == null) {
      final loadEpoch = ++_activeLoadEpoch;
      state = const ActiveSchoolContext.independent();
      await _storage.clearSchoolContext(version: loadEpoch);
      return state;
    }

    final loadEpoch = ++_activeLoadEpoch;

    // Immediately mark state as loading synchronously before any async gap
    state = const ActiveSchoolContext.loading();

    // 1. Immediately inspect local cache for fast offline responsiveness
    final cached = await _storage.getCachedSchoolContext();
    if (loadEpoch != _activeLoadEpoch) return state;

    // Security check: Only use cached context if it belongs to activeUser
    if (cached != null && cached.userId == activeUser.id) {
      // Reconstitute minimal display context from cache
      final cachedSchool = School(
        id: cached.schoolId,
        name: cached.schoolName,
        displayName: cached.schoolName,
        schoolCode: cached.schoolCode,
        status: SchoolStatus.active,
        createdAt: cached.cachedAt,
        updatedAt: cached.cachedAt,
      );

      final cachedMembership = SchoolMembership(
        id: cached.membershipId,
        schoolId: cached.schoolId,
        userId: activeUser.id,
        role: cached.membershipRole,
        status: cached.membershipStatus,
        createdAt: cached.cachedAt,
        updatedAt: cached.cachedAt,
      );

      Classroom? cachedClassroom;
      if (cached.activeClassroomId != null) {
        cachedClassroom = Classroom(
          id: cached.activeClassroomId!,
          schoolId: cached.schoolId,
          name: cached.activeClassroomName ?? 'My Classroom',
          grade: activeUser.grade,
          academicYear: '2026/27',
          createdAt: cached.cachedAt,
          updatedAt: cached.cachedAt,
        );
      }

      state = ActiveSchoolContext(
        status: ActiveSchoolContextStatus.offlineCached,
        school: cachedSchool,
        membership: cachedMembership,
        selectedClassroom: cachedClassroom,
        isOfflineCached: true,
      );
    } else if (cached != null && cached.userId != activeUser.id) {
      // Cached context belongs to a different signed-in user or is untagged; purge it immediately!
      await _storage.clearSchoolContext(version: loadEpoch);
    }

    // 2. Perform authoritative online refresh against Supabase
    try {
      final mySchools = await _schoolRepo.getMySchools();
      if (loadEpoch != _activeLoadEpoch) {
        return state; // Discard stale response if user switched
      }

      if (mySchools.isEmpty) {
        // Zero school memberships -> pure independent personal learner
        state = const ActiveSchoolContext.independent();
        await _storage.clearSchoolContext(version: loadEpoch);
        return state;
      }

      // Filter for active memberships
      final activeSchools =
          mySchools.where((m) => m.membership.isActive).toList();

      if (activeSchools.isEmpty) {
        // All memberships are inactive or removed -> revoke active context
        state = const ActiveSchoolContext.permissionRevoked(
          'Your institutional school membership has been deactivated or removed.',
        );
        await _storage.clearSchoolContext(version: loadEpoch);
        return state;
      }

      // Deterministically select active school
      final savedSchoolId = await _storage.getActiveSchoolId();
      if (loadEpoch != _activeLoadEpoch) return state;
      SchoolMembershipWithSchool selectedEntry = activeSchools.first;

      if (savedSchoolId != null) {
        final match =
            activeSchools.cast<SchoolMembershipWithSchool?>().firstWhere(
                  (e) => e?.school.id == savedSchoolId,
                  orElse: () => null,
                );
        if (match != null) {
          selectedEntry = match;
        }
      }

      // Fetch user's classrooms for this specific school
      List<Classroom> classrooms = const [];
      List<ClassroomMembership> classroomMemberships = const [];
      try {
        classrooms = await _classroomRepo.getMyClassrooms(
          schoolId: selectedEntry.school.id,
        );
        classroomMemberships = await _classroomRepo.getMyClassroomMemberships();
      } catch (e) {
        debugPrint('ActiveSchoolContext: classroom read warning: $e');
      }

      if (loadEpoch != _activeLoadEpoch) return state;

      Classroom? primaryClassroom;
      if (classrooms.isNotEmpty) {
        primaryClassroom = classrooms.first;
      }

      state = ActiveSchoolContext(
        status: ActiveSchoolContextStatus.active,
        school: selectedEntry.school,
        membership: selectedEntry.membership,
        classroomMemberships: classroomMemberships,
        selectedClassroom: primaryClassroom,
        isOfflineCached: false,
      );

      // Persist refreshed snapshot with versioned atomic commit
      await _storage.commitSchoolContext(
        version: loadEpoch,
        schoolId: selectedEntry.school.id,
        context: CachedSchoolContext.fromSchoolAndMembership(
          school: selectedEntry.school,
          membership: selectedEntry.membership,
          classroom: primaryClassroom,
        ),
      );
      if (loadEpoch != _activeLoadEpoch) return state;
      return state;
    } catch (e) {
      if (loadEpoch != _activeLoadEpoch) return state;
      debugPrint('ActiveSchoolContext online sync error: $e');

      // If already displayed from offline cache, keep it active offline!
      if (state.isOfflineCached) {
        return state;
      }

      // Fallback: If network failed on fresh device with 0 cache, default to independent
      // so student personal study is NEVER blocked by an institutional network error.
      state = const ActiveSchoolContext.independent();
      return state;
    }
  }

  /// Switch active school deterministically (e.g. for multi-school teachers).
  Future<void> selectSchool(String schoolId) async {
    final user = _ref.read(currentUserProvider).valueOrNull;
    if (user == null) {
      state = const ActiveSchoolContext.independent();
      return;
    }

    final loadEpoch = ++_activeLoadEpoch;
    state = const ActiveSchoolContext.loading();

    try {
      final mySchools = await _schoolRepo.getMySchools();
      if (loadEpoch != _activeLoadEpoch) return;

      final match = mySchools.cast<SchoolMembershipWithSchool?>().firstWhere(
            (m) => m?.school.id == schoolId && m?.membership.isActive == true,
            orElse: () => null,
          );

      if (match == null) {
        if (loadEpoch != _activeLoadEpoch) return;
        // Deterministically settle on unavailable school ID; never remain loading
        if (mySchools.isEmpty) {
          state = const ActiveSchoolContext.independent();
        } else {
          state = ActiveSchoolContext.error(
            'School $schoolId is not available or membership is inactive.',
          );
        }
        return;
      }

      final classrooms =
          await _classroomRepo.getMyClassrooms(schoolId: schoolId);
      final classroomMemberships =
          await _classroomRepo.getMyClassroomMemberships();

      if (loadEpoch != _activeLoadEpoch) return;

      state = ActiveSchoolContext(
        status: ActiveSchoolContextStatus.active,
        school: match.school,
        membership: match.membership,
        classroomMemberships: classroomMemberships,
        selectedClassroom: classrooms.isNotEmpty ? classrooms.first : null,
        isOfflineCached: false,
      );

      // Persist selected school with versioned atomic commit
      await _storage.commitSchoolContext(
        version: loadEpoch,
        schoolId: schoolId,
        context: CachedSchoolContext.fromSchoolAndMembership(
          school: match.school,
          membership: match.membership,
          classroom: classrooms.isNotEmpty ? classrooms.first : null,
        ),
      );
      if (loadEpoch != _activeLoadEpoch) return;
    } catch (e) {
      if (loadEpoch != _activeLoadEpoch) return;
      debugPrint('ActiveSchoolContext: failed to select school $schoolId: $e');
      // Settle deterministically on error, never leave state as loading
      state =
          ActiveSchoolContext.error('Failed to select school $schoolId: $e');
    }
  }

  /// Update selected classroom within the active school.
  void selectClassroom(Classroom classroom) {
    if (state.school != null && classroom.schoolId == state.school!.id) {
      state = state.copyWith(selectedClassroom: classroom);
    }
  }

  /// Manually trigger a refresh.
  Future<void> refresh() async {
    await resolveContext();
  }

  /// Explicitly reset context.
  Future<void> clear() async {
    final loadEpoch = ++_activeLoadEpoch;
    state = const ActiveSchoolContext.independent();
    await _storage.clearSchoolContext(version: loadEpoch);
  }
}

// =============================================================================
// Active School Providers
// =============================================================================

/// Global provider for the active institutional school context.
final activeSchoolContextProvider =
    StateNotifierProvider<ActiveSchoolContextNotifier, ActiveSchoolContext>(
  (ref) {
    final schoolRepo = ref.watch(schoolRepositoryProvider);
    final classroomRepo = ref.watch(classroomRepositoryProvider);
    final storage = AuthSessionStorage();

    return ActiveSchoolContextNotifier(
      schoolRepo: schoolRepo,
      classroomRepo: classroomRepo,
      storage: storage,
      ref: ref,
    );
  },
);

/// Provider exposing all school memberships of the current user.
final mySchoolMembershipsProvider =
    FutureProvider<List<SchoolMembershipWithSchool>>((ref) async {
  final schoolRepo = ref.watch(schoolRepositoryProvider);
  return await schoolRepo.getMySchools();
});

/// Provider exposing classrooms accessible to the current user,
/// automatically scoped to the active school if selected.
final myClassroomsProvider = FutureProvider<List<Classroom>>((ref) async {
  final classroomRepo = ref.watch(classroomRepositoryProvider);
  final activeContext = ref.watch(activeSchoolContextProvider);

  final schoolId = activeContext.school?.id;
  return await classroomRepo.getMyClassrooms(schoolId: schoolId);
});

/// Provider indicating whether the user currently has an active teacher membership.
final hasActiveTeacherMembershipProvider = Provider<bool>((ref) {
  final context = ref.watch(activeSchoolContextProvider);
  return context.isTeacher;
});

/// Provider indicating whether the user currently has an active school admin membership.
final hasActiveSchoolAdminMembershipProvider = Provider<bool>((ref) {
  final context = ref.watch(activeSchoolContextProvider);
  return context.isSchoolAdmin;
});
