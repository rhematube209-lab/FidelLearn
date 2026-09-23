# FidelLearn — Production Deployment Runbook

## Pre-Deployment Checklist

Before running any migration against production:

- [ ] All tests pass: `flutter test --coverage`
- [ ] `flutter analyze --fatal-infos` returns 0 issues
- [ ] Migration has been applied to staging and verified for at least 24h
- [ ] Staging Edge Functions are passing health checks
- [ ] Supabase Security Advisor shows 0 critical findings
- [ ] Database backup is confirmed (Supabase dashboard → Settings → Database → Backups)
- [ ] On-call engineer is aware of the deployment window
- [ ] Rollback procedure is reviewed and ready

---

## Migration Application

### Via CI/CD (Recommended)

1. Merge PR to `main` branch
2. GitHub Actions `deploy-production.yml` triggers automatically
3. Validation job runs and confirms credentials are present
4. **Manual approval gate** — a required reviewer must approve in GitHub UI
   - Go to: GitHub Actions → Deploy Production → Await Production Approval → Review deployments
5. Migrations apply automatically after approval
6. Edge Functions deploy automatically
7. Health check verifies each function returns 401

### Manual (Emergency Only)

```bash
# Link to production project
supabase link --project-ref YOUR_PROD_REF

# Dry-run first (shows SQL that will be applied)
supabase db diff --project-ref YOUR_PROD_REF

# Apply migrations
supabase db push \
  --project-ref YOUR_PROD_REF \
  --password YOUR_DB_PASSWORD
```

**Do not run manual migrations during peak usage hours (18:00–22:00 EAT).**

---

## Edge Function Deployment

```bash
supabase functions deploy claim-reward  --project-ref YOUR_PROD_REF
supabase functions deploy redeem-coins  --project-ref YOUR_PROD_REF
supabase functions deploy grant-role    --project-ref YOUR_PROD_REF
```

Verify health after deployment:
```bash
# Each should return HTTP 401 (authenticated endpoint)
curl -s -o /dev/null -w "%{http_code}" \
  -X POST https://YOUR_PROD_REF.functions.supabase.co/claim-reward
```

---

## Rollback Procedure

### Edge Function Rollback

Edge Functions can be redeployed from any previous Git commit:
```bash
git checkout <previous-commit>
supabase functions deploy claim-reward --project-ref YOUR_PROD_REF
```

### Migration Rollback

> ⚠️ Supabase does not auto-generate rollback scripts. Each migration must
> have a manual rollback plan.

For migration `20260924000000_production_hardening.sql`:

**The handle_new_user trigger fix cannot be safely rolled back** — rolling back
would re-introduce the privilege escalation vulnerability. If there is a
production issue with the trigger, fix it forward with a new migration.

For the RLS policy changes:
```sql
-- Example: restore a removed policy
CREATE POLICY "coin_ledger_user_insert" ON public.coin_ledger
  FOR INSERT WITH CHECK (auth.uid() = user_id::uuid);
```

---

## Post-Deployment Verification

Run these checks within 30 minutes of deployment:

1. **Privilege escalation fix:**
   - Attempt registration with `role: platform_admin` in metadata
   - Verify user receives only `student` role in `user_roles` table

2. **Coin claim:**
   - Complete an exam in staging (or use a test account)
   - Verify `claim-reward` Edge Function creates ledger entry with correct amount
   - Verify `server_verified = true` on the returned row

3. **Direct insert rejection:**
   - Attempt: `supabase.from('coin_ledger').insert({...})` via authenticated client
   - Expect: RLS error (row-level security policy violated)

4. **Offline exam resilience:**
   - Start an exam, kill network, complete exam
   - Restart app — active attempt should still be present (Drift persistence)

---

## Backup Configuration

Supabase provides automated backups on the **Pro plan and above**:

1. Go to: Supabase Dashboard → Settings → Database → Backups
2. Enable **Point-in-Time Recovery (PITR)**
3. Set retention to 7 days minimum (30 days recommended for production)

For manual backup before a migration:
```bash
# Export full database
pg_dump \
  --format=custom \
  --no-acl \
  --no-owner \
  postgresql://postgres:PASSWORD@db.YOUR_REF.supabase.co:5432/postgres \
  > backup_$(date +%Y%m%d_%H%M%S).dump
```

---

## Rate Limit Configuration

Configure in Supabase Dashboard → Authentication → Rate Limits:

| Setting | Recommended Value |
|---|---|
| Email OTP / Magic Link | 3 per hour per email |
| SMS OTP | 2 per hour per phone |
| Signup | 5 per hour per IP |
| Token refresh | 30 per hour per user |

---

## Security Advisor

Run before every production deployment:
1. Supabase Dashboard → Project → Advisors → Security
2. Address all Critical findings before proceeding
3. Document any accepted risks for Medium/Low findings

Common findings to watch for:
- `auth.users` exposed via public views
- Functions with mutable `search_path` (all new functions use fixed `search_path`)
- Tables missing RLS
- Extensions with elevated privileges

---

## Monitoring & Alerting

Connect Supabase Logs to an external monitoring service:

1. Supabase Dashboard → Logs → Log Drains
2. Configure drain to: Datadog / Grafana Cloud / BetterStack / Logtail
3. Set alerts on:
   - Edge Function error rate > 5% over 5 minutes
   - Auth failure rate > 20% over 5 minutes (brute force indicator)
   - RLS policy violations spike (potential attack indicator)
   - Database connection pool exhaustion

---

## SMS Provider Setup (Manual)

Phone OTP requires an external provider:

1. Choose: **Africa's Talking** (recommended for Ethiopian market) or Telerivet
2. Supabase Dashboard → Authentication → Providers → Phone
3. Enable phone provider
4. Select provider and enter API key
5. Set OTP template in Amharic and English
6. Test with a real Ethiopian phone number before launching

Africa's Talking API key must be stored in Supabase Vault:
```bash
supabase secrets set AFRICAS_TALKING_API_KEY=your_key --project-ref YOUR_PROD_REF
```
