# FidelLearn Developer & Agent Guide (`AGENTS.md`)

## 1. Project Overview & Vision
**FidelLearn** is an offline-first Ethiopian national-exam preparation platform for secondary students (Grades 6, 8, and 12; initial rollout focused on Grade 12 Natural & Social Science streams). It provides verified exam practice, timed/untimed mock exams, step-by-step explanations, weak-topic analytics, Study Coin rewards, and personal-best "Exam Ghost" challenges. It supports English and Amharic with responsive experiences for Students, Teachers, School Admins, and Platform Admins.

---

## 2. Project Directory Structure
The project follows a **Feature-First Clean Architecture**:

```text
fidel_learn/
├── AGENTS.md                        # Master developer & AI agent guidelines
├── README.md                        # Setup, run, test, and architecture documentation
├── pubspec.yaml                     # Dependencies and asset declarations
├── analysis_options.yaml            # Strict Dart lint rules
├── docs/                            # Architectural specifications
│   ├── architecture.md              # System design, state management, and boundaries
│   ├── data-model.md                # PostgreSQL & Drift SQLite entity relationships
│   ├── offline-sync.md              # Sync queue, conflict resolution, & idempotency
│   ├── security.md                  # Supabase RLS, role guards, privacy, & audit
│   ├── content-package-format.md    # Offline zip/sqlite subject package spec
│   └── implementation-plan.md       # Phased roadmap & verification checkpoints
├── lib/
│   ├── app/                         # App widget, environment config, app initialization
│   ├── core/                        # Shared platform infrastructure
│   │   ├── auth/                    # Auth repository interfaces, models, & mock/supabase impls
│   │   ├── database/                # Drift SQLite database, DAOs, converters, & migrations
│   │   ├── errors/                  # Typed domain failure hierarchy & user-friendly messages
│   │   ├── localization/            # Generated l10n helpers, ARB delegates (en/am)
│   │   ├── networking/              # HTTP client, connectivity checker, retry policies
│   │   ├── routing/                 # GoRouter configuration, path constants, & role guards
│   │   ├── security/                # Token storage, data redaction, & privacy guards
│   │   ├── sync/                    # Sync engine, pending operations queue, & backoff
│   │   ├── theme/                   # Material 3 design tokens, typography, colors, light/dark
│   │   └── widgets/                 # Reusable UI components (buttons, cards, banners, charts)
│   └── features/                    # Feature vertical slices
│       ├── onboarding/              # Splash, language/grade/stream picker, welcome
│       ├── auth/                    # Phone/password login, register, password recovery
│       ├── home/                    # Student dashboard, streak, coins, quick actions
│       ├── subjects/                # Package browser, downloader, updater, storage manager
│       ├── question_bank/           # Question filters, search, diagram viewer
│       ├── exams/                   # Custom builder, mock exams, question palette, auto-save
│       ├── results/                 # Score summary, analytics, answer breakdown, report action
│       ├── progress/                # Weak-topic service, readiness score, historical charts
│       ├── bookmarks/               # Offline bookmark toggle, list, and filters
│       ├── mistakes/                # Mistake notebook, retry flow, mastery tracker
│       ├── rewards/                 # Study Coin append-only ledger, daily goals, ad gateway
│       ├── exam_ghost/              # Personal-best ghost comparison & attempt replay
│       ├── challenges/              # Friend & sponsored challenges
│       ├── teacher/                 # Class assignments, question picker, class analytics
│       ├── school/                  # School admin dashboard, teacher/student rosters, reports
│       ├── admin/                   # Content CMS, question verification, audit log
│       └── profile/                 # Account management, language/theme settings, deletion
├── assets/
│   ├── seed/                        # Original offline subject packages & question seeds
│   ├── images/                      # Illustrations, logos, diagrams (SVG/PNG)
│   └── translations/                # intl_en.arb and intl_am.arb
├── supabase/
│   ├── migrations/                  # Versioned PostgreSQL schema migrations with RLS
│   ├── seed.sql                     # Development seed data for Supabase
│   └── functions/                   # Edge functions for secure coin & admin actions
└── test/
    ├── unit/                        # Unit tests (scoring, weak-topics, ledger, sync)
    ├── widget/                      # Widget tests (onboarding, home, exam runner, review)
    ├── repository/                  # Local Drift & Mock repository contract tests
    └── integration/                 # End-to-end student journey flows
```

---

## 3. Core Architecture Rules
1. **Offline-First Resilience**: All core student workflows (question browsing, taking exams, viewing downloaded explanations, bookmarks, mistake notebook, and Exam Ghost) must function seamlessly without internet access.
2. **Repository Pattern & Mock Fallback**: All repositories (`AuthRepository`, `ContentRepository`, `ExamRepository`, `ProgressRepository`, `RewardRepository`) must have abstract interfaces with both:
   - A `DriftLocal` / Mock implementation (default for offline and zero-credential setups)
   - A `SupabaseRemote` implementation (for cloud sync)
3. **Immutability & Unidirectional Data Flow**: Use immutable models (e.g., Freezed / Dart 3 class patterns) and Riverpod Notifiers/Providers for clean state propagation.
4. **Append-Only Coin Ledger**: Study Coins must never be stored as a mutable balance. Balances are derived from verified ledger entries with unique transaction IDs and idempotency keys.
5. **No AI in Student MVP**: All questions, answers, and explanations must come from verified and approved static content packages.
6. **No Production Secrets**: Never hard-code credentials or service-role keys in client code.

---

## 4. Coding Conventions
- **Language**: Dart 3.x / Flutter 3.x (Null safety enforced).
- **Naming**:
  - Files: `snake_case.dart`
  - Classes & Enums: `PascalCase`
  - Variables & Functions: `camelCase`
  - Constants: `lowerCamelCase` or `kPascalCase` for top-level constants.
- **Error Handling**: Use typed `Failure` classes extending `Equatable` or custom domain hierarchies. Avoid throwing raw exceptions in domain/presentation layers.
- **Localization**: Never hard-code user-facing strings. Use `AppLocalizations.of(context)` backed by ARB files (`intl_en.arb`, `intl_am.arb`).
- **Clean Widgets**: Keep widgets compact, extracting reusable sub-components. Separate business logic into Riverpod state notifiers.

---

## 5. Commands for Setup, Code Generation, Testing, & Building
```powershell
# 1. Dependency installation
flutter pub get

# 2. Code generation (Drift, Freezed, JSON Serializable, Riverpod)
dart run build_runner build --delete-conflicting-outputs
dart run build_runner watch --delete-conflicting-outputs

# 3. Static analysis and formatting
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos

# 4. Running tests
flutter test --coverage
flutter test test/unit/exam_engine_test.dart
flutter test test/unit/weak_topic_service_test.dart
flutter test test/unit/coin_ledger_test.dart

# 5. Running the application
# Windows Desktop (Development / Local Mock)
flutter run -d windows

# Chrome / Web (Admin / Teacher Dashboard Preview)
flutter run -d chrome

# Android
flutter run -d android
```

---

## 6. Security & Privacy Constraints
- **Row Level Security (RLS)**: Enforced on all Supabase PostgreSQL tables.
- **Role-Based Access Control (RBAC)**: Enforced via GoRouter route guards and backend validation (`student`, `teacher`, `school_admin`, `platform_admin`).
- **Child Safety & Privacy**: Minimal personal data collection. No public student search. Leaderboards display student-chosen screen names, never phone numbers.
- **Zero Advertising during Exams**: Rewarded ads are strictly optional outside test sessions.
- **Audit Trails**: All content modifications and admin actions are logged with actor UUID, timestamp, and action detail.

---

## 7. Definition of Done
A feature or phase is considered **Done** only when:
1. Architectural alignment: Adheres to Clean Architecture, offline-first Drift storage, and mock-safe repositories.
2. Code quality: `dart format` is clean and `flutter analyze` produces 0 errors/warnings.
3. Automated test coverage: Unit, widget, and repository tests pass reliably.
4. Offline verification: Functions completely in simulated airplane/offline mode using local seed content.
5. Localization: All labels support English and Amharic with proper font rendering.
6. Documentation: Updates reflected in `README.md`, `docs/`, and phase walkthroughs.
