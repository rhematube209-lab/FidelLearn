# FidelLearn — Priority 10 (P10) Institutional Analytics & Reporting Freeze

**Document Status:** FROZEN & RATIFIED  
**Analytics Engine Version:** `institutional_analytics_v1`  
**Report Schema Version:** `institutional_report_schema_v1`  
**Intervention Methodology Version:** `intervention_followup_v1`  
**Database Schema Target:** Drift SQLite local (v9 schema unchanged) & Supabase PostgreSQL (`20260925040000_p10_institutional_reporting.sql`)  
**Freeze Commit Tag:** `priority-10-institutional-reporting`

---

## 1. Executive Summary & Freeze Invariants

Priority 10 (P10) Institutional Analytics & Reporting establishes an enterprise-grade, privacy-preserving, multi-tenant analytical framework for school leadership and instructional staff across secondary schools preparing for the Ethiopian Secondary School Leaving Certificate Examination (ESSLCE).

This hardening pass reconciles all reporting implementations with frozen contracts from P0 through P9:
1. **Canonical Multi-Tenancy**: All student, teacher, and instructional mappings query the canonical tenant tables: `public.school_memberships`, `public.classroom_memberships`, and `public.teacher_subject_assignments`. Parallel or legacy table names (`classroom_students`, `school_teachers`, `classroom_teachers`) have been completely eliminated from SQL functions, models, tests, and documentation.
2. **Authority & Role Boundaries**: Every PostgreSQL reporting function executes as `SECURITY DEFINER` with fixed `SET search_path = public, pg_temp` and calls `validate_report_authority(...)`. Students are strictly denied access to all institutional reporting endpoints. Teachers are bounded to their assigned classrooms and subjects. Cross-tenant leakage is mathematically impossible under tenant isolation.
3. **P5 Provenance Normalization**: Reports preserve canonical exam provenance (`officialHistoricalPaper`, `verifiedModelPaper`, `generatedSimulation`, `nationalSimulation`, `custom`, `unit_test`, `teacher_assigned`) via `ExamProvenanceHelper` across P7, P8, P9, and P10.
4. **Non-Causal Academic Evidence**: Post-intervention score changes are reported strictly as observed academic longitudinal evidence with pre- and post-intervention sample counts and confidence tiers (`sufficient`, `limited`, `insufficient`). Causation is explicitly disclaimed in all UI screens, CSV headers, printable summaries, and PDF documents.
5. **Separation of Enrollment and Active Evidence**: Institutional reports cleanly split `active_enrolled_students` (active school memberships) from `students_with_academic_evidence` (students with at least one synchronized exam attempt during the window).
6. **Strict Timeliness Denominators**: Timeliness percentages are derived strictly from verified timing anchors:
   $$\text{Verified On-Time Rate} = \frac{\text{verified\_on\_time}}{\text{verified\_on\_time} + \text{verified\_late}}$$
   Unverified timing records and device clock anomalies are accounted for and reported as discrete indicators, never mixed into rate denominators.
7. **Standards-Compliant PDF Binary Generation**: Pure Dart PDF 1.4 generation produces valid binary `%PDF-1.4...%%EOF` artifacts with cryptographic SHA-256 integrity checksums.
8. **Device-Local P4 Mastery Non-Fabrication**: P4 adaptive spaced mastery and national readiness scores remain device-local and are never synthesized or faked into cloud institutional reports.

---

## 2. Canonical Tenant Schema Alignment

All P10 functions and models reference the frozen tenant architecture:

| Domain Entity | Canonical PostgreSQL Table | Description |
| :--- | :--- | :--- |
| School Membership | `public.school_memberships` | Authoritative tenant affiliation (`school_admin`, `teacher`, `student`, `staff`). Status: `active`, `suspended`, `transferred`. |
| Classroom Cohort | `public.classroom_memberships` | Student classroom assignment with academic stream (`natural`, `social`, `common`) and enrollment status (`active`, `transferred`, `dropped`). |
| Instructional Slot | `public.teacher_subject_assignments` | Teacher-subject-classroom assignments. Forms the basis for instructional coverage and teacher authorization scoping. |

Documentation and code comments have been audited to ensure zero references to deprecated legacy structures.

---

## 3. The 11 Canonical Institutional Report Types

P10 supports exactly 11 canonical institutional report types:

| # | Report Enum | Title (English) | Title (Amharic) | PostgreSQL Aggregation RPC | Target Audience |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | `executive` | School Executive Report | የትምህርት ቤት አመራር ሪፖርት | `get_institutional_executive_report` | School Admin, Platform Admin |
| 2 | `subjectPerformance` | Subject Performance Report | የትምህርት አይነት ውጤት ሪፖርት | `get_subject_performance_report` | School Admin, Assigned Teacher |
| 3 | `streamPerformance` | Stream Performance Report | የስትሪም ንጽጽር ሪፖርት | `get_stream_performance_report` | School Admin, Platform Admin |
| 4 | `classPerformance` | Class / Section Report | የክፍል / ሴክሽን ሪፖርት | `get_class_performance_report` | School Admin, Assigned Teacher |
| 5 | `assessment` | Assessment & Simulation Report | የፈተና እና ሲሙሌሽን ሪፖርት | `get_assessment_report` | School Admin, Assigned Teacher |
| 6 | `assignmentOutcomes` | Assignment Outcomes Report | የተግባር ስራ ውጤቶች ሪፖርት | `get_assignment_outcomes_report` | School Admin, Assigned Teacher |
| 7 | `interventionFollowUp` | Intervention Follow-Up Report | የድጋፍ ክትትል ማስረጃ ሪፖርት | `get_intervention_followup_report` | School Admin, Assigned Teacher |
| 8 | `studentSupport` | Student Support Report | ተጨማሪ ድጋፍ የሚሹ ተማሪዎች ሪፖርት | `get_student_support_report` | School Admin, Assigned Teacher |
| 9 | `dataCoverage` | Data Coverage & Freshness Report | የዳታ ሽፋን እና የሰዓት ትክክለኛነት ሪፖርት | `get_data_coverage_report` | School Admin, Platform Admin |
| 10 | `teacherCoverage` | Teacher Coverage Report | የመምህራን ምደባ ሽፋን ሪፖርት | `get_teacher_coverage_report` | School Admin, Platform Admin |
| 11 | `studentAcademic` | Student Academic Report | የተማሪ ግላዊ የትምህርት ሪፖርት | `get_student_academic_report` | School Admin, Authorized Teacher |

---

## 4. Security & Role-Based Access Control (RBAC)

Authority validation executes on the database server before any analytics aggregation:

```text
                                Caller Request
                                      │
                                      ▼
                      validate_report_authority(school_id)
                                      │
           ┌──────────────────────────┴──────────────────────────┐
           │                                                     │
           ▼                                                     ▼
     Student Role                                        Staff / Admin Role
           │                                                     │
   [RAISE EXCEPTION 42501]                                       ▼
 "REPORTING_NOT_AUTHORIZED:                              Active Membership?
  Students cannot access"                                        │
                                              ┌──────────────────┴──────────────────┐
                                              │                                     │
                                              ▼                                     ▼
                                             Yes                                   No
                                              │                                     │
                                              ▼                             [RAISE EXCEPTION]
                                    Is Platform Admin?                       "NOT_AUTHORIZED:
                                              │                               No active membership"
                               ┌──────────────┴──────────────┐
                               │                             │
                               ▼                             ▼
                              Yes                           No
                               │                             │
                       [GRANT ACCESS]                        ▼
                                                     Is School Admin?
                                                             │
                                              ┌──────────────┴──────────────┐
                                              │                             │
                                              ▼                             ▼
                                             Yes                            No (Teacher)
                                              │                             │
                                      [GRANT ACCESS                  Is Report Scoped
                                       to own school]                to Assigned Class/Subject?
                                                                            │
                                                              ┌─────────────┴─────────────┐
                                                              │                           │
                                                              ▼                           ▼
                                                             Yes                          No
                                                              │                           │
                                                        [GRANT ACCESS]            [RAISE EXCEPTION]
                                                                                  "Teacher unauthorized
                                                                                   for unassigned cohort"
```

### Policy Rules
1. **Students**: Strictly denied from all reporting RPCs (`REPORTING_NOT_AUTHORIZED: Students cannot access institutional reports`).
2. **Teachers**:
   - Access strictly restricted to classes and subjects assigned in `public.teacher_subject_assignments`.
   - Denied from cross-school reports, unassigned sections, and unassigned subjects.
   - Denied from school-wide leadership summaries (Executive, Stream, Teacher Coverage).
3. **School Admins**:
   - Authorized for all reports within their active school tenant.
   - Strictly blocked from cross-school report execution.
4. **Platform Admins**:
   - Server-side validated via `public.profiles.is_platform_admin = true` and service credentials.
   - Authorized across school tenants for administrative and compliance audits.
5. **Legacy / Global Roles**:
   - Deprecated global role claims (`profiles.role = 'school_admin'`) without active tenant memberships in `public.school_memberships` are rejected.

---

## 5. Analytical Invariants & Provenance Rules

### 5.1 Mathematics Stream Isolation
- Grade 12 Natural Science Mathematics (`math_g12` with `exam_variant = 'naturalScience'`) and Social Science Mathematics (`math_g12` with `exam_variant = 'socialScience'`) are treated as separate canonical subjects.
- Student attempt queries strictly match the student's classroom stream to prevent cross-stream contamination.

### 5.2 P5 Provenance Normalization
The `AssessmentReportRow.provenanceLabel` delegates directly to `ExamProvenanceHelper`:
- `officialHistoricalPaper` $\to$ **Official Historical Paper**
- `verifiedModelPaper` $\to$ **Verified Model Exam**
- `generatedSimulation` (with `mock_full`) $\to$ **FidelLearn ESSLCE Simulation**
- `custom` / `custom_builder` $\to$ **Custom Exam**
- `unit_test` $\to$ **Unit Test**
- `teacher_assigned` $\to$ **Teacher Assignment**

### 5.3 Intervention Follow-Up Methodology (`intervention_followup_v1`)
- **Baseline Window**: 30 days prior to intervention creation (`created_at - 30 days` to `created_at`).
- **Completion Anchor**: Evaluated strictly from the teacher completion timestamp (`completed_at`). Interventions without `completed_at` or in non-completed status (`open`, `active`) return:
  - `evidence_status = 'not_yet_eligible'`
  - `followup_accuracy = NULL`
  - `observed_change_pp = NULL`
  - `confidence = 'insufficient'`
- **Follow-Up Window**: 30 days following verified completion (`completed_at` to `completed_at + 30 days`).
- **Confidence Scoring**:
  - `sufficient`: $\ge 3$ attempts pre and post.
  - `limited`: 1 or 2 attempt pairs.
  - `insufficient`: Missing pre or post assessment evidence.
- **Mandatory Non-Causal Footnote**:
  > *"Observed change reflects academic performance recorded after intervention completion. Causation is not established."*

### 5.4 Synchronization Freshness
Derived from real academic sync evidence (`attempts.created_at`, `mistake_records.last_failed_at`), reusing frozen P7/P8 policy:
- $\le 2$ days: **Fresh**
- $3$ to $7$ days: **Moderate**
- $8$ to $14$ days: **Stale**
- $> 14$ days: **Very Stale**
- Missing / zero activity: **Unknown**

Fresh Data Coverage Rate is calculated as:
$$\text{Fresh Coverage Rate} = \frac{\text{fresh\_sync} + \text{moderate\_sync}}{\text{active\_enrolled\_students}} \times 100$$

### 5.5 Privacy Suppression ($k = 5$)
Any cohort, section, or subject aggregation cell representing fewer than 5 unique students ($n < 5$) is masked:
- `average_score = NULL`
- `median_score = NULL`
- `privacy_suppressed = true`
- CSV export label: `[SUPPRESSED n<5]`
- PDF export label: `Suppressed (n<5 for Privacy)`

---

## 6. Document & Data Export Specifications

### 6.1 Standards-Compliant PDF Exporter (`InstitutionalPdfExporter`)
- Pure Dart implementation generating valid ISO 32000-1 / PDF 1.4 binary byte streams.
- Magic bytes: `%PDF-1.4\n%\xE2\xE3\xCF\xD3\n` at byte offset 0.
- Proper catalog, page tree, font resource dictionaries, text streams, and cross-reference table (`xref`).
- Multi-page page-breaking with running headers, footers (`Page X of Y`), data-as-of timestamps, and methodology caveats.
- SHA-256 calculation over raw bytes for tamper-evident storage and signed URL serving.
- **Amharic PDF Glyph Limitation**: Standard PDF Type 1 fonts (Helvetica) support WinAnsi Latin-1 encoding. High-fidelity Ethiopic / Amharic Unicode glyph rendering requires TrueType font embedding (`.ttf`), which is documented as a known limitation for future binary packaging.

### 6.2 RFC 4180 CSV Exporter (`InstitutionalCsvExporter`)
- Compliant with RFC 4180: CRLF `\r\n` row terminators, escaped double quotes `""`.
- **Formula Injection Mitigation (OWASP)**: Any cell beginning with `=`, `+`, `-`, `@`, `\t`, or `\r` is automatically prepended with a single quote (`'`).
- Preserves UTF-8 multi-byte encoding for Amharic text labels.
- Zero PII inclusion: Student phone numbers, email addresses, password hashes, Study Coin balances, and push notification tokens are strictly excluded from all export formats.

### 6.3 Offline Production Policy
- `LocalInstitutionalReportingRepository` is strictly restricted to automated unit/widget tests and developer mock setups.
- In production, institutional reports require active cloud connectivity. If Supabase is unreachable, the system displays:
  > *"Institutional reports require an internet connection. Reconnect to load current synchronized analytics."*
- No canned or synthetic school data is ever presented in production environments.

### 6.4 Data Retention Policy
- FidelLearn Product Default: **3 years** retention for report run records and generated artifact snapshots.
- Stored as documented product policy default (not claimed as an unverified statutory legal requirement).

---

## 7. Verification & Regression Matrix

| Test Suite | File | Tests Run | Result |
| :--- | :--- | :---: | :---: |
| PostgreSQL Tenancy Baseline | `tools/test_postgres_tenancy.js` | 24 | **PASS** |
| PostgreSQL P7 Teacher Portal | `tools/test_postgres_p7_teacher_portal.js` | 20 | **PASS** |
| PostgreSQL P8 School Leadership | `tools/test_postgres_p8_leadership.js` | 16 | **PASS** |
| PostgreSQL P9 Assignments + Interventions | `tools/test_postgres_p9_assignments.js` | 23 | **PASS** |
| PostgreSQL P10 Institutional Reporting | `tools/test_postgres_p10_reporting.js` | 52 | **PASS** |
| **Total PostgreSQL RPC Checks** | | **135** | **100% PASS** |
| Flutter Full Suite Regression | `flutter test` | 555 | **555 / 555 PASS** |
| Flutter Analyzer | `flutter analyze --no-pub` | 300 files | **0 issues** |
| Dart Code Formatter | `dart format --output=none --set-exit-if-changed` | 300 files | **0 changes (Clean)** |
| Drift SQLite Schema | `lib/core/database/` | v9 | **Unchanged** |

---

## 8. Sign-Off & Freeze Declaration

All Priority 10 institutional analytics and reporting contracts are reconciled, hardened, and frozen. No further modifications or feature expansions may be introduced to P10. Transition to Priority 11 (P11) requires explicit user authorization.
