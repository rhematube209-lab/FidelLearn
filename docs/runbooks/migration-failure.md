# Runbook: Database Migration Failure & Recovery

## 1. Severity
- **Classification**: SEV-1 (Critical during release deployment)
- **Impact**: Database schema is partially applied or locked; deployment pipeline is halted.

## 2. Symptoms
- CI/CD deployment fails at migration step with PostgreSQL error code (e.g. `42P01`, `42703`, `23505`).
- Application reports `PostgrestException: column does not exist` or `relation does not exist`.
- Supabase CLI reports migration mismatch.

## 3. How to Confirm
1. Inspect deployment runner logs for the exact SQL statement and error message.
2. Query Supabase migration history:
   ```sql
   SELECT * FROM supabase_migrations.schema_migrations ORDER BY version DESC LIMIT 5;
   ```
3. Check table definition and locks in PostgreSQL:
   ```sql
   SELECT schemaname, relname, n_dead_tup FROM pg_stat_user_tables WHERE schemaname = 'public';
   ```

## 4. Likely Causes
- Migration attempted destructive `ALTER TABLE` or `DROP COLUMN` while active queries were running.
- Incompatible constraint violated by existing production data (e.g. `NOT NULL` without `DEFAULT`).
- Missing transaction wrapping (`BEGIN ... COMMIT`) allowing partial statement execution before failure.
- Out-of-order migration execution across development branches.

## 5. Safe Diagnostic Steps
1. Verify which statements inside migration file executed before failure.
2. Check if table locks are hanging:
   ```sql
   SELECT pid, query, mode, granted FROM pg_locks l JOIN pg_stat_activity a ON l.pid = a.pid WHERE a.query ILIKE '%alter%';
   ```

## 6. Safe Mitigation
1. **Never attempt blind manual DOWN migrations on production.** Destructive rollbacks can wipe production data.
2. If migration failed inside a transaction (`BEGIN ... COMMIT`), the entire migration safely rolled back with zero schema alteration. Verify rollback:
   ```sql
   -- Confirm schema matches previous migration baseline
   SELECT public.system_health_status();
   ```
3. If migration was non-transactional and left orphan objects:
   - Identify orphan object (e.g. half-created index or table).
   - Drop newly created orphan object explicitly.

## 7. Rollback / Recovery
1. Create a forward-fix migration that addresses the syntax/constraint error cleanly.
2. Test forward-fix against staging clone before applying to production.
3. Apply fixed migration via deployment pipeline.

## 8. Verification
1. Run full PostgreSQL test suite:
   ```bash
   node tools/test_postgres_p12_production_readiness.js
   ```
2. Verify all 7 regression suites pass 100%.
3. Confirm application health checks return `status: operational`.

## 9. Escalation
- **Primary**: Database Administrator / Lead Backend Engineer.
- **Secondary**: Platform Architect.
