# FidelLearn (ፊደል ለርን) 🇪🇹

**Offline-First Ethiopian National Exam Preparation Platform**  
Designed for Grades 6, 8, and 12 (Initial rollout: Grade 12 Natural & Social Sciences).

---

## 🌟 Overview & Philosophy

**FidelLearn** is built to address the unique educational and infrastructural needs of secondary students in Ethiopia. Designed from the ground up for high resilience in low-connectivity and intermittent power environments:

1. **100% Offline-First Student MVP**: All core exam workflows—custom test builder, timed and untimed mock exams, auto-saving active attempts, step-by-step verified explanations, mistake notebook, bookmarks, Exam Ghost personal-best comparator, and weak-topic analytics—function without an active internet connection.
2. **Deterministic & Static Pedagogical Core**: Zero Generative AI in the student experience. All questions, distractors, solutions, key concepts, and common pitfalls are derived from static, verified content packages created by subject-matter educators.
3. **Study Coin Append-Only Ledger**: Student rewards and coin balances are computed via an immutable, cryptographically verifiable append-only ledger that guards against double-spending and overdrafts.
4. **Bilingual Experience**: Full interface and content support in **English** and **Amharic (አማርኛ)**.
5. **Role-Based Clean Architecture**: Multi-role system architecture designed for Students, Teachers, School Admins, and Platform Admins.

---

## 📁 Repository Structure

```text
fidel_learn/
├── AGENTS.md                        # Master developer & AI agent guidelines
├── README.md                        # Project overview, setup, run & testing docs
├── pubspec.yaml                     # Dependencies and asset declarations
├── analysis_options.yaml            # Strict Dart lint rules
├── docs/                            # In-depth architectural specifications
│   ├── architecture.md              # Layer boundaries, state flow, and Clean Architecture
│   ├── data-model.md                # Normalized PostgreSQL & SQLite Drift entity schemas
│   ├── offline-sync.md              # Offline queue, retry backoff, and idempotency spec
│   ├── security.md                  # Supabase RLS policies, RBAC, and child privacy
│   ├── content-package-format.md    # Offline zip bundle (.flpkg) specification
│   └── implementation-plan.md       # Roadmap & verification checkpoints
├── lib/
│   ├── app/                         # App widget, theme bindings, route configuration
│   ├── core/                        # Shared infrastructure
│   │   ├── errors/                  # Typed domain failure hierarchy
│   │   ├── providers/               # Centralized Riverpod StateNotifiers & providers
│   │   ├── routing/                 # GoRouter declarative routing with guards
│   │   └── theme/                   # Material 3 Ethiopian emerald/gold design tokens
│   └── features/                    # Feature vertical slices
│       ├── onboarding/              # Splash, language/grade/stream picker
│       ├── auth/                    # Phone/password auth & mock repository
│       ├── home/                    # Student dashboard, streak, coins, quick actions
│       ├── subjects/                # Offline packages, units, topics, downloads
│       ├── question_bank/           # Question models, choices, explanations
│       ├── exams/                   # Custom builder, active runner, palette, autosave
│       ├── results/                 # Score breakdown, solutions review, reporting
│       ├── progress/                # Weak-topic detector & readiness formula (0-100)
│       ├── bookmarks/               # Offline bookmarks repository & list
│       ├── mistakes/                # Mistake notebook, mastery tracker, retry flow
│       ├── rewards/                 # Append-only coin ledger & optional ad gateway
│       ├── exam_ghost/              # Personal-best ghost comparator & retake
│       └── profile/                 # Profile editor, language switch, theme toggle
├── assets/
│   ├── seed/                        # Original offline demonstration question seeds
│   ├── images/                      # Diagrams and vector illustrations
│   └── translations/                # intl_en.arb and intl_am.arb
├── supabase/
│   ├── migrations/                  # PostgreSQL schema with Row Level Security (RLS)
│   └── seed.sql                     # Development seed data
└── test/
    ├── unit/                        # Pure domain engine, scoring, ghost, & ledger tests
    └── widget/                      # End-to-end student offline journey widget tests
```

---

## 🚀 Quick Start & Development Setup

### Prerequisites
- **Flutter SDK**: 3.29.x or higher
- **Dart SDK**: 3.7.x or higher
- **Windows Desktop / Chrome / Android Emulator**

### 1. Install Dependencies
```powershell
flutter pub get
```

### 2. Run Static Analysis & Lints
```powershell
flutter analyze
```

### 3. Run Automated Tests
```powershell
flutter test
```

### 4. Launch the App
```powershell
# Windows Desktop (Fastest for local development)
flutter run -d windows

# Chrome Web Preview
flutter run -d chrome

# Android Device / Emulator
flutter run -d android
```

---

## 🧪 Automated Test Suite

FidelLearn includes automated unit and widget test suites:

| Test Suite | File | Description |
| :--- | :--- | :--- |
| **Exam Engine** | `test/unit/exam_engine_test.dart` | Attempt initialization, choice selection, review flag toggles, scoring math & percentages. |
| **Weak-Topic Detector** | `test/unit/weak_topic_service_test.dart` | Statistical threshold filtering, insufficient data protection, and readiness score (0-100). |
| **Study Coin Ledger** | `test/unit/coin_ledger_test.dart` | Balance aggregation, overdraft prevention (`InsufficientCoinsFailure`), and idempotency duplicate prevention. |
| **Exam Ghost Comparator** | `test/unit/exam_ghost_test.dart` | Score delta, speed delta, and Personal Best headline detection. |
| **Content Repository** | `test/unit/question_filter_test.dart` | Unverified draft exclusion, topic and difficulty filtering, query pagination. |
| **Student Offline Journey** | `test/widget/student_journey_test.dart` | End-to-end widget test from Splash to Home Dashboard with mock data. |

To run all tests:
```powershell
flutter test
```

---

## 🔒 Security & Privacy Commitments

- **Row Level Security (RLS)**: Supabase PostgreSQL tables are locked down with strict RLS policies ensuring students can only access their own attempts, ledger transactions, bookmarks, and mistake records.
- **Child & Student Privacy**: No public student directory or phone number discovery. Leaderboards display student-chosen screen names only.
- **Zero Intrusive Ads**: No advertisements during test or study sessions. Optional rewarded ads are strictly student-initiated outside test environments.
- **Static Content Verification**: All content must have `verification_status = 'published'` to be accessible to student accounts.
