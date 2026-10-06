# Runbook: Institutional Reporting Failure & Recovery

## 1. Severity
- **Classification**: SEV-3 (Moderate)
- **Impact**: School Leadership or Teachers unable to generate institutional analytics, progress summaries, or PDF exports. Core classroom learning is unaffected.

## 2. Symptoms
- Leadership or Teacher hub shows "Failed to load report" or timeout error.
- Report export returns `REPORTING_OFFLINE` or `REPORT_GENERATION_FAILED`.
- Client logs report slow query execution (> 10s).

## 3. How to Confirm
1. Test report authority and generation RPC directly:
   ```sql
   SELECT public.validate_report_authority('<school_uuid>', 'executive_summary');
   ```
2. Test report execution timing:
   ```sql
   EXPLAIN ANALYZE
   SELECT * FROM public.get_school_stream_summary('<school_uuid>', '2026/27');
   ```
3. Check `public.report_runs` for failed execution rows:
   ```sql
   SELECT * FROM public.report_runs WHERE school_id = '<school_uuid>' ORDER BY created_at DESC LIMIT 5;
   ```

## 4. Likely Causes
- Heavy concurrent report generation during administrative end-of-term periods.
- Missing index on large exam attempts or mistakes dataset.
- Memory limit exceeded in server worker during PDF rendering.
- Complex Natural vs Social Math stream filtering contention.

## 5. Safe Diagnostic Steps
1. Verify query execution plan with `EXPLAIN ANALYZE`.
2. Check if student count or attempt volume requires pagination.
3. Verify that student sync freshness indicators are calculating correctly without blocking full report calculation.

## 6. Safe Mitigation
1. **Query Tuning**: Ensure indices `idx_attempts_user_exam` and `idx_school_memberships_school` are active and analyzed:
   ```sql
   ANALYZE public.attempts;
   ANALYZE public.school_memberships;
   ```
2. **Concurrency Throttling**: Limit concurrent heavy export jobs to prevent CPU starvation.
3. **Data Freshness Warning**: If sync is incomplete, report renders with documented "Stale/Partial data disclaimer" rather than failing completely.

## 7. Rollback / Recovery
- Re-run report generation with narrowed scope (e.g. specific stream or classroom rather than school-wide) while performance optimization is investigated.

## 8. Verification
1. Confirm `get_school_stream_summary` executes under 50ms.
2. Confirm report export produces valid metadata record in `public.report_runs`.
3. Confirm non-causal disclaimer and sync freshness disclosures render clearly.

## 9. Escalation
- **Primary**: Backend Analytics Engineer.
- **Secondary**: Lead Database Engineer.
