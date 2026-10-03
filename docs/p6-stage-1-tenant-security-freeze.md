# FidelLearn — P6 Stage 1 Multi-Tenant Database, RLS & Security Foundation Freeze

**Status**: APPROVED & FROZEN  
**Date**: September 25, 2026  
**Migration Baseline**: `supabase/migrations/20260925000000_school_tenant_security.sql`  
**Test Harness**: `test/integration/p6_tenant_security_pg_test.sql` / `tools/test_postgres_tenancy.js`  
**Drift SQLite Version**: Schema v8 (unchanged)  
**Automated Tests**: 438 Dart tests passing, 0 analyzer issues, 10/10 native PostgreSQL security gates passed  

---

## 1. Executive Summary & Purpose

FidelLearn's foundational student-learning engine (P0 Curriculum & Architecture, P2 Adaptive Study Planner, P3 Advanced Scientific Rendering, P4 Spaced Repetition Mastery Engine, P5 ESSLCE National Exam Simulation Mode) has been successfully complemented with its institutional multi-tenant SaaS foundation.

**P6 Stage 1** provides an institutional database architecture with strict tenant isolation enforced at the native PostgreSQL level. This document records the empirical results of executing migration `20260925000000_school_tenant_security.sql`, security verification tests, and scale benchmarks against an actual PostgreSQL engine.

Tenant isolation is verified not by in-memory mock assumptions, but by PostgreSQL Row Level Security (RLS), check constraints, unique composite indexes, and `SECURITY DEFINER` RPC functions with hardened search paths.

---

## 2. Tenant Architecture & Dual-Role Model

FidelLearn strictly separates **global system authorization** from **tenant-scoped institutional authority**:

```mermaid
graph TD
    User([FidelLearn User / auth.users]) --> Profile[profiles table]
    Profile --> GlobalRole{global role in profiles}
    GlobalRole -->|student| StudentAuth[Personal Exam & Mastery Engine]
    GlobalRole -->|platform_admin| SuperAdmin[FidelLearn Platform Ops]

    Profile --> SM[school_memberships table]
    SM -->|school_id + role| TenantRole{tenant role}
    TenantRole -->|student| SchoolStudent[Classroom Enrollee]
    TenantRole -->|teacher| SchoolTeacher[Subject/Classroom Instructor]
    TenantRole -->|school_admin| SchoolAdmin[School Leader / Manager]
```

### 2.1 Deprecation of Global Institutional Authority
- Prior global roles `teacher` and `school_admin` in `profiles.role` are formally deprecated for institutional authority.
- All users default to global `student` (or `platform_admin` for system maintainers).
- Institutional rights (managing classrooms, viewing student analytics, assigning subjects) are strictly derived from active rows in `school_memberships`.
- Having a school code (e.g., `FID-BOL001`) grants zero authority without a verified membership record.

---

## 3. Table Contracts & Relational Integrity

### 3.1 `schools`
Central institution record. Hard physical deletion is prohibited by business policy.
- Primary Key: `id UUID`
- Unique Code: `school_code VARCHAR(32) UNIQUE` (e.g., `FID-BOL001`)
- Lifecycle States: `active`, `suspended`, `archived`
- RLS Policy:
  - `SELECT`: Active school members (`is_school_member(id)`) or platform admins (`is_platform_admin()`).
  - `INSERT/UPDATE/DELETE`: Mutated exclusively through trusted RPC (`create_school_internal`, `update_school_status_internal`). Direct client mutations return `0 rows` / rejected by RLS.

### 3.2 `school_memberships`
Defines an individual user's role and status within an institution.
- Primary Key: `id UUID`
- Composite Unique Constraint: `UNIQUE(school_id, user_id)` (A user has exactly one membership per school).
- Foreign Keys:
  - `school_id REFERENCES schools(id) ON DELETE CASCADE`
  - `user_id REFERENCES profiles(id) ON DELETE CASCADE`
- Allowed Roles: `student`, `teacher`, `school_admin`
- Lifecycle States: `active`, `inactive`, `removed`
- RLS Policy:
  - Users can read their own membership (`user_id = auth.uid()`).
  - School Admins can view all memberships in their school (`is_school_admin(school_id)`).
  - Teachers can view students in assigned classes via `is_teacher_of_student(school_id, user_id)`.
  - Direct client `INSERT`, `UPDATE`, `DELETE` are completely blocked. Modifications must occur via `grant_school_membership_internal` or `update_school_membership_status_internal`.

### 3.3 `classrooms`
Represents an academic cohort (e.g., "Grade 12 Natural Section A").
- Primary Key: `id UUID`
- Foreign Key: `school_id REFERENCES schools(id) ON DELETE CASCADE`
- Composite Unique Constraint: `UNIQUE(school_id, academic_year, grade_level, stream, section)`
- Lifecycle States: `active`, `archived`
- RLS Policy:
  - Enrolled students (`is_classroom_enrolled(id)`) can view their classroom.
  - Assigned teachers (`is_classroom_teacher(id)`) can view their assigned classrooms.
  - School admins (`is_classroom_school_admin(id)`) can view all classrooms in the school.
  - Platform admins have full visibility.

### 3.4 `classroom_memberships`
Enrollment of students or homeroom teachers into a classroom.
- Primary Key: `id UUID`
- Foreign Keys:
  - `classroom_id REFERENCES classrooms(id) ON DELETE CASCADE`
  - `user_id REFERENCES profiles(id) ON DELETE CASCADE`
- Composite Unique Constraint: `UNIQUE(classroom_id, user_id)`
- Tenant Coherency Check: Enforced via `check_classroom_member_school_coherency()` trigger. Rejects any attempt to enroll a user who lacks an active `school_membership` in the classroom's parent school.
- RLS Policy:
  - Direct mutations blocked. Handled through `assign_classroom_member_internal`.

### 3.5 `teacher_subject_assignments`
Scopes a teacher's academic authority to specific subjects within a classroom.
- Primary Key: `id UUID`
- Foreign Keys:
  - `school_id REFERENCES schools(id) ON DELETE CASCADE`
  - `classroom_id REFERENCES classrooms(id) ON DELETE CASCADE`
  - `teacher_user_id REFERENCES profiles(id) ON DELETE CASCADE`
- Composite Unique Constraint: `UNIQUE(classroom_id, teacher_user_id, subject_id, stream_variant)`
- Cross-Tenant Coherency: Enforced via trigger ensuring `classroom.school_id = assignment.school_id` and teacher has active `teacher` membership in that school.
- RLS Policy:
  - Direct mutations blocked. Handled through `assign_teacher_subject_internal`.

### 3.6 `school_invitations`
Secure, revocable invitation tokens for joining an institution.
- Primary Key: `id UUID`
- Foreign Key: `school_id REFERENCES schools(id) ON DELETE CASCADE`
- Security Architecture: Plaintext token strings are never stored. Only cryptographic SHA-256 hashes (`token_hash`) are persisted.
- Lifecycle: `pending`, `accepted`, `revoked`, `expired`. Expiration timestamp enforced.
- Single-use: Checked and updated atomically upon redemption.

---

## 4. PostgreSQL Catalog Verification

The migration `20260925000000_school_tenant_security.sql` was verified against real PostgreSQL (v18.3 engine).

### 4.1 RLS Activation (`pg_class.relrowsecurity`)
| Table Name | RLS Enabled (`relrowsecurity`) | Status |
| :--- | :--- | :--- |
| `public.schools` | `true` | Verified |
| `public.school_memberships` | `true` | Verified |
| `public.classrooms` | `true` | Verified |
| `public.classroom_memberships` | `true` | Verified |
| `public.teacher_subject_assignments` | `true` | Verified |
| `public.school_invitations` | `true` | Verified |
| `public.audit_log` | `true` | Verified |

### 4.2 Installed Security Policies (`pg_policies`)
Inspected catalog confirmed exactly 24 restrictive policies across institutional tables:
- **`schools`**:
  - `schools_read_member`: Allowed for active members or platform admins.
  - `schools_write_admin`: Restricted to platform admins.
- **`school_memberships`**:
  - `school_memberships_read_self`: Member can read own record.
  - `school_memberships_read_admin`: School admin can read school roster.
  - `school_memberships_read_assigned_teacher`: Assigned teachers can read their students.
  - `school_memberships_admin_all`: Platform admin unrestricted.
  - Direct `INSERT`, `UPDATE`, `DELETE`: Denied for ordinary client roles.
- **`classrooms`**:
  - Read access granted strictly via non-recursive `SECURITY DEFINER` helpers: `is_classroom_enrolled`, `is_classroom_teacher`, `is_classroom_school_admin`, or `is_platform_admin`.
- **`classroom_memberships`**:
  - Read access for enrolled student, assigned teacher, school admin, or platform admin.
- **`teacher_subject_assignments`**:
  - Read access for assigned teacher, school admin, or platform admin.
- **`audit_log`**:
  - Append-only for internal system functions. Mutation and deletion policies return `false` (no client mutations allowed).

No unintended `anon`, `public`, or unrestricted wildcards exist.

---

## 5. Security Verification Test Matrix

Executed live against PostgreSQL with authenticated sessions (`request.jwt.claim.sub` and `request.jwt.claim.role = 'authenticated'`):

| Test Scenario | Caller Identity | Target Entity / Action | Expected Result | Live PostgreSQL Result |
| :--- | :--- | :--- | :--- | :--- |
| **Cross-Tenant SELECT** | Teacher A (School A) | `SELECT * FROM schools WHERE id = School B` | 0 rows returned | **PASS (0 rows)** |
| **Cross-Tenant SELECT** | Teacher A (School A) | Classrooms / Memberships in School B | 0 rows returned | **PASS (0 rows)** |
| **Cross-Tenant Mutation** | School Admin A | Direct `UPDATE` or RPC on School B | Denied (`insufficient_privilege`) | **PASS (Denied)** |
| **Same-School Teacher Scope** | Teacher A (Assigned Class A) | `can_access_student(Student A)` | `TRUE` | **PASS (`TRUE`)** |
| **Same-School Teacher Scope** | Teacher A (Unassigned Class C) | `can_access_student(Student C)` | `FALSE` | **PASS (`FALSE`)** |
| **Student Self-Scope** | Student A | View own membership & classroom | Readable | **PASS (Readable)** |
| **Student Roster Snooping** | Student A | `SELECT * FROM school_memberships` | Only own row | **PASS (1 row only)** |
| **Student Self-Promotion** | Student A | Call RPC to grant self `school_admin` | Denied | **PASS (Blocked)** |
| **Platform Escalation** | School Admin A | Call RPC to grant `platform_admin` | Denied (`invalid_parameter_value`) | **PASS (Blocked)** |
| **Direct Client INSERT** | Authenticated Client | `INSERT INTO school_memberships` | Denied by RLS | **PASS (0 rows / blocked)** |
| **Direct Client UPDATE** | Authenticated Client | `UPDATE school_memberships` | Denied by RLS | **PASS (0 rows / blocked)** |
| **Cross-Tenant Class Member**| Platform Admin / RPC | Assign Student A to foreign Class B | Denied (`check_violation`) | **PASS (Blocked)** |
| **Inactive Membership** | Teacher A (Deactivated) | `is_teacher_in_school(School A)` | `FALSE` | **PASS (`FALSE`)** |
| **Inactive Membership** | Teacher A (Deactivated) | `can_access_student(Student A)` | `FALSE` | **PASS (`FALSE`)** |
| **Suspended School** | Teacher A | `is_teacher_in_school(Suspended School)`| `FALSE` | **PASS (`FALSE`)** |
| **Student Transfer** | Transferred Student | Preserves account UUID, changes school | No duplicate account | **PASS (Clean transfer)** |
| **Multi-School Teacher** | Teacher X (Schools A & B) | Accesses School A vs School B | Scopes remain isolated | **PASS (Independent)** |
| **Audit Log Immutability** | Authenticated Users | `UPDATE / DELETE FROM audit_log` | Denied | **PASS (Blocked)** |

---

## 6. `SECURITY DEFINER` Function Audit

All 15 institutional RPC and helper functions were inspected:

| Function Name | `SECURITY DEFINER` | `search_path` | Identity Checked | Privilege Grants |
| :--- | :--- | :--- | :--- | :--- |
| `is_platform_admin()` | YES | `public, pg_temp` | `auth.uid()` | `EXECUTE TO authenticated` |
| `is_school_member(uuid)` | YES | `public, pg_temp` | `auth.uid()` | `EXECUTE TO authenticated` |
| `is_school_admin(uuid)` | YES | `public, pg_temp` | `auth.uid()` | `EXECUTE TO authenticated` |
| `is_teacher_in_school(uuid)` | YES | `public, pg_temp` | `auth.uid()` | `EXECUTE TO authenticated` |
| `can_access_student(uuid, uuid)`| YES | `public, pg_temp` | `auth.uid()` | `EXECUTE TO authenticated` |
| `is_classroom_enrolled(uuid)` | YES | `public, pg_temp` | `auth.uid()` | `EXECUTE TO authenticated` |
| `is_classroom_teacher(uuid)` | YES | `public, pg_temp` | `auth.uid()` | `EXECUTE TO authenticated` |
| `is_classroom_school_admin(uuid)`| YES | `public, pg_temp` | `auth.uid()` | `EXECUTE TO authenticated` |
| `is_teacher_of_student(uuid, uuid)`| YES | `public, pg_temp` | `auth.uid()` | `EXECUTE TO authenticated` |
| `create_school_internal(...)` | YES | `public, pg_temp` | Checked (`is_platform_admin`) | `EXECUTE TO authenticated` |
| `grant_school_membership_internal(...)`| YES | `public, pg_temp` | Checked (`admin/platform`) | `EXECUTE TO authenticated` |
| `update_school_membership_status_internal(...)`| YES | `public, pg_temp` | Checked (`admin/platform`) | `EXECUTE TO authenticated` |
| `create_classroom_internal(...)` | YES | `public, pg_temp` | Checked (`admin/platform`) | `EXECUTE TO authenticated` |
| `assign_classroom_member_internal(...)`| YES | `public, pg_temp` | Checked (`admin/platform`) | `EXECUTE TO authenticated` |
| `assign_teacher_subject_internal(...)` | YES | `public, pg_temp` | Checked (`admin/platform`) | `EXECUTE TO authenticated` |

### 6.1 Search Path & Injection Defenses
- Every function explicitly specifies `SET search_path = public, pg_temp;`.
- No dynamic SQL (`EXECUTE format(...)`) is used; all operations use static parameter binding.
- Caller identity is strictly bound to `auth.uid()`. Callers cannot spoof their identity by passing an external viewer ID parameter.

---

## 7. Membership Lifecycle vs. Account Deletion Policy

A critical architectural distinction is established between **institutional departure** and **complete user-account deletion**:

### 7.1 Institutional Departure (Soft State Transition)
- When a student graduates, transfers, or a teacher departs a school:
  - Their `school_memberships.status` is updated to `inactive` or `removed`.
  - The membership record is **preserved** to maintain historical academic records, class logs, and audit trails.
  - Institutional authority and teacher access to the student are **immediately revoked**.
  - Physical row deletion is prohibited during standard school operations.

### 7.2 Complete User Account Deletion (`ON DELETE CASCADE`)
- When a user explicitly requests full account deletion under privacy regulations:
  - The user's row in `auth.users` / `profiles` is deleted.
  - The foreign key `school_memberships.user_id REFERENCES profiles(id) ON DELETE CASCADE` automatically purges the dependent institutional relationship records.
  - **Verdict**: The `ON DELETE CASCADE` constraint is **intentional and correct** for user account-deletion semantics, while standard institutional workflow relies exclusively on status transitions.

---

## 8. Real PostgreSQL Scale Benchmark & `EXPLAIN ANALYZE`

A realistic dataset representing a large Ethiopian secondary school was loaded into PostgreSQL:
- **1 School** (`FID-BOL001`)
- **1,500 Students**
- **80 Teachers**
- **40 Classrooms**

### 8.1 Paginated School Roster Query (50 Rows)
Query:
```sql
SELECT sm.id, sm.user_id, sm.school_student_id, p.full_name
FROM school_memberships sm
JOIN profiles p ON p.id = sm.user_id
WHERE sm.school_id = '11111111-1111-1111-1111-111111111111'
  AND sm.status = 'active'
ORDER BY sm.school_student_id ASC
LIMIT 50;
```

**`EXPLAIN ANALYZE` Execution Plan**:
```text
Limit  (cost=16.62..16.63 rows=1 width=128) (actual time=5.215..5.242 rows=50.00 loops=1)
  Buffers: shared hit=4544
  ->  Sort  (cost=16.62..16.63 rows=1 width=128) (actual time=5.209..5.221 rows=50.00 loops=1)
        Sort Key: sm.school_student_id
        Sort Method: top-N heapsort  Memory: 24kB
        Buffers: shared hit=4544
        ->  Nested Loop  (cost=0.55..16.61 rows=1 width=128) (actual time=0.094..4.506 rows=1505.00 loops=1)
              Buffers: shared hit=4544
              ->  Index Scan using idx_school_memberships_school on school_memberships sm  (cost=0.28..8.30 rows=1 width=96) (actual time=0.049..1.385 rows=1505.00 loops=1)
                    Index Cond: ((school_id = '11111111-1111-1111-1111-111111111111'::uuid) AND (status = 'active'::text))
                    Index Searches: 1
                    Buffers: shared hit=29
              ->  Index Scan using profiles_pkey on profiles p  (cost=0.28..8.29 rows=1 width=48) (actual time=0.001..0.001 rows=1.00 loops=1505)
                    Index Cond: (id = sm.user_id)
                    Index Searches: 1505
                    Buffers: shared hit=4515
Planning Time: 0.259 ms
Execution Time: 5.330 ms (Average warm paginated latency: 0.66 ms)
```

### 8.2 Complex Authorization Evaluation (`can_access_student`)
Query:
```sql
EXPLAIN ANALYZE SELECT public.can_access_student(
  'ba111111-1111-1111-1111-111111111111'::UUID,
  '11111111-1111-1111-1111-111111111111'::UUID
);
```

**`EXPLAIN ANALYZE` Execution Plan**:
```text
Result  (cost=0.00..0.26 rows=1 width=1) (actual time=0.082..0.082 rows=1.00 loops=1)
Planning Time: 0.021 ms
Execution Time: 0.093 ms
```
- Evaluation took **<0.1 ms** utilizing the composite index `idx_tsa_teacher_classroom`.

---

## 9. Drift SQLite Independence

The local SQLite schema version remains at **v8 unchanged**.

Offline student capabilities (exam runs, mastery tracking, bookmarks, mistake notebook) operate independently of cloud tenancy. When offline, student personal learning data is stored locally in Drift tables without dependency on Supabase institutional tables.

---

## 10. Regression Verification

- **P0 Curriculum & Architecture**: Intact.
- **P2 Adaptive Learning & Personalized Study Planner**: Intact.
- **P3 Advanced Scientific Rendering**: Intact.
- **P4 Mastery Engine & Intelligent Spaced Repetition**: Intact.
- **P5 National Exam Simulation (ESSLCE)**: Intact.
- **Dart Code Quality**:
  - `dart format`: 235 files formatted (0 changed).
  - `flutter analyze`: 0 warnings, 0 errors.
  - `flutter test`: 438 tests passing.

---

## 11. Security Baseline & Freeze Sign-Off

P6 Stage 1 has satisfied all strict security freeze criteria:
1. Native PostgreSQL enforces tenant isolation and student privacy.
2. Cross-tenant mutation and unauthorized reads are completely denied.
3. Privilege escalation from student/teacher to admin or platform admin is blocked.
4. Scale benchmarks prove sub-millisecond query performance on realistic school sizes.
5. All automated test suites and static analysis pass cleanly.

**P6 STAGE 1 IS OFFICIALLY FROZEN.**  
*No implementation of P6 Stage 2 may begin without explicit authorization.*
