# Runbook: Sync Backlog & Thundering Herd Recovery

## 1. Severity
- **Classification**: SEV-2 (High)
- **Impact**: Student attempt and mistake sync batches are queued or delayed, potentially inflating database latency during morning/reconnection spikes.

## 2. Symptoms
- High pending queue counts reported in client telemetry.
- Database connection spikes during school morning start or post-network outage resumption.
- Increased rate of `SYNC_RETRYABLE_FAILURE` errors.
- Elevated p95 database query latency on `attempts` and `exam_mistakes` tables.

## 3. How to Confirm
1. Query system health and recent attempt insertion rates:
   ```sql
   SELECT date_trunc('minute', created_at) AS min, count(*)
   FROM public.attempts
   WHERE created_at > NOW() - interval '1 hour'
   GROUP BY 1 ORDER BY 1 DESC;
   ```
2. Check sync diagnostic on sample pilot students:
   ```sql
   SELECT public.get_student_sync_diagnostic('<student_uuid>');
   ```
3. Inspect client error telemetry for dead-letter spikes or maximum retry limits.

## 4. Likely Causes
- **Thundering Herd**: Hundreds of devices in a pilot school reconnecting simultaneously after overnight or intermittent offline periods.
- Database locks on related tables during concurrent batch insertions.
- Transient network flakiness causing repeated retry loops.

## 5. Safe Diagnostic Steps
1. Verify if attempt inserts are failing due to duplicate key conflicts or slow constraints.
2. Check if dead-letter queue is isolating poisoned records:
   ```sql
   -- Verify if sync queue entries are failing idempotently
   SELECT count(*) FROM public.attempts WHERE created_at > NOW() - interval '15 minutes';
   ```
3. Check CPU and memory utilization on PostgreSQL server.

## 6. Safe Mitigation
1. Client exponential backoff with jitter is built-in (`SyncEngine` and `DriftSyncQueueRepository`). Ensure clients do not hammer server on tight loops.
2. If database load is critical:
   - Temporarily rate-limit or defer non-essential analytical report generation to prioritize transaction ingestion.
   - Scale connection pooler max client connections.
3. Poison pill isolation: If a malformed payload is causing crashes, verify that `markOperationDeadLetter` increments retry count up to 10 and moves the operation to dead-letter status, allowing healthy queued items behind it to process.

## 7. Rollback / Recovery
- Client mutations are durable in local Drift SQLite. Even during severe backlogs, no student data is discarded.
- Once load stabilizes, clients automatically drain queues in FIFO order.

## 8. Verification
1. Monitor pending queue counts across clients until normalized.
2. Verify zero duplicate attempts inserted (`attempts` deduplicated by `(user_id, exam_id, start_time)` or idempotency key).
3. Confirm database p95 response time returns to < 20ms baseline.

## 9. Escalation
- **Primary**: On-call Backend Engineer.
- **Secondary**: Client Mobile Lead.
