# P8 — School Leadership Dashboard Architecture

## 1. Product Vision & Architectural Principle
FidelLearn's three-tier institutional SaaS model is structured as follows:

```text
Students use FidelLearn.
    └── Offline-first exam practice, instant step-by-step explanations, Exam Ghost, Study Coins.
Teachers act on FidelLearn.
    └── Class assignments, question curation, roster attention queues, targeted interventions.
School leaders make decisions with FidelLearn.
    └── Institutional simulation participation, stream parity, systemic weak topic allocation,
        data freshness coverage, non-punitive teacher oversight, targeted student support.
```

The School Leadership Dashboard introduces the institutional executive decision-making layer, empowering principals, vice principals, and academic directors across Ethiopian secondary institutions to evaluate national exam preparation for the Ethiopian Secondary School Leaving Certificate Examination (ESSLCE).

---

## 2. Metric Dictionary & Educational Philosophy

### 2.1 Honest Metric Policy (Zero Fabricated Readiness)
Device-local P4 mastery models (spaced repetition item stability and retrieval strength under `fidel_spaced_v1.0`) reside strictly in encrypted Drift SQLite databases on student devices and are not synchronized to cloud analytics. School leaders frequently ask for an overarching "School Readiness Score" (e.g. "Our school is 78% exam-ready"). 

**FidelLearn strictly prohibits fabricated aggregations.** Computing an ungrounded weighted average of local mastery or incomplete test scores creates false administrative confidence and misrepresents student readiness. The dashboard presents a **National Exam Preparation Overview**, never a synthesized scalar "Readiness Score".

Instead, FidelLearn provides four verified, statistically honest institutional metrics:

| Metric | Calculation Method | Educational Purpose |
| :--- | :--- | :--- |
| **Simulation Participation** | $\frac{\text{Students with } \ge 1 \text{ completed simulation in 30 days / academic year}}{\text{Total active enrolled students}} \times 100$ | Quantifies institutional coverage and adoption across Grade 12 cohorts. Scoped by stream applicability. |
| **Recent Simulation Average & Median** | Arithmetic mean and 50th percentile of latest completed attempts per student per exam. | Compares general performance against outlier-skewed distributions. |
| **Mistake Concentration** | $\frac{\text{Incorrect question occurrences in unit/topic}}{\text{Total incorrect answers recorded across school}} \times 100$ | Identifies systemic curriculum blockages where instructional intervention yields highest ROI. |
| **Data Freshness Coverage** | Cohort count and percentage active within $\le 7$ days, $8-14$ days, $15-30$ days, and $>30$ days. | Alerts leadership to stale sync states or offline cohorts requiring connectivity support. |

### 2.2 Retake Deduplication Policy
When students retake a national exam simulation or mock paper, previous attempts reflect historical diagnostic state, whereas the **latest completed attempt** reflects their current demonstrated competence. All institutional RPC routines apply a strict deduplication window using SQL window functions:

```sql
ROW_NUMBER() OVER (
    PARTITION BY a.user_id, a.exam_id 
    ORDER BY a.end_time DESC, a.created_at DESC
) = 1
```

This prevents students who take an exam five times from skewing school-wide averages 5x more than students who take it once.

### 2.3 P4 Mastery Engine Transparency Disclosure
FidelLearn's P4 mastery engine uses the frozen algorithm `fidel_spaced_v1.0`. All spaced repetition memory states (stability, difficulty, retrievability, and review schedules) remain device-local. Institutional dashboards explicitly disclose:

> *"FidelLearn's P4 mastery and spaced-repetition state (fidel_spaced_v1.0) remains device-local and is not included in school-wide cloud analytics."*

No BKT (Bayesian Knowledge Tracing) data models or claims are present or supported.

---

## 3. Security, Multi-Tenant Isolation & Role Guards

### 3.1 Tenant Authority Resolution
Institutional leadership authority is governed exclusively by active tenancy within PostgreSQL:

```sql
SELECT EXISTS (
    SELECT 1 
    FROM public.school_memberships sm
    JOIN public.schools s ON s.id = sm.school_id
    WHERE sm.school_id = p_school_id
      AND sm.user_id = v_user_id
      AND sm.role = 'school_admin'
      AND sm.status = 'active'
      AND s.status = 'active'
);
```

**Key Security Constraints**:
1. Deprecated global role `UserRole.schoolAdmin` in `profiles` or `users` confers **0** tenant leadership authority.
2. If `schools.status != 'active'` (e.g. `suspended` or `archived`), all leadership RPC calls immediately raise an `insufficient_privilege` exception (SQLSTATE 42501).
3. Attempting to query another school's ID raises an unauthorized access violation.
4. All 11 leadership routines are defined with `SECURITY DEFINER` and a fixed search path (`SET search_path = public, pg_temp`) to eliminate search path hijacking.

### 3.2 Client Route Guards & Defense in Depth
Two independent defensive perimeters enforce school leadership isolation on the client:
1. **GoRouter Route Guard (`app_router.dart`)**: Routes `/school` and `/school/home` inspect `activeSchoolContextProvider.isSchoolAdmin`. If false or inactive, navigation is intercepted and redirected to `/home`.
2. **Screen-Level Lifecycle Guard (`SchoolLeadershipHomeScreen`)**: Re-checks `isSchoolAdmin` on widget build; displays an access denied message and intercepts navigation if tenancy was revoked or switched while on screen.
3. **Database RLS / RPC Guard**: The authoritative security boundary remains the PostgreSQL server-side check.

---

## 4. Canonical P5 Provenance Preservation

Leadership and teacher portals share an identical canonical provenance taxonomy:

| Canonical Category | Persisted Values / Legacy Aliases | Leadership & Teacher UI Label |
| :--- | :--- | :--- |
| `officialHistoricalPaper` | `officialHistoricalPaper`, `officialPastExam`, `officialPastPaper` | **Official Historical Paper** |
| `verifiedModelPaper` | `verifiedModelPaper`, `verifiedModel`, `modelexam` | **Verified Model Exam** |
| `generatedSimulation` | `nationalsimulation` mode, `generatedSimulation`, `mock_full` | **FidelLearn ESSLCE Simulation** |
| `custom` | `custom` mode, `custom_builder` | **Custom Exam** |
| `unit_test` (Context) | `unit_test` | **Unit Test** |
| `teacher_assigned` (Context) | `teacher_assigned`, `teacherCustom`, `teacherAssignment` | **Teacher Assignment** |
| `practice` | Default / unassigned | **Practice** |

Canonical P5 provenance maintains strict separation across three dimensions:
- **Conceptual `source_type`**: `officialHistoricalPaper`, `verifiedModelPaper`, `generatedSimulation`.
- **Conceptual `exam_mode`**: `nationalSimulation`, `historicalPaper`, `custom`, `practice`.
- **Contextual `exam_type`**: `mock_full`, `unit_test`, `practice`, `teacher_assigned`, `custom_builder`.
UI labels are derived from this combination; `unitTest` and `teacherAssignment` are operational contexts, not canonical source types.

---

## 5. Dual Stream, Canonical Math Identity & Track Terminology

### 5.1 Canonical Mathematics Architecture
In alignment with P0 curriculum architecture, Mathematics is **one canonical subject**:
- `subjectId = 'math_g12'`
- Disambiguated strictly by `ExamVariantCode.naturalScience` and `ExamVariantCode.socialScience`.
- **Authoritative Variant Requirement**: Exact `exam_variant` is required. Stream fallback is **NONE**.
- **Contradictory Metadata**: If `exam_variant = 'naturalScience'` with `stream = 'social'` (or vice versa), the record is treated as invalid/inconsistent and strictly excluded.
- **NULL / Shared Variants**: Excluded from variant-specific analytics.
- UI displays distinct labels: **"Mathematics — Natural Science"** and **"Mathematics — Social Science"**.
- Cross-variant contamination is zero.

### 5.2 Curriculum & Assessment Track Counts
The Grade 12 curriculum model consists of:
- **9 primary canonical subjects**: Mathematics (`math_g12`), English (`english_g12`), Scholastic Aptitude (`aptitude_g12`), Physics (`physics_g12`), Chemistry (`chemistry_g12`), Biology (`biology_g12`), History (`history_g12`), Geography (`geography_g12`), Economics (`economics_g12`).
- **10 primary assessment tracks**: The 9 primary subjects span 10 ESSLCE tracks because Mathematics has two distinct stream variants (`naturalScience` and `socialScience`).
- **1 supplementary subject**: Civics & Ethical Education (`civics_g12`), bringing total canonical subject IDs to **10**.
- **11 Unique Subject+Variant Analytical Entities**: The leadership dashboard provides 11 discrete subject/variant analytical entities in the Subjects tab (10 primary assessment tracks + 1 supplementary Civics view).
- **Per-Stream Primary Views**:
  - Natural Science: English, Math — Natural, Aptitude, Physics, Chemistry, Biology = **6 primary tracks**.
  - Social Science: English, Math — Social, Aptitude, History, Geography, Economics = **6 primary tracks**.
  - Civics is displayed as **Supplementary / Common Curriculum**, never forced into a single stream.

### 5.3 Civics Status
Civics (`civics_g12`) is supplementary / curriculum-only for launch and is not a default ESSLCE entrance-exam daily-plan blocker or core assessment track. It is excluded from default ESSLCE simulation participation denominators, primary entrance-exam track coverage, and primary teacher staffing slots.

---

## 6. Non-Punitive Educational Principles

### 6.1 Class Performance Comparison
Classes are compared using objective operational and mastery metrics:
- Enrollment count
- Active student count
- Assessment completion rate (%)
- Average score (%)

The UI explicitly **avoids** competitive, pejorative, or superlative labels (such as "Best Class", "Worst Class", or "Failing Section"). All classes are presented constructively with neutral sorting options.

### 6.2 Teacher Oversight (Coverage, Not Outcome Scoring)
School leaders oversee instructional staffing coverage derived strictly from `teacher_subject_assignments` joined with `classrooms`:
- Derived from `classroom`, `subject`, and `exam_variant` where applicable.
- Core curriculum requires 6 primary ESSLCE subjects per class:
  - **Natural Science (6)**: English, Mathematics (Natural), Aptitude, Physics, Chemistry, Biology.
  - **Social Science (6)**: English, Mathematics (Social), Aptitude, History, Geography, Economics.
- Total core staffing slots across 4 standard classes = **24 required slots**. Civics is not required as a primary ESSLCE staffing slot.
- Teachers are **never ranked** against each other on student exam score averages.

---

## 7. Targeted Student Support Population

School leaders identify students requiring academic or administrative support before national exams:

### 7.1 Risk Factor Categorization
- **Academic Factors**:
  - `active_mistakes_present`: Student has accumulated systemic unresolved mistake records.
  - `borderline_accuracy`: Average accuracy below 50% on recent assessments.
  - `no_simulations_completed`: **No recent simulation evidence** recorded (indicates missing assessment diagnostic data, NOT poor academic ability or failure).
- **Administrative Factors**:
  - `stale_sync_latency`: Device has not synchronized with cloud within $>14$ days (**stale sync $\ne$ no study**; student may be studying actively offline).

### 7.2 Severity Rules
- **High**: Multiple compounding academic risk factors (e.g. low accuracy + active mistake backlog).
- **Medium**: Single academic risk factor.
- **Low**: Administrative / data-quality flags only (e.g. stale sync or missing simulation evidence).

---

## 8. Offline & Local Architecture (Hardened Invariant)

### 8.1 Production Offline Policy (No Synthetic Fallback)
A real school administrator must never see fabricated student counts, assessment averages, or teacher staffing coverage presented as cached institutional truth.

**Production Invariant**:
```text
Supabase unavailable ≠ LocalSchoolLeadershipRepository
```

1. **Provider Resolution**: `schoolLeadershipRepositoryProvider` resolves to `SupabaseSchoolLeadershipRepository` whenever `EnvConfig.isProduction`, `EnvConfig.isStaging`, or `EnvConfig.isSupabaseConfigured` is true.
2. **Offline Handling**: When offline or when `ActiveSchoolContext.isOfflineCached == true`, leadership analytics providers throw `SchoolLeadershipOfflineException`:
   > *"Leadership analytics require an internet connection. Reconnect to load current school analytics."*
3. **Tenant Identity Preservation**: The offline cached school context retains identity metadata (`school.name`, `school.schoolCode`, `membership.role`, `membership.status`) for display, while analytics cards honestly state offline unavailability.
4. **Local Repository Scope**: `LocalSchoolLeadershipRepository` is strictly reserved for unit tests, widget tests, Storybook/previews, and explicit demo overrides. It is **never** invoked as a production fallback.
5. **No Persistent Cache**: No sensitive school roster, student drill-down, or teacher coverage data is persisted to SharedPreferences, Drift SQLite, or unencrypted local storage.
6. **Drift SQLite Schema**: The local SQLite database schema remains strictly **v8 unchanged**.
