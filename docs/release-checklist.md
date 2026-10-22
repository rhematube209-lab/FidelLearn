# Production Release Gate Checklist

## 1. Pre-Release Verification
- [ ] **Working Tree Clean**: No uncommitted files or dirty changes in Git repository.
- [ ] **Release Tag & Commit SHA**: Tag matches SemVer (e.g., `v1.0.0`) and points to verified release commit.
- [ ] **Environment Separation**: Build environment set explicitly to `production` (`--dart-define=APP_ENVIRONMENT=production`).
- [ ] **No Secret Leaks**: Verified zero server secrets (Supabase `service_role`, webhook secrets, private keys) present in client code or assets.

## 2. Automated Quality Gates
- [ ] **Flutter Unit & Widget Tests**: 100% pass rate (`flutter test`).
- [ ] **Static Code Analysis**: 0 errors, 0 warnings (`flutter analyze --no-pub`).
- [ ] **Code Formatting**: 100% compliant (`dart format --output=none --set-exit-if-changed lib test`).
- [ ] **Multi-Tenant Regression Suites**: All PostgreSQL suites pass:
  - [ ] P6 Multi-Tenancy (`tools/test_postgres_tenancy.js`)
  - [ ] P7 Teacher Portal (`tools/test_postgres_p7_teacher_portal.js`)
  - [ ] P8 School Leadership (`tools/test_postgres_p8_leadership.js`)
  - [ ] P9 Assignments & Interventions (`tools/test_postgres_p9_assignments.js`)
  - [ ] P10 Institutional Reporting (`tools/test_postgres_p10_reporting.js`)
  - [ ] P11 Licensing & Seats (`tools/test_postgres_p11_licensing.js`)
  - [ ] P12 Production Readiness (`tools/test_postgres_p12_production_readiness.js`)

## 3. Database Migration Safety
- [ ] **Additive & Idempotent**: Migrations use `IF NOT EXISTS` / transactional blocks.
- [ ] **Security Definer Hardening**: Privileged functions enforce `SET search_path = public, pg_temp;`.
- [ ] **Staging Dry Run**: Migration applied to staging database clone without errors.
- [ ] **Forward-Fix Rollback Prepared**: Forward-fix strategy prepared in case of deployment issues.

## 4. Release Build Artifacts
- [ ] **Android Production Bundle**: Built with release signing key (`flutter build appbundle --release`).
- [ ] **Web Production Bundle**: Compiled and validated (`flutter build web --release`).
- [ ] **Version Metadata Entry**: Recorded in `public.production_releases` with tag, SHA, and migration baseline.

## 5. Post-Deployment Smoke Verification
- [ ] **Health Endpoint Operational**: `SELECT public.system_health_status();` returns `operational`.
- [ ] **Canary Login Tested**: Student, Teacher, and School Admin can authenticate.
- [ ] **Tenant Isolation Verified**: Cross-school queries blocked.
- [ ] **Sync Ingestion Tested**: Test attempt sync commits cleanly without duplicates.
- [ ] **Rollback Plan Active**: Rapid rollback runbook reviewed and accessible to release commander.
