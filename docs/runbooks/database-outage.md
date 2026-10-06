# Runbook: Database Outage & Recovery

## 1. Severity
- **Classification**: SEV-1 (Critical)
- **Impact**: All authenticated cloud queries, student sync batches, and portal analytics are blocked. Device-local learning continues offline via Drift SQLite.

## 2. Symptoms
- Server health endpoint (`system_health_status()`) returns connection error or timeouts.
- Client applications report error code `SERVER_DATABASE_UNAVAILABLE` or `NETWORK_UNAVAILABLE`.
- Students observe "Working offline" status banner with sync queue retaining mutations.
- Teacher/Admin portals show "Unable to load school records" with retry action.

## 3. How to Confirm
1. Test direct database connectivity from bastion/CLI:
   ```bash
   psql -h $DB_HOST -U postgres -d postgres -c "SELECT public.system_health_status();"
   ```
2. Inspect Supabase dashboard / Cloud provider metrics:
   - Check connection pool saturation (pgbouncer clients vs pool size).
   - Check CPU / RAM usage and disk I/O metrics.
3. Review structured logs for `PostgrestException: connection refused` or `503 Service Unavailable`.

## 4. Likely Causes
- Connection pool exhaustion due to a burst of simultaneous clients (e.g. morning sync herd).
- Unplanned PostgreSQL engine restart or cloud infrastructure maintenance.
- Storage volume full on database instance.
- Runaway expensive query locking key catalog or membership tables.

## 5. Safe Diagnostic Steps
1. Verify active connection count without adding heavy query load:
   ```sql
   SELECT count(*), state FROM pg_stat_activity GROUP BY state;
   ```
2. Check for blocking queries or locks:
   ```sql
   SELECT pid, query, state, age(clock_timestamp(), query_start)
   FROM pg_stat_activity
   WHERE state != 'idle' AND age(clock_timestamp(), query_start) > interval '30 seconds';
   ```
3. Inspect system disk space and swap usage.

## 6. Safe Mitigation
1. If runaway query is blocking transactions:
   ```sql
   SELECT pg_cancel_backend(<pid>); -- First attempt graceful cancel
   -- If unresponsive:
   SELECT pg_terminate_backend(<pid>);
   ```
2. If connection pool is exhausted:
   - Temporarily increase pool limits on connection pooler.
   - Restart Supabase connection pooler (`pooler` container/service).
3. If database crashed:
   - Trigger instance restart via provider console.

## 7. Rollback / Recovery
- If database corruption occurred, initiate Point-in-Time Recovery (PITR) to latest known consistent snapshot prior to outage (see `backup-restore.md`).
- Validate tenant isolation post-recovery.

## 8. Verification
1. Run `SELECT public.system_health_status();` and confirm `'status': 'operational'`.
2. Confirm client sync queues successfully drain with 200 OK.
3. Confirm school leadership and teacher portals load without timeouts.

## 9. Escalation
- **Primary**: On-call Infrastructure Lead.
- **Secondary**: Platform Architect.
- **Provider**: Supabase Enterprise / Cloud Host support ticket.
