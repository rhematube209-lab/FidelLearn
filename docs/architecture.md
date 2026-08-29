# FidelLearn Architecture Specification

## 1. Architectural Style & Boundaries
FidelLearn employs a **Feature-First Clean Architecture** with strict layer separation:

```text
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                       │
│  - Flutter Widgets (Material 3, Responsive Desktop/Mobile)  │
│  - Riverpod StateNotifiers / AsyncNotifiers (UI State)      │
│  - GoRouter Routing & Role-Based Route Guards               │
└──────────────────────────────┬──────────────────────────────┘
                               │ (Calls use-cases / repositories)
┌──────────────────────────────▼──────────────────────────────┐
│                       Domain Layer                          │
│  - Entity Models (Immutable / Pure Dart)                    │
│  - Domain Services (Scoring, Weak Topics, Ghost Comp, Coin) │
│  - Repository Interfaces (Contracts)                        │
│  - Failure & Error Hierarchy                                │
└──────────────────────────────┬──────────────────────────────┘
                               │ (Implements contracts)
┌──────────────────────────────▼──────────────────────────────┐
│                    Data & Infrastructure                    │
│  - Local Database: Drift (SQLite) + Seed Packages           │
│  - Remote Database: Supabase (PostgreSQL + Auth + Storage)  │
│  - Offline Sync Engine: Operation Queue + Exponential Backoff│
│  - Secure Storage & Token Manager                           │
│  - Mock Implementations (Deterministic offline development) │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. State Management & Dependency Injection
- **State Management**: **Flutter Riverpod 2.x** with code-generation (`riverpod_annotation`).
- **Data Flow**: Unidirectional data flow. UI dispatches events -> Riverpod Notifier executes business logic via Repository / Domain Services -> Updates Immutable State -> UI reacts.
- **Provider Scoping**: Feature providers are modular and independently testable with overrides in unit and widget tests.

---

## 3. Storage Architecture: Hybrid Offline-First
1. **Local Authoritative for Execution**:
   - Question bank, active exams, question flags, and unfinished drafts are saved locally in SQLite via **Drift**.
   - Offline packages (zip/sqlite bundle) are imported into local Drift database upon download.
2. **Cloud Authoritative for Synchronized State**:
   - Once online, completed attempt records, bookmark changes, mistake statuses, and Study Coin ledger transactions synchronize to Supabase PostgreSQL.
   - Server validates coin transactions and role permissions.

---

## 4. Multi-Role UI Navigation
- **Students**: Mobile-optimized bottom navigation (Home, Practice, Progress, Rewards, Profile).
- **Teachers**: Responsive navigation rail/sidebar (Overview, Classes, Exams, Results, Profile).
- **School Admins**: School analytics, teacher rosters, class comparisons, summary exports.
- **Platform Admins**: Content management (Question CRUD, verification workflow, package publisher), coin economics, audit logs.
