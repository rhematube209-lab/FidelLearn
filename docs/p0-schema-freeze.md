# FidelLearn — P0 Grade 12 Launch Curriculum & Architecture Freeze

**Freeze Version**: `p0-grade12-schema-freeze-v1.0.0`  
**Freeze Date**: September 24, 2026  
**Status**: `P0 FREEZE APPROVED`  
**Target Milestone**: Grade 12 National Examination (ESSLCE) Natural & Social Science Launch

---

## 1. Executive Summary

This document establishes the official and binding **P0 Grade 12 Launch Curriculum & Architecture Freeze** for FidelLearn. All core entity schemas, subject hierarchies, exam-track models, curriculum manifest contracts, question provenance specifications, decoupled coverage metrics, and launch-readiness policies are permanently locked. 

Subsequent development (including Post-P0 Architecture Validation, Multi-Platform Readiness, and future Priority 2 milestones) builds strictly upon this stable baseline. Content additions (new exam papers, corrected explanations, additional verified questions) are encouraged and supported through data-driven ingestion without altering frozen schemas.

---

## 2. Canonical Launch Scope & Subject Matrix

FidelLearn launches with **9 unique canonical primary subjects across 10 assessment tracks**, with **Civics preserved as supplementary Grade 12 content**.

### 2.1 Common Exam Subjects (Accessible to Both Streams)
1. **English** (`english_g12` | `ENG12`)
   - **Scope**: `SubjectScope.commonExam`
   - **Variant**: `ExamVariantCode.shared`
   - **Assessment Structure**: `AssessmentStructure.mixed` (curriculum knowledge + reading passage stimulus)
2. **Mathematics** (`math_g12` | `MATH12`)
   - **Scope**: `SubjectScope.commonExam`
   - **Variant Architecture**: Single canonical subject containing two mutually exclusive assessment tracks:
     - **Track 1**: Natural Science Mathematics (`ExamVariantCode.naturalScience` | Variant ID: `math_g12_nat`)
     - **Track 2**: Social Science Mathematics (`ExamVariantCode.socialScience` | Variant ID: `math_g12_soc`)
   - **Assessment Structure**: `AssessmentStructure.curriculum`
3. **Scholastic Aptitude** (`aptitude_g12` | `APT12`)
   - **Scope**: `SubjectScope.commonExam`
   - **Variant**: `ExamVariantCode.shared`
   - **Assessment Structure**: `AssessmentStructure.skillBased` (Verbal and Quantitative cognitive reasoning)

### 2.2 Natural Science Stream Subjects
4. **Physics** (`physics_g12` | `PHY12`)
   - **Scope**: `SubjectScope.streamExam` | **Variant**: `ExamVariantCode.naturalScience` | **Structure**: `AssessmentStructure.curriculum`
5. **Chemistry** (`chemistry_g12` | `CHM12`)
   - **Scope**: `SubjectScope.streamExam` | **Variant**: `ExamVariantCode.naturalScience` | **Structure**: `AssessmentStructure.curriculum`
6. **Biology** (`biology_g12` | `BIO12`)
   - **Scope**: `SubjectScope.streamExam` | **Variant**: `ExamVariantCode.naturalScience` | **Structure**: `AssessmentStructure.curriculum`

### 2.3 Social Science Stream Subjects
7. **History** (`history_g12` | `HIS12`)
   - **Scope**: `SubjectScope.streamExam` | **Variant**: `ExamVariantCode.socialScience` | **Structure**: `AssessmentStructure.curriculum`
8. **Geography** (`geography_g12` | `GEO12`)
   - **Scope**: `SubjectScope.streamExam` | **Variant**: `ExamVariantCode.socialScience` | **Structure**: `AssessmentStructure.curriculum`
9. **Economics** (`economics_g12` | `ECN12`)
   - **Scope**: `SubjectScope.streamExam` | **Variant**: `ExamVariantCode.socialScience` | **Structure**: `AssessmentStructure.curriculum`

### 2.4 Supplementary Grade 12 Subject
* **Civics & Ethical Education** (`civics_g12` | `CIV12`)
  - **Scope**: `SubjectScope.curriculumOnly`
  - **Variant**: `ExamVariantCode.shared`
  - **Assessment Structure**: `AssessmentStructure.curriculum`
  - **Role**: Preserved for historical study and general curriculum practice. Excluded from primary national entrance exam calculations.

---

## 3. Frozen Architecture Contracts

### 3.1 Mathematics Variant Architecture
Mathematics is modeled as **one canonical subject record** (`math_g12`) with two attached `SubjectExamVariant` descriptors:
```dart
Subject(
  id: 'math_g12',
  code: 'MATH12',
  nameEn: 'Mathematics',
  nameAm: 'ሒሳብ',
  grade: 12,
  stream: 'common',
  scope: SubjectScope.commonExam,
  assessmentStructure: AssessmentStructure.curriculum,
  availableVariants: [
    SubjectExamVariant(
      variantId: 'math_g12_nat',
      variantCode: ExamVariantCode.naturalScience,
      titleEn: 'Mathematics (Natural Science)',
      titleAm: 'ሒሳብ (የተፈጥሮ ሳይንስ)',
      stream: 'natural',
      descriptionEn: 'Vectors, limits, integration, 3D geometry',
      sortOrder: 1,
    ),
    SubjectExamVariant(
      variantId: 'math_g12_soc',
      variantCode: ExamVariantCode.socialScience,
      titleEn: 'Mathematics (Social Science)',
      titleAm: 'ሒሳብ (የማህበራዊ ሳይንስ)',
      stream: 'social',
      descriptionEn: 'Business calculus, sequences, linear programming',
      sortOrder: 2,
    ),
  ],
)
```
- **Stream Isolation Rule**: Natural Science students only receive `ExamVariantCode.naturalScience` questions. Social Science students only receive `ExamVariantCode.socialScience` questions. Cross-variant questions never leak across streams.

### 3.2 Subject Classification Contract
Enforced by `SubjectScope`:
```dart
enum SubjectScope {
  commonExam,     // Required for all streams (English, Math tracks, Aptitude)
  streamExam,     // Stream-exclusive (Physics, Chem, Bio vs History, Geo, Econ)
  curriculumOnly, // Non-entrance supplementary content (Civics)
}
```

### 3.3 Assessment Structure Contract
Enforced by `AssessmentStructure`:
```dart
enum AssessmentStructure {
  curriculum, // Organized by standard textbook units/chapters (Physics, Chemistry, History, etc.)
  skillBased, // Organized by cognitive skills/domains without textbook chapters (Scholastic Aptitude)
  mixed,      // Units combined with stimulus passages and skill clusters (English)
}
```

### 3.4 Curriculum Manifest Contract
The official denominator for curriculum coverage is governed by `SubjectManifest`:
```dart
class SubjectManifest {
  final String manifestId;
  final String canonicalSubjectId;
  final ExamVariantCode variantCode;
  final String title;
  final String sourceAuthority;
  final String sourceDocumentTitle;
  final String? sourceDocumentId;
  final String sourceReference;
  final String? sourceUrlOrReference;
  final String curriculumVersion;
  final String? verifiedAt;
  final String? verifiedBy;
  final ManifestVerificationStatus verificationStatus;
  final AssessmentStructure assessmentStructure;
  final SubjectScope scope;
  final bool isSupplementary;
  final List<ExpectedUnitOrDomain> expectedUnitsOrDomains;
  final List<int> targetPastExamYears;
}
```
Every `ExpectedUnitOrDomain` records:
- `index`: 1-based sequential order
- `id`: Unique stable unit identifier (`geo_u1`, `econ_u1`, etc.)
- `titleEn` & `titleAm`: Bilingual titles
- `domainType`: `'unit'` or `'skill_domain'`
- `sourceReference` & `sourcePage`: Authoritative syllabus citation

### 3.5 Question Provenance Contract
Every official past examination question must supply an immutable `QuestionProvenance` record:
```dart
class QuestionProvenance {
  final SourceProvenanceType sourceProvenanceType; // officialNeaeaPaper, nationalArchive, educatorModelExam
  final String sourceDocument;
  final int examYear;                             // In Ethiopian Calendar (e.g. 2014)
  final String? bookletCode;                      // Official EAES booklet code (e.g. "Booklet 12")
  final int? itemNumber;                          // Item number on physical booklet (1 to 100)
  final String? originalExamType;                 // "ESSLCE" / "National University Entrance"
  final String? verifiedBy;                       // Reviewer / curator ID
  final DateTime? verifiedAt;                     // Timestamp of provenance verification
  final bool isAuthenticPastExam;                 // Strictly true only for genuine past exams
  final String? checksum;                         // Integrity hash
}
```
- **Integrity Rule**: No question may claim `isAuthenticPastExam: true` or `sourceName: "ESSLCE"` without authoritative provenance evidence. AI-generated questions are strictly prohibited from posing as official past exams.

---

## 4. Frozen Coverage Model & Launch Policy

### 4.1 Decoupled Coverage Metrics
Curriculum completeness is measured across four independent metrics:
1. **Curriculum Breadth %**: `(unitsWithQuestions / manifestTotalUnits) * 100.0`
2. **Past-Paper Depth %**: `(verifiedTargetYears / totalTargetYears) * 100.0`
3. **Question-Bank Depth**: `totalQuestions` (volume)
4. **Explanation Quality %**: `rationaleCoveragePercent` (solution clarity >= 85%)

### 4.2 Configurable Launch-Readiness Policy
Historical depth is decoupled from blocking launch readiness under the default baseline:
```dart
HistoricalDepthLaunchPolicy.informationalOnly
```
- A subject with 100% Curriculum Breadth, >= 85% Rationale Quality, and `authoritative` manifest verification status achieves `SubjectLaunchReadiness.readyForLaunch` even if past-paper archive depth is partial.
- Historical archive completeness is recorded as `HistoricalCoverageStatus.partial` without blocking product launch.
- If an institution requires strict paper completeness, the policy can be toggled to `minimumYearCount(N)` or `allTargetYears`.

### 4.3 Target Exam-Year Window
The canonical historical past-exam target window is frozen as:
```text
2013 E.C.
2014 E.C.
2015 E.C.
2016 E.C.
2017 E.C.
2018 E.C.
```
- Unverified/uningested years (e.g. 2016, 2017, 2018 E.C.) are visibly recorded as missing (`effectiveMissingTargetYears`) and are never fabricated.

---

## 5. Frozen Package Contract (`.flpkg`)

Offline packages adhere to the following specification:
- **Archive Format**: Versioned ZIP or encrypted SQLite bundle.
- **Manifest Attributes**:
  - `package_id`: e.g. `"pkg_g12_math_nat_v1"`
  - `subject_id`: Canonical subject ID (`math_g12`)
  - `variant_code`: `naturalScience`
  - `grade`: `12`
  - `curriculum_version`: `"current_grade12"`
  - `content_version`: `1`
  - `total_questions`: Question count
  - `checksum_sha256`: SHA-256 verification hash
- **Zero-Network Guarantee**: All ingested packages unpack and run locally through Drift SQLite with 0 external network requests.

---

## 6. Stable Identifier Reference

These identifiers are permanently frozen and must not be renamed:

### 6.1 Canonical Subject IDs
| Canonical ID | Subject Code | Subject Name | Scope |
|---|---|---|---|
| `english_g12` | `ENG12` | English | `commonExam` |
| `math_g12` | `MATH12` | Mathematics | `commonExam` |
| `aptitude_g12` | `APT12` | Scholastic Aptitude | `commonExam` |
| `physics_g12` | `PHY12` | Physics | `streamExam` |
| `chemistry_g12` | `CHM12` | Chemistry | `streamExam` |
| `biology_g12` | `BIO12` | Biology | `streamExam` |
| `history_g12` | `HIS12` | History | `streamExam` |
| `geography_g12` | `GEO12` | Geography | `streamExam` |
| `economics_g12` | `ECN12` | Economics | `streamExam` |
| `civics_g12` | `CIV12` | Civics (Supplementary) | `curriculumOnly` |

### 6.2 Exam Variant Identifiers
| Variant ID | Canonical Subject | Variant Code | Stream |
|---|---|---|---|
| `math_g12_nat` | `math_g12` | `naturalScience` | `natural` |
| `math_g12_soc` | `math_g12` | `socialScience` | `social` |
| `common` | Various | `shared` | `common` |

### 6.3 Curriculum Manifest Identifiers
| Manifest ID | Denominator (Units/Domains) | Authoritative Source Document ID |
|---|---|---|
| `english_g12` | 6 Skill Domains | `MOE-ETH-SYL-G12-ENG-2023` |
| `math_nat_g12` | 5 Units | `MOE-ETH-SYL-G12-MAT-NAT-2023` |
| `math_soc_g12` | 6 Units | `MOE-ETH-SYL-G12-MAT-SOC-2023` |
| `aptitude_g12` | 2 Domains / 11 Skills | `EAES-ETH-ASSESS-APT-2023` |
| `physics_g12` | 9 Units | `MOE-ETH-SYL-G12-PHY-2023` |
| `chemistry_g12` | 6 Units | `MOE-ETH-SYL-G12-CHM-2023` |
| `biology_g12` | 6 Units | `MOE-ETH-SYL-G12-BIO-2023` |
| `history_g12` | 5 Units | `MOE-ETH-SYL-G12-HIS-2023` |
| `geography_g12` | 8 Units | `MOE-ETH-SYL-G12-GEO-2023` |
| `economics_g12` | 8 Units | `MOE-ETH-SYL-G12-ECN-2023` |
| `civics_g12` | 11 Units | `MOE-ETH-SYL-G12-CIV-2023` |

### 6.4 Persisted Enums & Serialization Names
- `SubjectScope`: `commonExam`, `streamExam`, `curriculumOnly`
- `ExamVariantCode`: `shared`, `naturalScience`, `socialScience`
- `AssessmentStructure`: `curriculum`, `skillBased`, `mixed`
- `SourceProvenanceType`: `officialNeaeaPaper`, `nationalArchive`, `educatorModelExam`
- `ManifestVerificationStatus`: `confirmed`, `partiallyConfirmed`, `needsVerification`
- `CoverageAuthorityLevel`: `authoritative`, `provisional`, `unverified`
- `HistoricalDepthLaunchPolicy`: `informationalOnly`, `minimumYearCount`, `requiredSpecificYears`, `allTargetYears`
- `HistoricalCoverageStatus`: `complete`, `partial`, `minimal`
- `SubjectLaunchReadiness`: `notStarted`, `inProgress`, `contentReview`, `qa`, `readyForLaunch`

---

## 7. Extensibility & Future-Proofing

1. **Grade 8 Regional Exam Extensibility**:
   - The architecture supports Grade 8 regional examination subjects without modifying core schemas. Grade 8 subjects instantiate `Subject(grade: 8, scope: SubjectScope.commonExam)` with corresponding manifests and packages.
2. **Data-Driven Future Exam Years**:
   - Ingesting future years (e.g. 2019, 2020 E.C.) requires zero schema migrations; years are added through manifest configuration (`targetPastExamYears`) and seed package updates.
3. **Backward Compatibility**:
   - All existing Drift SQLite tables, bookmarks, user mistake notebooks, exam attempts, and Study Coin ledger entries remain fully compatible.

---

## 8. Quality Assurance & Regression Audit

- **Static Analysis**: `flutter analyze --no-pub` reported **0 issues**.
- **Formatting**: `dart format --output=none --set-exit-if-changed lib test` reported **0 unformatted files**.
- **Automated Test Suite**: **280 tests executed, 280 passed (100% pass rate)**.
- **P0 Blockers**: **0 Blockers**.

---

## 9. Non-Blocking Content Backlog (Post-Freeze Operational Roadmap)

The following items are normal editorial content additions that do not alter the frozen schema:
1. Ingest physical exam booklets for remaining target years (2016, 2017, 2018 E.C.) as official EAES papers become available.
2. Expand Amharic explanations and key concept summaries across advanced Mathematics and Economics questions.
3. Ingest supplemental diagrams for complex circuit and organic chemistry problems.
