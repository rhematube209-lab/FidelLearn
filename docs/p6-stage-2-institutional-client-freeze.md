# P6 Stage 2 — Institutional Client Architecture
## Freeze Record

```
Status:   FROZEN
Tag:      p6-stage-2-institutional-client-v1.0.0
Tests:    460 / 460 passing
Analyze:  0 issues
Format:   clean
Drift:    v8 (unchanged)
Date:     2026-09-25
```

---

## 1. Scope

P6 Stage 2 connects the Flutter application to the PostgreSQL-enforced, RLS-protected
institutional backend established in P6 Stage 1.

This stage introduces:

- Pure-Dart canonical institutional domain models
- Supabase repository implementations for schools and classrooms
- An `ActiveSchoolContext` state machine for safe multi-tenant application behavior
- Offline affiliation caching (display-only, not a security boundary)
- Account-switch isolation via epoch-versioned async load tracking
- Multi-school membership support with deterministic school selection

This stage does **not** introduce:

- The Teacher Portal (P7)
- The School Leadership Dashboard (P8)
- Assignments, interventions, or analytics (P9 / P10)
- Billing or licensing

---

## 2. Architectural Principle (Non-Negotiable)

> **The backend determines whether the user has institutional authority.**
> **`ActiveSchoolContext` determines which authorized tenant the user is currently viewing.**
> **The offline cache only remembers what to display.**

`ActiveSchoolContext` is a UI and display state machine, not a security boundary.
All data access authorization is enforced by Supabase PostgreSQL RLS, not by client-side role checks.

---

## 3. Domain Models

**File:** `lib/features/school/domain/models/tenant_models.dart`

### Enums

| Enum | Values |
|---|---|
| `SchoolStatus` | `active`, `suspended`, `archived`, `unknown` |
| `SchoolMemberRole` | `student`, `teacher`, `schoolAdmin`, `unknown` |
| `SchoolMembershipStatus` | `invited`, `active`, `inactive`, `removed`, `unknown` |
| `ClassroomMemberRole` | `student`, `teacher`, `unknown` |
| `ActiveSchoolContextStatus` | `loading`, `independent`, `active`, `offlineCached`, `permissionRevoked`, `error` |

All enums provide `fromString()` (DB / JSON to enum) and `toDbString()` (enum to DB / JSON).

### Backward-Compatibility Aliases

Stage 1 test code refers to legacy type names. Aliases are preserved:

```dart
typedef SchoolRole = SchoolMemberRole;
typedef MembershipStatus = SchoolMembershipStatus;
typedef SchoolTenant = School;
typedef ClassroomEntity = Classroom;
typedef ClassroomMembershipEntity = ClassroomMembership;
typedef TeacherSubjectAssignmentEntity = TeacherSubjectAssignment;
typedef SchoolInvitationEntity = SchoolInvitation;
```

### Entity Classes

All entities extend `Equatable` for value equality. All implement `fromJson` / `toJson`.

| Class | Purpose |
|---|---|
| `School` | Institutional tenant entity |
| `SchoolMembership` | User role and status within a school |
| `SchoolMembershipWithSchool` | Relational aggregate: membership + school |
| `Classroom` | A classroom belonging to a school |
| `ClassroomMembership` | User role within a classroom |
| `TeacherSubjectAssignment` | Scopes a teacher authority to a subject within a classroom |
| `SchoolInvitation` | School invitation with optional `tokenHash` (admin-only) |
| `CachedSchoolContext` | Lightweight offline snapshot (display-only) |
| `ActiveSchoolContext` | Application-level multi-tenant context state |
| `InstitutionalAccess` | Stateless helper for checking institutional permissions |

### Security Note on `SchoolInvitation`

The `tokenHash` field is present in the domain model for admin-initiated flows only.
Student and teacher-facing code must never surface raw tokens. RLS on the
`school_invitations` table enforces that non-admins cannot read `token_hash`.

---

## 4. Repository Contracts

### `SchoolRepository`

**File:** `lib/features/school/domain/repositories/school_repository.dart`

```
getMySchools()             → List<SchoolMembershipWithSchool>
getSchoolById(id)          → School?
getSchoolByCode(code)      → School?
getSchoolInvitations(id)   → List<SchoolInvitation>   (school admin only)
```

### `ClassroomRepository`

**File:** `lib/features/school/domain/repositories/classroom_repository.dart`

```
getMyClassrooms(schoolId?)             → List<Classroom>
getMyClassroomMemberships()            → List<ClassroomMembership>
getClassroomById(id)                   → Classroom?
getTeacherSubjectAssignments(schoolId) → List<TeacherSubjectAssignment>
```

---

## 5. Supabase Repository Implementations

### `SupabaseSchoolRepository`

**File:** `lib/features/school/data/repositories/supabase_school_repository.dart`

- Uses authenticated Supabase client; RLS enforces tenant isolation on all queries.
- `getMySchools()`: Fetches `school_memberships` joined with `schools` via PostgREST embed.
- `getSchoolByCode()`: Public school discovery (lookup by `school_code`). Authorization to
  join is never granted here. Only the `join_school_by_code` RPC grants membership.
- Error mapping: PostgreSQL error code `42501` → `PermissionDeniedFailure`;
  network failure → `NetworkFailure`.

### `SupabaseClassroomRepository`

**File:** `lib/features/school/data/repositories/supabase_classroom_repository.dart`

- All queries are RLS-gated: students see only their own classrooms;
  teachers see only classrooms they are assigned to.
- `getTeacherSubjectAssignments()` is scoped by `school_id` to prevent cross-tenant leakage.

### Error Mapping (`mapSupabaseError`)

**File:** `lib/features/school/data/models/school_dtos.dart`

| Condition | Failure |
|---|---|
| PostgreSQL `42501` (RLS / permission denied) | `PermissionDeniedFailure` |
| Network / socket exception | `NetworkFailure` |
| All other errors | `UnknownFailure` |

---

## 6. ActiveSchoolContext State Machine

**File:** `lib/features/school/presentation/providers/active_school_context_provider.dart`

### State Transitions

```
                +----------+
     boot ----> | loading  |
                +----+-----+
                     |
         +-----------+-----------+
         v           v           v
   independent    active    offlineCached
  (0 memberships) (online)  (cache only)
         |           |           |
         |     permissionRevoked |
         |    (membership removed)
         +-----------+-----------+
```

### Race Condition Protection (_activeLoadEpoch)

Every call to `resolveContext()` increments `_activeLoadEpoch`. All async await points
re-check the epoch before mutating state. If the user switches accounts or schools before
a backend response arrives, the stale response is silently discarded.

### Offline Cache Behavior

1. On startup, the local cache is loaded first for instant UI responsiveness.
2. An online refresh is always initiated immediately after.
3. If the online refresh fails and the cache is already displayed, the offline cached
   state is retained — student personal study is never blocked by network errors.
4. If the online refresh fails on a fresh device with no cache, state defaults to `independent`.
5. The cache never grants backend authorization. Privileged mutations check the online
   session or `isOfflineCached` flag explicitly.

### Multi-School Support

- `getMySchools()` returns all active memberships.
- If a previously saved `activeSchoolId` matches an active membership, it is selected.
- Otherwise the first active membership is selected.
- `selectSchool(schoolId)` allows explicit switching; only active memberships are selectable.
- `selectClassroom(classroom)` is a synchronous update guarded by school ID matching.

### Account-Switch Isolation

When `currentUserProvider` detects a user change (`prevUser?.id != nextUser.id`):
- `_activeLoadEpoch` is incremented, invalidating any in-flight requests from the previous user.
- `resolveContext()` is called fresh for the new user.
- On sign-out, state is set to `independent` and the cache is cleared.

---

## 7. Offline Trust Model Summary

| Layer | Authority |
|---|---|
| PostgreSQL RLS | Sole gatekeeper for all data read / write access |
| Supabase RPC (`join_school`, `add_member`, etc.) | Mutation authority; validates server-side |
| `ActiveSchoolContext` | Which school to display; not a security boundary |
| `CachedSchoolContext` | What to show while offline; confers no authority |
| `InstitutionalAccess` | Stateless helper; checks `isOfflineCached` before mutations |

---

## 8. Deprecated Global Role Policy

`UserRole.teacher` and `UserRole.schoolAdmin` in the legacy `user_profile` table
are **deprecated as institutional authority claims**.

| Old Claim | Status | Replacement |
|---|---|---|
| `UserRole.teacher` | Deprecated | `SchoolMembership.role == SchoolMemberRole.teacher` |
| `UserRole.schoolAdmin` | Deprecated | `SchoolMembership.role == SchoolMemberRole.schoolAdmin` |

Deprecated values confer zero institutional authority in P6+ code.
All institutional RBAC is derived from `school_memberships` enforced by RLS.

---

## 9. Wiring

**File:** `lib/core/providers/app_providers.dart`

```dart
final schoolRepositoryProvider             → SupabaseSchoolRepository
final classroomRepositoryProvider          → SupabaseClassroomRepository
final activeSchoolContextProvider          → ActiveSchoolContextNotifier
final mySchoolMembershipsProvider          → FutureProvider (all memberships)
final myClassroomsProvider                 → FutureProvider (scoped to active school)
final hasActiveTeacherMembershipProvider   → Provider<bool>
final hasActiveSchoolAdminMembershipProvider → Provider<bool>
```

**File:** `lib/core/security/auth_session_storage.dart`

New persistent storage methods:
```
saveCachedSchoolContext(CachedSchoolContext)
getCachedSchoolContext() → CachedSchoolContext?
clearSchoolContext()
saveActiveSchoolId(String)
getActiveSchoolId() → String?
```

---

## 10. Test Coverage

| Suite | File | Status |
|---|---|---|
| Domain models, DTOs, enums, error mapping | `test/unit/tenant_models_test.dart` | PASS |
| `ActiveSchoolContext` lifecycle | `test/unit/active_school_context_test.dart` | PASS |
| Stage 1 PostgreSQL RLS integration | `test/integration/school_tenant_security_test.sql` | PASS |
| Full suite (all phases) | `flutter test --coverage` | **460 / 460 PASS** |

---

## 11. Quality Gates

| Gate | Result |
|---|---|
| `flutter test --coverage` | 460 / 460 passed |
| `flutter analyze --fatal-infos` | 0 issues |
| `dart format` | Clean |
| Drift schema version | v8 (unchanged) |
| Stage 1 RLS unchanged | Confirmed |

---

## 12. Frozen Deliverables

| File | Purpose |
|---|---|
| `lib/features/school/domain/models/tenant_models.dart` | Canonical domain models |
| `lib/features/school/domain/repositories/school_repository.dart` | Repository contract |
| `lib/features/school/domain/repositories/classroom_repository.dart` | Repository contract |
| `lib/features/school/data/models/school_dtos.dart` | DTOs and error mapping |
| `lib/features/school/data/repositories/supabase_school_repository.dart` | Production school repo |
| `lib/features/school/data/repositories/supabase_classroom_repository.dart` | Production classroom repo |
| `lib/features/school/data/repositories/local_school_repository.dart` | Offline / mock repo |
| `lib/features/school/presentation/providers/active_school_context_provider.dart` | Context state machine |
| `lib/core/providers/app_providers.dart` | Production Riverpod wiring |
| `lib/core/security/auth_session_storage.dart` | Offline cache persistence |
| `lib/core/errors/failures.dart` | Institutional typed failures |
| `test/unit/tenant_models_test.dart` | Domain model tests |
| `test/unit/active_school_context_test.dart` | Context lifecycle tests |
| `docs/p6-stage-2-institutional-client-architecture.md` | Architecture reference |

---

## 13. What Subsequent Phases May Build On

P6 Stage 2 provides the following stable contracts for P7 and beyond:

- `activeSchoolContextProvider` — consume in Teacher Portal and School Dashboard
- `hasActiveTeacherMembershipProvider` / `hasActiveSchoolAdminMembershipProvider` — route guards
- `SchoolRepository` / `ClassroomRepository` — data source for assignments and analytics
- `InstitutionalAccess` — uniform access checking across all institutional features

---

## 14. Freeze Declaration

P6 Stage 2 — **Domain Models, Supabase Repositories, and ActiveSchoolContext** is **FROZEN**.

The institutional client architecture is complete, tested, and ready to support the
Teacher Portal (P7) and School Leadership Dashboard (P8).

```
Frozen:   2026-09-25
Tests:    460 / 460
Analyze:  0 issues
Drift:    v8 (unchanged)
Tag:      p6-stage-2-institutional-client-v1.0.0
Next:     P7 Teacher Portal
```
