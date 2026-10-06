# Pilot School Onboarding & Operational Checklist

## 1. Commercial & Institutional Provisioning
- [ ] **School Entity Created**: Name, code, region, and city registered in `public.schools`.
- [ ] **License Provisioned**: Plan code selected (`school_standard` or `school_premium`), valid dates set (`starts_at`, `ends_at`), and `student_seat_limit` assigned.
- [ ] **Entitlements Verified**: `teacher_portal`, `leadership_dashboard`, `assignments_interventions`, and `institutional_reporting` active.
- [ ] **School Admin Invited**: Admin phone/email credential created, membership assigned with role `school_admin`.

## 2. Academic Structure Configuration
- [ ] **Academic Year Defined**: Primary academic year (e.g., `2026/27`) configured as default.
- [ ] **Classrooms Created**: Natural Science and Social Science sections registered with status `active`.
- [ ] **Streams Validated**: Class stream attributes correctly match national curriculum definitions.

## 3. Faculty & Subject Assignments
- [ ] **Teachers Enrolled**: Teachers added to `public.school_memberships` with role `teacher`.
- [ ] **Subject Allocations**: Teacher subject assignments created per classroom:
  - Natural Science sections assigned: Biology, Physics, Chemistry, English, Natural Math, Civics.
  - Social Science sections assigned: History, Geography, Economics, English, Social Math, Civics.
- [ ] **Math Variant Segregation**: Confirmed Natural sections assigned `naturalScience` variant, Social sections assigned `socialScience` variant.

## 4. Student Roster & Seat Enforcement
- [ ] **Bulk Import Executed**: Student roster ingested via `institutional_import_runs`.
- [ ] **Seat Utilization Validated**: Ingested student count <= licensed seat capacity (`get_school_seat_usage`).
- [ ] **Classroom Enrollments Verified**: Each student enrolled in appropriate classroom section (`classroom_memberships`).
- [ ] **No Cross-Tenant Leaks**: Verified zero duplicate IDs or misassigned students.

## 5. Device & Content Readiness
- [ ] **Offline Packages Installed**: Verified Grade 12 curriculum packages (`.flpkg`) installed on student devices via `AtomicPackageInstaller`.
- [ ] **Offline Content Integrity**: Packages verified via SHA-256 hash checks.
- [ ] **Student Offline Practice**: Student completes mock exam in airplane mode; score and mistake notebook recorded locally in Drift SQLite.
- [ ] **Reconnection & Sync**: Reconnection drains sync queue into Supabase `attempts` table without duplicate records.

## 6. Portals & Reporting Validation
- [ ] **Teacher Portal Tested**: Teacher logs in, views assigned classroom roster, weak topics, and publishes a practice assignment.
- [ ] **Student Inbox Tested**: Student receives published assignment, submits completion, and receives results.
- [ ] **Leadership Dashboard Tested**: School Admin logs in, views stream averages, and confirms student participation.
- [ ] **Executive Report Tested**: School Admin generates institutional executive summary report.

## 7. Pilot Sign-Off
- [ ] **Support Contact Established**: School designated operational focal point assigned to FidelLearn support lead.
- [ ] **Zero Database Edits**: School fully provisioned through standard application flows with zero direct manual SQL repairs.
