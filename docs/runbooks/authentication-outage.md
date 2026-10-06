# Runbook: Authentication Outage & Recovery

## 1. Severity
- **Classification**: SEV-1 (Critical)
- **Impact**: New logins and session refreshes fail. Already logged-in offline students remain fully operational on local storage.

## 2. Symptoms
- Login requests return 500/502/504 errors or auth service timeouts.
- Client applications show error code `AUTH_SERVICE_UNAVAILABLE` or `AUTH_TOKEN_EXPIRED`.
- Attempted sync requests fail with `401 Unauthorized` without successful token refresh.

## 3. How to Confirm
1. Test Supabase Auth GoTrue service directly:
   ```bash
   curl -I "https://$SUPABASE_PROJECT_REF.supabase.co/auth/v1/health"
   ```
2. Verify token issuance with test credentials or check GoTrue container logs:
   ```bash
   docker logs supabase-auth --tail 100
   ```
3. Check error rates in Supabase dashboard under API & Auth metrics.

## 4. Likely Causes
- GoTrue auth server crash or memory leak.
- PostgreSQL connection limit reached for auth service role.
- Supabase cloud auth infrastructure disruption.
- Expired JWT signing secrets or misconfigured environment variables.

## 5. Safe Diagnostic Steps
1. Verify if database is accepting connections from auth role:
   ```sql
   SELECT count(*) FROM auth.users;
   ```
2. Check JWT expiration and clock skew:
   ```sql
   SELECT NOW(), current_setting('TIMEZONE');
   ```
3. Verify whether issue is isolated to phone login or affects email/password as well.

## 6. Safe Mitigation
1. Restart GoTrue auth daemon:
   ```bash
   # On self-hosted / local:
   docker restart supabase-auth
   ```
2. If cloud provider issue:
   - Check Supabase status page (`status.supabase.com`).
   - Enable maintenance notice banner in client application metadata.
3. Advise support: Do NOT ask users to log out. Offline local study and cached sessions will continue working. Logging out while auth is down prevents re-entry.

## 7. Rollback / Recovery
- Once GoTrue recovers, clients with queued sync mutations will automatically refresh their JWT and resume synchronization via bounded exponential backoff.

## 8. Verification
1. Perform test login with canary account.
2. Verify JWT token issuance and refresh token rotation.
3. Confirm queued client synchronization succeeds without authentication failure.

## 9. Escalation
- **Primary**: On-call Backend Engineer.
- **Secondary**: Security & Identity Lead.
