# Runbook: Backup & Disaster Recovery Drill

## 1. Severity
- **Classification**: SEV-1 (When executing disaster recovery) / Operational Maintenance (When performing scheduled drills)
- **Impact**: Full or partial recovery of production PostgreSQL database, Supabase storage assets, and configuration state.

## 2. RPO / RTO Objectives
- **Recovery Point Objective (RPO)**: <= 1 Hour (Continuous WAL archiving with hourly automated snapshot baselines).
- **Recovery Time Objective (RTO)**: <= 4 Hours (Target restoration of database and smoke verification).

## 3. Backup Architecture
1. **PostgreSQL Database**:
   - Automated daily base backups + continuous Write-Ahead Log (WAL) archiving provided by Supabase / Cloud PostgreSQL.
   - Point-in-Time Recovery (PITR) retention: 7 days for pilot / staging; 30 days for production.
2. **Supabase Storage**:
   - Curriculum packages (`.flpkg`): Immutable, versioned source artifacts replicated in cold object storage.
   - Institutional report artifacts: Ephemeral or reconstructable from raw relational attempt data.
3. **Configuration & Secrets**:
   - Environment templates and non-secret configuration tracked in version control.
   - Production secrets managed via KMS / Vault / GitHub Environment Secrets.

## 4. Controlled Restoration Drill Procedure
> [!IMPORTANT]
> Never perform a restore drill directly into the active production database. Always use an isolated recovery database or staging clone.

### Step 1: Provision Isolated Target Environment
Ensure an empty or staging target PostgreSQL instance is provisioned:
```bash
export TARGET_DB_URL="postgres://postgres:password@recovery-host:5432/fidel_recovery"
```

### Step 2: Produce & Export Backup Snapshot (Option A: Archive Includes ACLs)
Omitting `--no-privileges` ensures all database ACLs, role grants, and revocations are preserved inside the custom archive:
```bash
pg_dump --format=custom --no-owner \
  --dbname="$SOURCE_DB_URL" \
  --file="fidel_backup_drill_$(date +%Y%m%d_%H%M%S).dump"
```

### Step 3: Restore Snapshot to Target Environment
Restore the snapshot including all schema definitions, data rows, and privilege grants directly into the isolated recovery database:
```bash
pg_restore --clean --if-exists --no-owner \
  --dbname="$TARGET_DB_URL" \
  "fidel_backup_drill_$(date +%Y%m%d_%H%M%S).dump"
```

### Step 4: Verify Data Integrity Post-Restore
Run integrity checks on restored entities:
```sql
SELECT count(*) AS total_schools FROM public.schools;
SELECT count(*) AS total_memberships FROM public.school_memberships;
SELECT count(*) AS total_licenses FROM public.school_licenses;
SELECT count(*) AS total_attempts FROM public.attempts;
SELECT count(*) AS total_audit_events FROM public.audit_log;
```

### Step 5: Verify Multi-Tenant Isolation Post-Restore
Ensure RLS and security functions remain intact on restored instance:
```bash
node tools/test_postgres_tenancy.js
node tools/test_postgres_p12_production_readiness.js
```
Confirm:
- Cross-tenant data isolation is fully enforced.
- Student cannot access records belonging to other schools.
- `SECURITY DEFINER` functions maintain `search_path = public, pg_temp`.

### Step 6: Document Drill Results
Record the restore event in the production audit log or operational ledger:
```sql
INSERT INTO public.audit_log (
    action, target_table, target_id, metadata
) VALUES (
    'database_restore_test',
    'system',
    'recovery_drill',
    jsonb_build_object(
        'drill_date', NOW(),
        'restored_by', 'lead_devops',
        'result', 'SUCCESS',
        'rto_minutes', 35
    )
);
```

## 5. Emergency Incident Response Escalation
- **Primary**: Disaster Recovery Commander / DevOps Lead.
- **Secondary**: Platform Architect.
- **Executive**: Chief Technology Officer.
