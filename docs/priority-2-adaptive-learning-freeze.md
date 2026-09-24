# FidelLearn — Priority 2 Adaptive Learning & Personalized Study Planner Freeze

**Freeze Version**: `priority-2-adaptive-learning-v1.0.0`  
**Freeze Date**: September 24, 2026  
**Status**: `PRIORITY 2 FREEZE APPROVED`  
**Planner Algorithm Version**: `adaptive_planner_v1.1`  
**Target Architecture**: Clean Architecture, Drift SQLite Schema v4, Riverpod Unidirectional Data Flow, 100% Offline-First Deterministic Engine

---

## 1. Executive Summary

This document certifies the formal engineering freeze for **Priority 2: Adaptive Learning & Personalized Study Planner** of FidelLearn (ፊደል ለርን). Priority 2 delivers an intelligent, explainable, and offline-first pedagogical study plan engine that analyzes student performance across past exams, practice sessions, and mistake records to synthesize optimal daily study sessions.

This hardening and freeze pass resolved all cross-track curriculum gaps:
1. **English and Scholastic Aptitude Full Participation**: English (`AssessmentStructure.mixed`) and Scholastic Aptitude (`AssessmentStructure.skillBased`) now fully participate in daily recommendations without being forced into artificial textbook units.
2. **Mathematics Stream Variant Isolation**: Single canonical subject `math_g12` strictly persists its exam variant (`ExamVariantCode.naturalScience` vs `socialScience`) across planning, persistence, and Exam Runner execution with **0% cross-track contamination**.
3. **Canonical Exam-Proximity Policy**: Unified 4-phase exam proximity model (`foundation`, `consolidation`, `intensive`, `finalReview`) applied uniformly across domain engines, UI indicators, and test assertions.
4. **Non-Destructive Database Schema Migration**: Upgraded Drift SQLite schema from v3 to v4 with incremental safety guards (`&& to >= 4`) and safe legacy backfilling preserving historic study plans.
5. **Roadmap Correction**: Official roadmap documentation updated to identify Priority 3 as **Advanced Scientific Rendering** (LaTeX/KaTeX, vector diagram rendering, chemical formulas).

---

## 2. Eligible Subject Matrix & Stream Architecture

The adaptive planner strictly honors the frozen **Priority 0 Grade 12 Launch Matrix** (`p0-grade12-schema-freeze-v1.0.0`):

| Stream | Eligible Assessment Tracks (6 Primary Tracks per Stream) | Supplementary / Excluded |
| :--- | :--- | :--- |
| **Natural Science** | 1. **English** (`english_g12` \| `shared` \| `mixed`)<br>2. **Mathematics (Natural)** (`math_g12` \| `naturalScience` \| `curriculum`)<br>3. **Scholastic Aptitude** (`aptitude_g12` \| `shared` \| `skillBased`)<br>4. **Physics** (`physics_g12` \| `naturalScience` \| `curriculum`)<br>5. **Chemistry** (`chemistry_g12` \| `naturalScience` \| `curriculum`)<br>6. **Biology** (`biology_g12` \| `naturalScience` \| `curriculum`) | • Social Subjects (History, Geography, Economics) excluded.<br>• Civics excluded from default daily study plans. |
| **Social Science** | 1. **English** (`english_g12` \| `shared` \| `mixed`)<br>2. **Mathematics (Social)** (`math_g12` \| `socialScience` \| `curriculum`)<br>3. **Scholastic Aptitude** (`aptitude_g12` \| `shared` \| `skillBased`)<br>4. **History** (`history_g12` \| `socialScience` \| `curriculum`)<br>5. **Geography** (`geography_g12` \| `socialScience` \| `curriculum`)<br>6. **Economics** (`economics_g12` \| `socialScience` \| `curriculum`) | • Natural Subjects (Physics, Chemistry, Biology) excluded.<br>• Civics excluded from default daily study plans. |

---

## 3. Session Data Model & Persistence Architecture

The session data model in `lib/features/progress/domain/models/study_plan_models.dart` and Drift table `DbStudyPlanSessions` (`lib/core/database/tables.dart`) explicitly captures the complete pedagogical identity of every study session:

```dart
class StudyPlanSession extends Equatable {
  final String id;
  final String planId;
  final String subjectId;
  final ExamVariantCode? examVariant;          // naturalScience, socialScience, shared
  final AssessmentStructure? assessmentStructure; // curriculum, skillBased, mixed
  final String? unitId;                       // Curriculum unit ID
  final String? topicId;                      // Curriculum topic ID
  final String? contentDomain;                // E.g. 'Reading Comprehension', 'Quantitative Reasoning'
  final String? skill;                        // E.g. 'Data Interpretation', 'Analogies'
  final StudySessionType sessionType;         // weakTopicPractice, curriculumCoverage, mistakeRetry, timedMockExam, mixedReview
  final String titleEn;
  final String titleAm;
  final int questionTarget;
  final int estimatedMinutes;
  final double priorityScore;
  final RecommendationReasonCode reasonCode;  // weakTopic, newCurriculum, mistakeReview, examProximity, balancedProgress, spacedReview
  final String reasonDetailEn;
  final String reasonDetailAm;
  final SessionCompletionStatus status;       // notStarted, inProgress, completed, skipped
  final List<String> questionIds;
  final DateTime? completedAt;
  final int timeSpentSeconds;
  final double? scorePercentage;
}
```

### Drift SQLite Schema Migration (v3 -> v4)
- **Table Alteration**: Added nullable columns `exam_variant`, `assessment_structure`, `content_domain`, and `skill` to `db_study_plan_sessions`.
- **Migration Strategy**: Step-guarded via `if (from < 4 && to >= 4)`.
- **Legacy Backfill**: Safe non-destructive SQL backfills unambiguous subjects (`aptitude_g12` → `skillBased`/`shared`; `english_g12` → `mixed`/`shared`; science/social subjects → `curriculum` with respective stream variants). Ambiguous legacy Mathematics sessions are left with `exam_variant = NULL` to safely trigger clean plan re-generation.

---

## 4. Mathematics Cross-Track Isolation Verification

FidelLearn models Mathematics as a single canonical subject `math_g12` with two mutually exclusive tracks:
- **Natural Track**: `math_g12` with `examVariant: ExamVariantCode.naturalScience`
- **Social Track**: `math_g12` with `examVariant: ExamVariantCode.socialScience`

### Isolation Implementation
1. **Candidate Discovery**: `AdaptiveStudyPlanner._isQuestionEligibleForStudent()` validates question variant against student stream. A Natural student's pool strictly rejects `socialScience` Math questions; a Social student's pool strictly rejects `naturalScience` Math questions.
2. **Session Persistence**: Sessions persist `examVariant` directly in the database.
3. **Exam Runner Launch**: Fallback question selection in `StudentHomeScreen._startStudyPlanSession` filters available questions by `session.examVariant` and `studentStream`.
4. **Verification Result**:
   - Natural Math recommendation retaining Natural variant: **PASS**
   - Social Math recommendation retaining Social variant: **PASS**
   - Cross-track question contamination: **NONE (0.0% leakage)**

---

## 5. English & Scholastic Aptitude Integration

### English (`AssessmentStructure.mixed`)
- **Pedagogical Structure**: Combines passage stimulus comprehension (`Reading Comprehension`) with grammatical knowledge (`Grammar & Usage`, `Vocabulary in Context`).
- **Learning Target Representation**: Mapped through `LearningTarget` with `contentDomain: 'Reading Comprehension'` and `assessmentStructure: AssessmentStructure.mixed`.
- **Weakness Detection**: Weakness in Reading Comprehension surfaces a `mixedReview` or `weakTopicPractice` session with bilingual justification (*"Low accuracy in Reading Comprehension"* / *"በንባብ ግንዛቤ ዝቅተኛ ውጤት"*).
- **Exam Runner Launch**: Automatically launches filtered English reading questions.

### Scholastic Aptitude (`AssessmentStructure.skillBased`)
- **Pedagogical Structure**: Cognitive reasoning categorized into Verbal Reasoning and Quantitative Reasoning, evaluated by specific skills (`Data Interpretation`, `Analogies`, `Logical Deduction`).
- **Learning Target Representation**: Captured without synthetic textbook units using `contentDomain: 'Quantitative Reasoning'` and `skill: 'Data Interpretation'`.
- **Persistence & Launch**: Full persistence of skill-based attributes in Drift schema v4, launching Exam Runner with aptitude-specific reasoning questions.

---

## 6. Canonical Exam-Proximity Policy

A single, canonical 4-phase threshold policy governs exam proximity across the entire platform:

| Phase Enum | Exam Proximity Threshold | Strategic Focus & Planner Weighting |
| :--- | :--- | :--- |
| `foundation` | **> 60 days** (or exam date unconfigured) | Curriculum breadth, covering unpracticed units, foundational practice. |
| `consolidation` | **31 – 60 days** | Systematic weak-topic remediation and error notebook retries. |
| `intensive` | **15 – 30 days** | High-yield mixed review across balanced stream subjects. |
| `finalReview` | **0 – 14 days** | Full timed mock exam simulations (**+85.0 priority weighting**) and high-speed retrieval. |

*Boundary Condition Guarantee*: Timed Mock Exam boost (+85.0) activates **strictly at <= 14 days** (`finalReview`). Between 15 and 30 days (`intensive`), the planner maintains targeted curriculum and weak-topic practice.

---

## 7. Multi-Factor Prioritization Formula & Determinism

The recommendation engine calculates priority scores deterministically using the following additive signal hierarchy:

$$\text{PriorityScore} = S_{\text{weakness}} + S_{\text{coverage}} + S_{\text{mistakes}} + S_{\text{spaced}} + S_{\text{proximity}} - P_{\text{recency}}$$

1. **Weak Topic Signal ($S_{\text{weakness}}$)**: Up to $+40.0 \times (1.0 - \text{accuracy})$. Requires minimum 3 attempts with accuracy $<65\%$.
2. **Curriculum Coverage Signal ($S_{\text{coverage}}$)**: $+25.0$ for unpracticed units/topics to ensure balanced syllabus progression.
3. **Mistake Notebook Signal ($S_{\text{mistakes}}$)**: Up to $+35.0 \times \text{recencyDecay}$ for questions with unresolved errors.
4. **Spaced Review Signal ($S_{\text{spaced}}$)**: $+15.0 \times \text{decayFactor}$ for topics not practiced in over 14 days.
5. **Exam Proximity Signal ($S_{\text{proximity}}$)**: $+85.0$ for timed mock exams during `finalReview` ($\le 14$ days); $+15.0$ to $+30.0$ for mixed reviews during `intensive` ($\le 30$ days).
6. **Multi-Subject Balancing Penalty ($P_{\text{recency}}$)**: $-20.0$ penalty for subjects practiced consecutively, rotating attention to unpracticed stream subjects while protecting common subjects (English and Aptitude) from starvation.

### Determinism Guarantee
The planner executes purely deterministic calculations. Any tie-breaking uses a stable deterministic seed (`DateTime(planDate.year, planDate.month, planDate.day).millisecondsSinceEpoch`). Identical student history on a given day produces the exact same study plan.

---

## 8. Daily Session Limits & Budget Scaling

- **User Budget**: 15 to 120 minutes (default: 45 minutes).
- **Session Duration**: 10 to 25 minutes per session (default: 15 minutes).
- **Session Count Limit**: Maximum 4 sessions per daily study plan.
- **Budget Compliance**: Total estimated minutes of recommended sessions never exceeds user budget by more than 1 session tolerance.

---

## 9. Quality Assurance & Verification Summary

### Automated Test Suite Execution
- **Total Automated Tests**: **388 tests** across repository.
- **Test Pass Rate**: **100% (388 / 388 passed)**.
- **Static Analysis (`flutter analyze`)**: **0 issues found**.
- **Code Formatting (`dart format`)**: **0 diffs** (235 files verified clean).

### Key Test Suites for Priority 2
1. `test/unit/adaptive_planner_p2_freeze_test.dart`: 10 dedicated freeze tests (10/10 passed).
2. `test/unit/adaptive_study_planner_hardening_test.dart`: 8 granular track isolation & proximity tests (8/8 passed).
3. `test/unit/study_plan_drift_migration_test.dart`: Drift SQLite schema v3 to v4 migration and legacy backfill (1/1 passed).
4. `test/unit/adaptive_study_planner_test.dart`: Core adaptive scoring, stream filtering, and balancing (9/9 passed).
5. `test/unit/study_plan_drift_test.dart`: Drift database persistence and reactive streams (4/4 passed).
6. `test/integration/adaptive_study_planner_journey_test.dart`: Full end-to-end student study plan lifecycle (1/1 passed).
7. `test/widget/today_study_plan_card_test.dart`: Home screen study plan widget, track badges, and launch action (5/5 passed).

---

## 10. Known Non-Blocking Observations

| Item | Classification | Observation & Architectural Status |
| :--- | :---: | :--- |
| **Civics Practice Availability** | `LOW` | Civics questions remain fully accessible via Custom Exam Builder and Question Bank, but are intentionally excluded from the default entrance-exam daily study plan. |
| **Legacy Math Re-Generation** | `LOW` | Legacy v3 plans with un-annotated Math sessions have `examVariant = NULL`; upon first daily sync/load, the engine seamlessly regenerates an annotated v4 plan. |
| **Audio Explanations in Study Sessions** | `LOW` | Audio explanation playback is available in the Exam Runner for questions that have recorded audio clips; study plan sessions reference these questions seamlessly. |

---

## 11. Freeze Artifact & Roadmap Alignment

- **Freeze Document**: [`docs/priority-2-adaptive-learning-freeze.md`](file:///c:/Users/tamer/Documents/Fidel%20Learn/docs/priority-2-adaptive-learning-freeze.md)
- **Algorithm Version**: `adaptive_planner_v1.1`
- **Database Schema**: Drift Schema Version `4`
- **Next Engineering Priority**: **Priority 3 — Advanced Scientific Rendering** (LaTeX/KaTeX, vector diagram rendering, chemical formulas).
