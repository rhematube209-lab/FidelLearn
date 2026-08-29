# FidelLearn Offline Synchronization Engine

## 1. Sync Principles & Guarantees
- **Offline First**: All user actions (taking exams, reviewing, bookmarking, earning local milestone events) write to local Drift SQLite immediately.
- **Idempotent Synchronization**: Every sync payload carries an `idempotency_key` (UUID v4 or deterministic key such as `daily_streak_YYYY_MM_DD_userID`).
- **Conflict Resolution Rules**:
  1. *Published Educational Content*: Server version is authoritative (Server wins).
  2. *Completed Attempts*: Append-only immutable records. History is never overwritten.
  3. *Attempt Responses*: Frozen upon submission.
  4. *Bookmarks*: Merged by `(user_id, question_id)` using latest `created_at` / `is_active` state.
  5. *Mistakes*: Counter increments merged; `is_mastered = true` takes precedence if correct attempt verified.
  6. *Coin Transactions*: Server is strictly authoritative. Ledger transactions are evaluated with balance checks and idempotency.

---

## 2. Pending Operations Queue Structure
A local Drift table `sync_queue` stores pending server mutations:

```text
┌───────────────────────────────────────────────────────────┐
│                     sync_queue                            │
├───────────────────┬───────────────────────────────────────┤
│ id                │ UUID (PK)                             │
│ operation_type    │ 'SUBMIT_ATTEMPT' | 'UPDATE_BOOKMARK'  │
│                   │ 'LOG_COIN_EVENT' | 'UPDATE_PROFILE'   │
│ payload_json      │ JSON payload string                   │
│ idempotency_key   │ Unique string                         │
│ retry_count       │ Integer (default 0)                   │
│ next_retry_at     │ Timestamp (UTC)                       │
│ last_error        │ Text (nullable)                       │
│ created_at        │ Timestamp (UTC)                       │
└───────────────────┴───────────────────────────────────────┘
```

---

## 3. Backoff and Connectivity Management
- Sync triggers on:
  - Network connectivity restored (monitored via `connectivity_plus`)
  - App launch / foreground resumption
  - Explicit manual pull-to-refresh
- Retry policy: Bounded exponential backoff:
  $$\Delta t = \min(2^{\text{retry\_count}} \times 2\,\text{sec}, 300\,\text{sec}) + \text{jitter}$$
- Max retries before flagging for manual review: 10 attempts.
