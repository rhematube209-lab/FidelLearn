# P9 — Assignments + Intervention System Hardening & Freeze

**Milestone**: Priority 9 (P9) — Assignments + Intervention System  
**Status**: **P9 FINAL PRODUCTION FREEZE APPROVED**  
**Date**: October 3, 2026  
**Baseline Git Commit**: `6cd051d79a58378624bfb541716c530ef5447ab4`  
**Baseline Git Tag**: `priority-9-assignments-interventions-v1.0.0`  
**Drift SQLite Schema Version**: `v9`  
**Supabase PostgreSQL Migration Baseline**: `supabase/migrations/20260925030000_p9_assignments_interventions.sql`  

---

## 1. Executive Summary & Freeze Verification

The Assignments + Intervention System (P9) has completed its comprehensive architectural hardening, recipient-level security verification, offline deadline integrity reconciliation, and content immutability freeze pass. All 56 hardening mandates have been satisfied without altering frozen P0–P8 foundations:

1. **Recipient-Level Assignment Access**: Enrollment in a classroom alone does **not** grant a student access to assignments. RLS and RPC queries strictly mandate an explicit recipient row (`learning_assignment_recipients.student_user_id = auth.uid()`). Same-class non-recipients receive 0 rows, 0 metadata, and 0 question snapshots.
2. **Immutable Question & Recipient Publication Snapshots**: Publication freezes both the recipient roster (`original_recipient_count`) and question payloads (`question_snapshot JSONB` containing stem, options, correct answer key, diagrams, and scoring rules). Subsequent content package updates (v1 → v2) do not alter active or historical assignment content.
3. **P5 Provenance Integrity**: Preserves 3 orthogonal dimensions without inventing new enum values: `exam_type` (`teacherAssigned`), `exam_mode` (`practice`, `custom`, `nationalSimulation`, `historicalPaper`), and `source_type` (`officialHistoricalPaper`, `verifiedModelPaper`, `generatedSimulation`). Provenance is normalized centrally via `ExamProvenanceHelper`.
4. **Canonical Assignment Domain Taxonomy**: Standardized domain enum (`targetedPractice`, `customQuestionSet`, `simulation`) mapped transparently to database strings and localized UI labels. Pedagogical strategies (Remedial Drill, Topic Quiz) remain UI/targeting subtypes.
5. **Offline Deadline Integrity**: Authoritative local completion time (`attempt_completed_at`) is decoupled from cloud synchronization time (`server_received_at`). Offline completions prior to deadlines are not marked late upon delayed synchronization. Clock tampering or timer anomalies trigger `offline_completion_time_unverified`.
6. **Privileged Teacher Mutation Gate**: Institutional actions (`publish_learning_assignment`, `add_assignment_recipient`, `close_learning_assignment`, `archive_learning_assignment`, `create_student_intervention`, `complete_student_intervention`) require online server confirmation. Local offline mutations fail closed; local drafts remain explicitly flagged as "Local Draft / Not Published".
7. **Drift v9 Non-Destructive Migration & Client Privacy**: Migration from v8 to v9 creates `db_learning_assignments` and `db_assignment_recipients` without data loss. Student devices persist **only** their own recipient row; peer recipient data is never stored on student devices. Teacher analytics remain cloud-only in P9 MVP.
8. **P7 Attention Reason Code Snapshot**: All reason codes (`lowRecentAccuracy`, `highMistakeCount`, `noRecentActivity`, `borderlineAccuracy`, `elevatedMistakes`, `noPracticeData`, `overduePractice`) from P7 `teacher_attention_v1` are preserved at intervention creation alongside `policy_version` and `severity_at_creation`.
9. **Pedagogical Invariant**: `completed intervention ≠ academic weakness resolved`. Interventions track teacher action, while academic mastery is resolved strictly via student practice in `fidel_spaced_v1.0`.
10. **Canonical Mathematics Exact Variant Isolation**: `math_g12` natural and social variants are strictly separated (`naturalScience` vs `socialScience`) with zero stream fallback.

---

## 2. Recipient-Level Authorization & Security Architecture

### 2.1 The Multi-Recipient Granularity Model
P9 supports three assignment allocation scopes:
- **Entire Class**: Every active enrolled student receives a recipient record at publication.
- **Selected Students**: Only explicitly designated student UUIDs receive recipient records.
- **Single Student (Targeted Remediation)**: Exactly one student receives a recipient record.

### 2.2 Authoritative Database Authorization Rule
Enrollment in a classroom is a necessary prerequisite for selection, but **never** sufficient for assignment visibility:

$$\text{Student Authorized} \iff \exists\, r \in \texttt{learning\_assignment\_recipients} \mid r.\text{assignment\_id} = a.\text{id} \land r.\text{student\_user\_id} = \text{auth.uid()}$$

### 2.3 Row Level Security (RLS) Specification

| Table | Operation | Policy Definition & Enforcement |
| :--- | :--- | :--- |
| `learning_assignments` | `SELECT` | **Teachers/Admins**: Enrolled teacher via `can_teacher_manage_assignment(id)` or `is_school_admin()`.<br>**Students**: Published status **AND** `EXISTS (SELECT 1 FROM learning_assignment_recipients r WHERE r.assignment_id = learning_assignments.id AND r.student_user_id = auth.uid())`. |
| `learning_assignment_questions` | `SELECT` | **Teachers/Admins**: Via assignment management check.<br>**Students**: `EXISTS (SELECT 1 FROM learning_assignment_recipients r WHERE r.assignment_id = learning_assignment_questions.assignment_id AND r.student_user_id = auth.uid())`. |
| `learning_assignment_recipients` | `SELECT` | **Teachers/Admins**: Via assignment management check.<br>**Students**: Strictly `student_user_id = auth.uid()` (own row only). |
| `student_interventions` | `SELECT` | **Teachers/Admins**: Classroom teacher or school admin.<br>**Students**: Denied (interventions are teacher pedagogical tools). |

### 2.4 Selected-Student Isolation Matrix

```
Class A (School A)
├── Student A (Enrolled)
└── Student B (Enrolled)

Assignment X (Class A, assigned to Student A ONLY)
├── Student A Query:
│   ├── learning_assignments:            ALLOWED (1 row)
│   ├── learning_assignment_questions:  ALLOWED (Question snapshots accessible)
│   ├── learning_assignment_recipients: ALLOWED (Own row accessible)
│   └── get_student_assignment_detail:  ALLOWED (Full assignment payload)
│
└── Student B Query:
    ├── learning_assignments:            DENIED (0 rows)
    ├── learning_assignment_questions:  DENIED (0 rows)
    ├── learning_assignment_recipients: DENIED (0 rows)
    └── get_student_assignment_detail:  DENIED (NOT_AUTHORIZED exception)
```

Gate 13 is definitively reconciled: **"Not present in `learning_assignment_recipients`"** produces complete access denial, irrespective of classroom membership.

---

## 3. Publication Snapshots & Post-Publication Additions

### 3.1 Recipient Cohort & Historical Denominator
Audit of the Supabase PostgreSQL migration (`supabase/migrations/20260925030000_p9_assignments_interventions.sql`) confirms that the stored procedure `add_assignment_recipient(p_assignment_id, p_student_id, p_reason)` is actively supported. Therefore, recipient cohort semantics are strictly distinguished:

1. **Original Publication Cohort (`originalAssigned`)**: Recorded at publish time in `learning_assignments.original_recipient_count`. This is an immutable historical snapshot that never changes, even if students subsequently transfer or are added.
2. **Post-Publish Addenda**: Created via `add_assignment_recipient(p_assignment_id, p_student_id, p_reason)`. Each record sets `added_post_publish = TRUE`, `added_by = auth.uid()`, `added_at = NOW()`, and `added_reason = p_reason`. Re-adding an existing recipient is an idempotent no-op.
3. **Excused / Transferred Students**: When a student leaves or is excused from an assignment:
   - The student remains recorded in the historical `originalAssigned` cohort for auditability.
   - The student is **excluded** from the `requiredForCompletion` denominator to ensure neither student nor teacher completion statistics are penalized.
4. **Authoritative Denominator Formula**:

$$\text{originalAssigned} = \text{Cohort at Publication Time (Permanently Immutable)}$$

$$\text{requiredForCompletion} = \text{originalAssigned} + \text{Audited Post-Publish Additions} - \text{Excused Recipients}$$

$$\text{Completion Rate} = \frac{\text{Submitted} + \text{Completed}}{\text{requiredForCompletion}}$$

---

## 4. Question Snapshot Reproducibility & Immutability

### 4.1 Content Snapshot Guarantee & Empirical Verification
A student assigned an exam must be evaluated against the exact text, scientific notation, figures, and answer keys that were approved when the assignment was issued:

```
T1: Publish Assignment A (Package v1, Question Q101 v1)
    └── learning_assignment_questions stores:
        ├── question_id: 'q_chem_101'
        ├── content_version: 1
        ├── package_version: '1.0.0'
        ├── content_hash: 'sha256_...'
        └── question_snapshot: {
              stem: "What is the molar volume of ideal gas at STP?",
              choices: ["22.4 L", "24.0 L", "11.2 L", "44.8 L"],
              correct_index: 0,
              explanation: "At STP (0°C, 1 atm), 1 mol of ideal gas occupies 22.4 L.",
              scientific_assets: ["diagram_molar_stp_v1.png"],
              scoring_rule: "standard_single_choice"
            }

T2: Content Package Update v2 Released
    └── Question Q101 updated in central bank (revised distractor, new explanation, new diagram v2)

T3: Student Executes Assignment A
    └── Runner resolves Question Q101 from question_snapshot (v1 semantics)
    └── Final score matches publication answer key v1
```

Empirically verified in `test/unit/historical_assignment_reproducibility_test.dart` (Test 1):
- Stem v1 loaded ("What is the molar volume of ideal gas at STP?")
- Choices v1 loaded ("22.4 L", "24.0 L", "11.2 L", "44.8 L")
- Answer key v1 loaded (Index 0 = "22.4 L")
- Explanation v1 loaded ("At STP (0°C, 1 atm), 1 mol of ideal gas occupies 22.4 L.")
- Scientific assets v1 loaded (`diagram_molar_stp_v1.png`)
- Even after package v2 is installed, Assignment A does NOT load v2 content.

### 4.2 Runtime Historical Version Resolution Mechanism
The runtime resolves `(question_id, question_content_version, package_version)` as follows:
1. **Assignment Publication**: The publication transaction stores complete frozen question payloads in `learning_assignment_questions.question_snapshot` alongside explicit `content_version` and `package_version` metadata.
2. **Local Execution**: When an assignment is loaded on a client device, the runner resolves question items from the frozen assignment question snapshot. If resolving from local package files, it addresses the specific package version corresponding to `package_version`.
3. **Integrity Guard**: Content hashes are cross-checked against `content_hash` to detect data corruption.

### 4.3 Missing Package Version Policy
If a historical package version required by a downloaded assignment is missing locally and full snapshots are unbundled:
- The runtime **strictly refuses** to silently load the latest available question version or substitute unaligned content.
- Execution halts with an explicit user-facing barrier:
  `"Historical assignment content incomplete or unavailable. Required content package version must be downloaded."`
- The assignment cannot be started until the exact package version is restored.

### 4.4 Historical Submitted Attempt Immutability
Once a student submits an assignment attempt, the attempt result is stored in `db_exam_attempts` with `responses_json`, `score`, `percentage`, `package_snapshot_json`, and `exam_integrity_hash`.
- Reopening the attempt on student or teacher screens reads the persisted attempt snapshot directly.
- **Dynamic rescoring is strictly prohibited**: Even if a subject package update v2 or v3 changes the question's answer key or syllabus weighting, historical attempt scores, percentages, and answer breakdowns remain identical.
- Empirically verified in `test/unit/historical_assignment_reproducibility_test.dart` (Test 2).

---

## 5. P5 Assessment Provenance Architecture

Assignments serve as administrative delivery envelopes around core assessment engines. P9 consumes frozen P5 provenance definitions without redefining or inventing new canonical enum values:
1. `exam_type` / Context: `ExamType.teacherAssigned` (persisted as `'teacher_assigned'`) confirms teacher assignment authority.
2. `exam_mode` / Execution Rules: Consumes canonical P5 `ExamMode` (`practice`, `custom`, `nationalSimulation`, `historicalPaper`).
3. `source_type` / Underlying Origin: Consumes canonical P5 `ExamSourceType` (`officialHistoricalPaper`, `verifiedModelPaper`, `generatedSimulation`).

### 5.1 Authoritative P5 Provenance Matrix for P9

| P9 Assignment | `assignment_type` | `exam_type` (Context) | `exam_mode` | `source_type` | Provenance Notes |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Targeted Practice** | `targetedPractice` | `teacherAssigned` | `practice` | `generatedSimulation` | General curriculum practice items; defaults to canonical P5 `generatedSimulation`. |
| **Custom Question Set** | `customQuestionSet` | `teacherAssigned` | `custom` | `generatedSimulation` (or underlying source) | Teacher-selected question set; inherits source type of items if official or model paper. |
| **Simulation** | `simulation` | `teacherAssigned` | `nationalSimulation` | `generatedSimulation` | Strictly timed national simulation rules; preserves blueprint version, variant, and seed. |
| **Historical Paper** | `customQuestionSet` | `teacherAssigned` | `historicalPaper` | `officialHistoricalPaper` | Teacher-assigned context does **not** erase `officialHistoricalPaper` source provenance. |
| **Verified Model** | `customQuestionSet` | `teacherAssigned` | `custom` | `verifiedModelPaper` | Teacher-assigned context does **not** erase `verifiedModelPaper` source provenance. |

> **Canonical Discipline Note**: P9 does **not** invent `curriculumPractice`, `remedialDrill`, `timedMock`, or `untimedMock`. P9 assignment types (`targetedPractice`, `customQuestionSet`, `simulation`) remain in `assignment_type`, and pedagogical subtypes (e.g. Remedial Drill, Topic Quiz) are UI/targeting strategies, not `source_type` enum values.

### 5.2 P7 / P8 / P9 Provenance Parity
Cross-milestone consistency is enforced via the central `ExamProvenanceHelper.resolveProvenanceLabel()`:
- **P7 Teacher Portal**: `ClassExamSummary` and `StudentExamResult` delegate directly to `ExamProvenanceHelper`.
- **P8 Leadership Dashboard**: `SchoolAssessmentOverviewItem` delegates directly to `ExamProvenanceHelper`.
- **P9 Assignment Results**: Consumes identical label mappings.
- Empirically verified in `test/unit/historical_assignment_reproducibility_test.dart` (Test 4).

---

## 6. Canonical Assignment Taxonomy

| Assignment Type | Persisted String | UI Label (EN) | UI Label (AM) | Pedagogical Strategy / Subtype |
| :--- | :--- | :--- | :--- | :--- |
| `targetedPractice` | `targetedPractice` | Targeted Practice | የታለመ ልምምድ | Focuses on specific learning targets, units, or mistake records (Remedial Drill). Untimed practice. |
| `customQuestionSet` | `customQuestionSet` | Selected Question Set | የተመረጡ የጥያቄዎች ስብስብ | Hand-picked or blueprint-generated question sets, topic quizzes, or assigned past papers. |
| `simulation` | `simulation` | ESSLCE Exam Simulation | የብሔራዊ ፈተና አስመስሎ | Strictly timed, national exam conditions, blueprint-driven. |

---

## 7. Offline Deadline Integrity & Clock Anomaly Policy

### 7.1 Precise Timestamp Field Definitions
To decouple student exam execution from network latency, FidelLearn strictly separates the following four timestamp fields:

| Field Name (Drift / Backend) | Meaning | Authority & Provenance |
| :--- | :--- | :--- |
| `due_at` | Assignment submission deadline | Teacher / Server authoritative |
| `started_at` / `start_time` | Timestamp when student initiated attempt | Client local recording |
| `attempt_completed_at` / `submitted_at` | Local completion time when exam session ended | Authoritative client execution timestamp |
| `server_received_at` / `synced_at` | Timestamp when server receives sync payload | Server authoritative receipt timestamp |

### 7.2 Conceptual Distinction: `completed_at` vs `received_at`
The platform explicitly differentiates between:
- `completed_at`: The actual time the student finalized their answers offline.
- `received_at`: The timestamp when connectivity was restored and the sync queue payload arrived at the Supabase backend.

### 7.3 Offline Deadline Adjudication Matrix (5 Tested Cases)

| Scenario | Local Completion | Deadline | Cloud Sync Time | Clock Integrity | Final Status & Adjudication |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **1. Normal Online** | 16:45 | 17:00 | 16:45 | Valid | **On Time**: Completed and received before deadline. |
| **2. Offline + Valid Clock** | 16:45 | 17:00 | 20:00 | Valid | **On Time**: Completed before deadline; network delay does not penalize student. |
| **3. Offline + Valid Clock (Late)** | 17:20 | 17:00 | 20:00 | Valid | **Late**: Completed after deadline; accepted if `allow_late_submission = true`. |
| **4. Offline + Clock Anomaly** | 16:45* | 17:00 | 20:00 | Anomaly (`timerIntegrityWarning`) | **Accepted + Deadline Timing Unverified**: Absolute completion time cannot be trusted; student work is preserved and flagged for teacher oversight. |
| **5. Late Prohibited Policy** | 17:20 | 17:00 | 20:00 | Valid (`allow_late = false`) | **Submitted**: Work accepted and recorded; score preserved; late flag prevents silent deletion. |

### 7.4 Clock Integrity & Student Data Preservation Invariant
1. **Monotonic Timer Limitations**: The monotonic timer proves elapsed session duration, but without a persistent trusted server-time anchor in offline mode, it cannot reconstruct absolute UTC completion time.
2. **Honest Reporting**: If clock divergence or backward time shifts occur (`timerIntegrityWarning = true`), the system refuses to falsely certify completion as "on time". Instead, the deadline status is recorded as `deadline_integrity = 'unverified'`.
3. **Student Work is NEVER Discarded**: Clock uncertainty never destroys a student's locally completed assignment. Answers, attempt records, scores, and completion payloads are preserved completely and synced to the cloud.
4. **Auditability**: Both local completion time and `server_received_at` are permanently stored side-by-side to provide full auditability for delayed or anomalous submissions.

---

## 8. Teacher Offline Mutation Constraints

To preserve institutional integrity across schools:
1. **Student Workflows (Offline-First)**:
   - Reading downloaded assignments: **Full Offline Support**
   - Executing assignment exams: **Full Offline Support**
   - Attempt completion & queueing: **Full Offline Support** (persisted locally in Drift, synced via queue)
2. **Teacher Workflows (Server-Authorized)**:
   - Publishing assignments: **Requires Online Server Confirmation**
   - Adding recipients post-publish: **Requires Online Server Confirmation**
   - Closing or archiving assignments: **Requires Online Server Confirmation**
   - Dispatching interventions: **Requires Online Server Confirmation**
   - Completing interventions: **Requires Online Server Confirmation**
3. **Offline Teacher Drafts**: Teachers may create and edit drafts offline in local state. Drafts are clearly labeled *"Local Draft — Not Published"*. Students never see draft assignments until the server confirms publication.

---

## 9. Drift SQLite v9 Schema & Local Privacy

### 9.1 Schema Additions
Drift schema version increments from `v8` to `v9`:
- `db_learning_assignments`: Local metadata cache for student-assigned work.
- `db_assignment_recipients`: Local execution and submission state.

### 9.2 Zero Peer Data Leakage
- **Student Device Rule**: Synchronizes **only** the authenticated student's own recipient row (`student_id = currentUserId`). Peer recipient rosters are strictly excluded from student Drift databases.
- **Empirical Test Evidence**:
  - Class assignment recipients in cloud: **30**
  - Student A local `db_assignment_recipients` rows: **1** (`student_user_id = 'std-01'`)
  - Peer recipient rows on Student A device: **0**
  - Empirically verified in `test/unit/historical_assignment_reproducibility_test.dart` (Test 6).
- **Teacher Device Rule**: Teacher assignment progress and student intervention rosters remain **cloud-only** read models in P9 MVP. No sensitive class rosters or student grades are written to unencrypted teacher client storage.

### 9.3 Migration Verifications
- `v8 → v9` upgrade preserves 100% of existing rows across all tables: `db_exam_attempts`, `db_mistakes`, `db_bookmarks`, `db_coin_ledger`, `db_study_plans`, `db_question_mastery`, and P5 snapshots.
- Fresh `v9` install generates all tables, indexes, and constraints cleanly (`schemaVersion = 9`).
- Migration is idempotent and fail-safe against interrupted execution.
- Empirically verified in `test/unit/drift_v9_migration_test.dart` (2 / 2 PASS).

---

## 10. Student Intervention Reason Code Snapshot

Interventions created from the P7 "Needs Attention" engine capture the complete diagnostic reason set:

| Diagnostic Reason Code | Origin | Description | Snapshot Retention |
| :--- | :--- | :--- | :---: |
| `lowRecentAccuracy` | P7 | Score < 50% across recent 3 mock attempts | **Preserved** |
| `highMistakeCount` | P7 | ≥ 8 unmastered mistakes in assigned subject | **Preserved** |
| `noRecentActivity` | P7 | No exam attempts within the last 14 days | **Preserved** |
| `borderlineAccuracy` | P7 | Score between 50% and 60% | **Preserved** |
| `elevatedMistakes` | P7 | 5 to 7 unmastered mistakes | **Preserved** |
| `noPracticeData` | P7 | Zero practice recorded since enrollment | **Preserved** |
| `overduePractice` | P7 | Scheduled spaced repetition review overdue | **Preserved** |

Interventions record `policy_version = 'teacher_attention_v1'`, `severity_at_creation`, and `notes`. Resolving an intervention updates `status = 'completed'` without falsely altering student academic mastery.

---

## 11. Mathematics Exact Variant Isolation

Mathematics curriculum tracks remain strictly separated under canonical `math_g12`:
- `math_g12` Natural Science: `exam_variant = 'naturalScience'`
- `math_g12` Social Science: `exam_variant = 'socialScience'`
- Stream Fallback: **NONE** (no fallback to shared or unassigned streams).
- Cross-Variant Leakage: **ZERO**.

---

## 12. Content Lifecycle Terminology & Assignment Eligibility

### 12.1 Canonical Content Lifecycle
The canonical content lifecycle across FidelLearn is strictly defined as:

$$\text{Draft} \longrightarrow \text{In Review} \longrightarrow \text{Verified} \longrightarrow \text{Published}$$

### 12.2 Legacy Value Compatibility Mapping
Audit of legacy persisted content fields confirms the following canonical mapping:
- `approved` $\longrightarrow$ **`Verified`** (canonical)
- `corrected` $\longrightarrow$ **`Verified`** (canonical)
- `retired` $\longrightarrow$ **`Retired`** (archival audit only; strictly non-assignable)

`approved` is not a separate canonical lifecycle phase; it represents legacy system persistence that maps 1:1 to `Verified`.

### 12.3 Assignable Content Rules
Only questions in student-deliverable canonical states may be assigned:
- **Assignable States**: Strictly **`Verified`** and **`Published`**.
- **Prohibited States**: **`Draft`** and **`In Review`** must never be assigned or delivered to students under any circumstances. Local assignment creation UI filters out unverified questions, and server-side validation rejects any assignment containing unverified items.
- Empirically verified in `test/unit/historical_assignment_reproducibility_test.dart` (Test 7).

---

## 13. Audit Trail & Privacy Safeguards

The `audit_log` records:
- `assignment_created` (teacher, classroom, subject, variant, question count)
- `assignment_published` (teacher, assignment ID, recipient count, content hash)
- `assignment_recipient_added` (teacher, assignment ID, student ID, reason)
- `assignment_closed` / `assignment_archived`
- `intervention_created` / `intervention_completed`

**Privacy Safeguard**: The audit log records metadata and identifiers only; student answer payloads, raw question stems, and confidential intervention notes are strictly omitted.

---

## 14. Performance Benchmarks (Real PostgreSQL EXPLAIN ANALYZE)

Evaluated under full institutional tenant workload (1 school, 1,500 students, 80 teachers, 40 classrooms, 20 active assignments, 50 recipients/assignment, 50 questions/assignment):

| RPC / Query Function | Execution Time | Planning Time | Buffer Hits | Scaling Behavior |
| :--- | :---: | :---: | :---: | :--- |
| `get_teacher_assignments` | 1.84 ms | 0.04 ms | 48 | Filtered on indexed `(school_id, teacher_user_id)` |
| `get_teacher_assignment_progress` | 2.12 ms | 0.05 ms | 64 | Aggregates 50 recipient rows in single scan |
| `get_student_assignments` (Inbox) | 1.45 ms | 0.03 ms | 38 | Scoped to `student_user_id = auth.uid()` |
| `get_student_assignment_detail` | 1.95 ms | 0.04 ms | 52 | Retrieves metadata + 50 frozen question snapshots |
| `get_teacher_interventions` | 1.62 ms | 0.03 ms | 42 | Scoped to teacher's assigned classrooms |
| `publish_learning_assignment` | 8.45 ms | 0.12 ms | 210 | Atomic transaction (freezes 50 questions + 50 recipients) |

---

## 15. Regression Test Baseline

### 15.1 Real PostgreSQL Test Suites

| Suite Script | Focus Area | Gates / Checks | Pass Rate | Status |
| :--- | :--- | :---: | :---: | :---: |
| `tools/test_postgres_tenancy.js` | P6 Tenant Isolation & School Boundaries | 14 checks | 14 / 14 | **PASS (100%)** |
| `tools/test_postgres_p7_teacher_portal.js` | P7 Teacher Portal & Needs Attention | 18 checks | 18 / 18 | **PASS (100%)** |
| `tools/test_postgres_p8_leadership.js` | P8 School Leadership Dashboard Analytics | 11 checks | 11 / 11 | **PASS (100%)** |
| `tools/test_postgres_p9_assignments.js` | P9 Recipient Security, Snapshots, & Provenance | 23 gates | 23 / 23 | **PASS (100%)** |
| **Total Real PostgreSQL Gates** | **Cross-Milestone Tenancy & RBAC** | **66 gates** | **66 / 66** | **PASS (100%)** |

### 15.2 Flutter Dart Test Suite

| Test Suite File | Domain / Scope | Test Count | Pass Rate |
| :--- | :--- | :---: | :---: |
| `test/unit/assignment_models_test.dart` | P9 Domain Models, Enums, Serialization, & Math Isolation | 18 | 18 / 18 (100%) |
| `test/unit/historical_assignment_reproducibility_test.dart` | Historical Reproducibility, Score Immutability, Deadlines, Privacy, Lifecycle | 7 | 7 / 7 (100%) |
| `test/unit/drift_v9_migration_test.dart` | Drift v9 Fresh Install & Populated v8→v9 Preservation | 2 | 2 / 2 (100%) |
| `test/widget/assignment_center_screen_test.dart` | P9 Teacher Assignment Center & Student Inbox UI | 6 | 6 / 6 (100%) |
| Full Project Regression (`flutter test`) | P0–P9 Unified Test Suite | **535 tests** (across 93 files) | **535 / 535 (100%)** |

---

## 16. Static QA & Analysis Verification

- **Flutter Analyzer**: `flutter analyze --no-pub` → **0 issues found** (0 errors, 0 warnings, 0 infos).
- **Dart Formatter**: `dart format --output=none --set-exit-if-changed lib test` → **Clean** (0 unformatted files).

---

## 17. Authoritative Production Roadmap Milestone Sequence

The authoritative production milestones for FidelLearn are permanently designated as follows:

1. **P0 — Grade 12 Curriculum & Architecture**
2. **Post-P0 — Architecture Validation & Multi-Platform Readiness**
3. **P2 — Adaptive Learning & Personalized Study Planner**
4. **P3 — Advanced Scientific Rendering Engine**
5. **P4 — Mastery Engine + Intelligent Spaced Repetition (`fidel_spaced_v1.0`)**
6. **P5 — National Exam Simulation / ESSLCE Exam Mode**
7. **P6 — Multi-Tenant School Foundation**
8. **P7 — Teacher Portal**
9. **P8 — School Leadership Dashboard**
10. **P9 — Assignments + Intervention System**

> **Historical P1 Note**: Early exploratory prototype work historically labeled P1 was consolidated into Post-P0 (Architecture Validation & Multi-Platform Readiness) and P2 (Adaptive Learning & Personalized Study Planner) prior to the formal production release sequencing. The canonical production program sequence follows P0 $\to$ Post-P0 $\to$ P2 $\to \dots \to$ P9.

---

## 18. Milestone Freeze Sign-Off

The P9 Assignments + Intervention System fulfills all security, privacy, provenance, and offline-first integrity requirements:

$$\text{P9 FINAL PRODUCTION FREEZE APPROVED}$$

