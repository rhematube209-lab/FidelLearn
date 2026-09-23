# FidelLearn — Coin Security Model

## Principle

> The client must never determine or request its own reward amount.

This document explains why this matters and exactly how FidelLearn enforces it.

---

## The Problem with Client-Determined Amounts

A naive implementation might let the Flutter app call:

```dart
// INSECURE — never do this
supabase.from('coin_ledger').insert({
  'user_id': userId,
  'amount': 100,        // Client sends its own amount
  'transaction_type': 'CREDIT',
  'reason': 'exam_completed',
});
```

This is insecure because:
1. Any user can intercept the request and change `amount: 100` to `amount: 999999`
2. A compromised device can insert arbitrary credits
3. Even with RLS, if the client determines the amount, the server has no way to
   validate whether the amount is legitimate without re-implementing all the
   business rules

The same problem applies to a server that simply validates `amount > 0` —
the client still determines the amount.

---

## The FidelLearn Event-Claim Model

Instead, the client sends an **event claim**:

```dart
// SECURE — Flutter sends this to the sync queue
SyncOperation(
  operationType: SyncOperationType.claimReward,
  payload: {
    'event_type':       'exam_completed',    // What happened
    'source_entity_id': attemptId,           // Proof (which attempt)
    'idempotency_key':  'exam_completed_${attemptId}_${userId}',
  },
  // Note: no 'amount' field
);
```

The sync engine forwards this to the `claim-reward` Edge Function:

```
Flutter
  → SyncEngine (dequeues when online)
      → claim-reward Edge Function
          → Authenticates JWT
          → Looks up event_type in reward_rules table (server-controlled)
          → Verifies attempt exists and belongs to user
          → Checks idempotency_key not already used
          → Inserts CREDIT row with server-determined amount
          → Returns confirmed ledger entry
```

---

## Reward Rules Table (Server-Controlled)

The `reward_rules` table in PostgreSQL is the single source of truth for amounts:

| event_type | reward_amount | source_table |
|---|---|---|
| `exam_completed` | 10 | `attempts` |
| `daily_streak` | 5 | `profiles` |
| `challenge_completed` | 20 | `challenges` |
| `signup_bonus` | 50 | `profiles` |
| `mistake_mastered` | 3 | `mistake_records` |

Only `platform_admin` users may modify this table. Authenticated users and
anonymous users may only SELECT (for display purposes).

Changing a reward amount requires:
1. A platform_admin to log into the admin dashboard
2. An explicit UPDATE to the `reward_rules` table
3. All future reward claims automatically use the new amount

---

## Local Optimistic State

Flutter still maintains a local coin balance for immediate UI feedback:

1. Student completes exam
2. Flutter locally appends a `CoinLedgerEntry` with `serverVerified: false`
   and `amount` based on locally-cached `reward_rules` values
3. UI shows updated balance immediately (optimistic)
4. Sync engine sends the event claim to the server
5. Server confirms → local entry updated to `serverVerified: true`
6. If server returns different amount (rule changed since last sync) → local
   entry updated to server-confirmed amount

The local amount is for display only. The server is authoritative.

---

## Coin Redemption Model

Redemptions follow the same principle — client sends item ID, server
determines cost:

```
Flutter
  → SyncEngine (dequeues when online)
      → redeem-coins Edge Function
          → Authenticates JWT
          → Looks up item_id in redemption_catalog (server-controlled cost)
          → Acquires advisory lock on user_id (prevents concurrent negative balance)
          → Validates balance >= cost
          → Atomically inserts DEBIT row
          → Returns confirmed debit entry
```

The advisory lock ensures two simultaneous redemption requests cannot both
succeed with an insufficient balance. Only one wins; the other receives a
402 Insufficient Balance response.

---

## Database Enforcement

RLS blocks ALL direct client inserts to `coin_ledger`:

```sql
CREATE POLICY "coin_ledger_no_direct_insert"
    ON public.coin_ledger FOR INSERT
    WITH CHECK (FALSE);  -- Rejected for all clients
```

The only way to insert into `coin_ledger` is through:
1. `claim_reward_internal` SECURITY DEFINER function (called by `claim-reward` Edge Function)
2. `redeem_coins_atomic` SECURITY DEFINER function (called by `redeem-coins` Edge Function)

Both functions are restricted:
```sql
REVOKE EXECUTE ON FUNCTION public.claim_reward_internal(...) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.redeem_coins_atomic(...) FROM PUBLIC;
```

They can only be called by the Supabase service role used by Edge Functions —
not by any authenticated client.

---

## Idempotency

Every coin operation carries an `idempotency_key`. The server checks this
before inserting:

- `exam_completed_<attempt_uuid>_<user_id>` — ensures one reward per attempt
- `daily_streak_2026-09-24_<user_id>` — ensures one streak reward per day
- `signup_bonus_<user_id>` — ensures the bonus is awarded exactly once

If the sync engine retries a failed request (e.g., network timeout after the
server succeeded), the second call hits the idempotency check and returns the
existing entry without creating a duplicate.
