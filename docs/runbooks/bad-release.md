# Runbook: Bad Release & Emergency Rollback

## 1. Severity
- **Classification**: SEV-1 (Critical)
- **Impact**: Released client version causes fatal app crashes, renders exam navigation unusable, or violates backend schema contracts.

## 2. Symptoms
- Sudden spike in crash telemetry (`ErrorTelemetry.recentEvents`).
- Surge in support tickets or user reports of white screens/freezes after app update.
- Client version compatibility errors (`UNSUPPORTED_VERSION` or `CLIENT_COMPATIBILITY_REJECTED`).

## 3. How to Confirm
1. Review crash telemetry and error taxonomy:
   ```json
   { "category": "server", "code": "CLIENT_COMPATIBILITY_REJECTED" }
   ```
2. Verify production release ledger:
   ```sql
   SELECT * FROM public.production_releases ORDER BY deployed_at DESC LIMIT 5;
   ```
3. Test Canary device with the latest released version.

## 4. Likely Causes
- Regressed Flutter dependency or unhandled null assertion on specific device form-factors.
- Desynchronized database migration deployment where backend RPC signature was modified.
- Corrupted release asset or ProGuard/R8 obfuscation stripping required reflection models.

## 5. Safe Diagnostic Steps
1. Isolate the affected client versions vs previous stable version (e.g. `v1.0.1` vs `v1.0.0`).
2. Determine if the issue is client-only (UI crash) or server-induced (RPC exception).

## 6. Safe Mitigation
### A. Web Release Rollback
- Revert hosting deployment immediately (e.g. Vercel instant rollback to previous deployment SHA):
  ```bash
  # Vercel instant rollback:
  vercel rollback [DEPLOYMENT_ID]
  ```

### B. Mobile App Release Gate
- Update server-side client compatibility table to mark the bad release as unsupported or require update:
  ```sql
  UPDATE public.client_version_compatibility
  SET minimum_supported_version = '1.0.0',
      recommended_version = '1.0.0',
      latest_version = '1.0.0',
      force_update_message_en = 'Emergency rollback active. Please revert or use version 1.0.0.',
      updated_at = NOW()
  WHERE platform = 'android';
  ```
- Halt staged rollout in Google Play Console (Halt Rollout).

## 7. Rollback / Recovery
1. Re-publish previous known stable APK/AAB (`v1.0.0+1`) as hotfix increment if store rollout cannot be halted.
2. For backend regressions, apply forward-fix hotfix migration rather than destructive down-migration to preserve data integrity.

## 8. Verification
1. Verify older versions (`v1.0.0`) continue operating normally.
2. Verify web traffic routes to restored deployment.
3. Confirm crash rate declines back to baseline.

## 9. Escalation
- **Primary**: Release Manager & Mobile Lead.
- **Secondary**: Platform Tech Lead.
