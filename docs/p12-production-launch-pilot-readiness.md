# Priority 12: Production Launch & Pilot Readiness Specification

## 1. Overview & Vision
Priority 12 (P12) operationalizes the complete FidelLearn institutional learning platform. It transitions the platform from feature-complete development (P0–P11 frozen baselines) into an operationally resilient, observable, recoverable, and maintainable production system ready for deployment in real Ethiopian secondary schools.

---

## 2. Environment Architecture & Isolation
FidelLearn maintains three distinct environments:
1. **Local / Development**:
   - Uses local Drift SQLite mock database and local seeds.
   - Zero external cloud dependencies required for complete offline student MVP journeys.
2. **Staging**:
   - Isolated Supabase project instance with pre-production data fixtures.
   - Used for pre-release validation, migration dry runs, and integration testing.
3. **Production**:
   - Multi-tenant cloud PostgreSQL database with strict Supabase Row Level Security (RLS).
   - Dedicated connection pooling, automated backups, and CDN edge endpoints.
   - Never shares mutable state with staging or development environments.

---

## 3. Secret Management & Client-Safe Principles
- **Public Client Boundary**: Flutter client binaries contain only client-safe identifiers: Supabase URL and anon key (`EnvConfig.supabaseAnonKey`).
- **Zero Privileged Secrets**: Privileged secrets (e.g., Supabase `service_role` key, payment webhook secrets, Android keystore passwords) are strictly managed via CI/CD secrets and cloud environment variables.
- **Automated PII Redaction**: The structured logging system (`AppLogger`) and error telemetry buffer (`ErrorTelemetry`) automatically scrub authorization headers, access tokens, passwords, credit card numbers, and raw student payload data.

---

## 4. Observability & Health Architecture
1. **Health & Readiness Endpoints**:
   - **Liveness**: Evaluates whether the application process and local SQLite database engine are responsive.
   - **Readiness**: Evaluates whether network connectivity and Supabase backend are reachable and healthy.
   - **Database RPC**: `public.system_health_status()` returns operational status, schema version baseline, and active license telemetry to authenticated operators.
2. **Correlation Tracking**:
   - Critical operations (bulk imports, exam submissions, sync batches, report runs) generate UUID correlation IDs, enabling cross-tier request tracing.
3. **Structured Logging**:
   - `AppLogger` formats operational logs as JSON with severity level, timestamp, operation name, correlation ID, and safe metadata.

---

## 5. Error Taxonomy & User Experience
Client and server errors map into standardized domain categories:
- `network`: Transient connection drop (Retryable).
- `authentication`: Session expired or invalid credentials.
- `authorization`: Cross-school or insufficient role privilege.
- `seatLimit`: Institutional capacity exceeded (Non-retryable).
- `license`: Suspended or expired school license.
- `sync`: Synchronization failure (Retryable via bounded exponential backoff).
- `content`: Missing or corrupt subject package.
- `server`: Remote 5xx or unhandled backend error.

**User Experience Guard**: Raw system exceptions (`PostgrestException`, `SocketException`, null assertion errors) are never displayed directly to students or teachers. Friendly, actionable copy is displayed in English and Amharic with appropriate retry buttons.

---

## 6. Backup, Restore & Disaster Recovery (DR)
- **RPO Target**: <= 1 Hour (Continuous WAL archiving with hourly snapshot backups).
- **RTO Target**: <= 4 Hours (Target restoration of database and smoke verification).
- **Database Backup**: Automated daily base snapshots and continuous WAL stream managed via PostgreSQL/Supabase.
- **Storage Backup**: Curriculum packages (`.flpkg`) are immutable, versioned source artifacts replicated in cold object storage.
- **Restore Verification**: Validated via automated restore drills (`docs/runbooks/backup-restore.md`). Restored instances must pass all P6 multi-tenant RLS checks before traffic routing.

---

## 7. Release Engineering & Rollback Strategy
1. **Deterministic Quality Pipeline**:
   - `flutter test` (Unit and widget tests pass 100%).
   - `flutter analyze --no-pub` (0 errors, 0 warnings).
   - `dart format --output=none --set-exit-if-changed` (Clean code formatting).
   - PostgreSQL Regression Suites: P6 through P12 test suites executed against real PostgreSQL engine.
2. **Rollback Procedures**:
   - **Web Deployments**: Instant rollback via edge hosting console (e.g., Vercel deployment rollback).
   - **Mobile Clients**: Backend version compatibility gating (`public.client_version_compatibility`) allows enforcing or recommending client updates.
   - **Database Migrations**: Additive, non-destructive forward migrations preferred; forward-fix hotfixes prepared in advance.

---

## 8. Client / Backend Compatibility Policy
- Mobile applications may operate offline for months.
- Database schema and server RPCs remain backward compatible with supported client versions.
- Server maintains minimum supported versions per platform (`check_client_compatibility`).
- Students using older versions offline are never blocked from local studying; force-updates apply only to online synchronization when critical schema breaking changes occur.

---

## 9. Offline & Synchronization Reliability
1. **Durability**: Offline attempt submissions and mistake notebooks are recorded transactionally in local Drift SQLite (`DbSyncQueue`).
2. **Exponential Backoff**: Transient network drops trigger bounded exponential backoff with random jitter to prevent battery drain and server thundering herds.
3. **Idempotency**: All sync mutations carry unique idempotency keys. Network drops during submission retry safely without creating duplicate database records.
4. **Poison-Pill Isolation**: Malformed queue items failing repeatedly (up to 10 attempts) are marked as `dead_letter`, preventing queue stalling and allowing subsequent items to proceed.
5. **Session & Tenant Boundaries**: User sign-out securely resets sync context, preventing User A's queued mutations from uploading under User B's session.

---

## 10. Content Package Reliability
- Packages (`.flpkg`) are downloaded to a temporary location (`.flpkg.tmp`).
- SHA-256 integrity hash is verified against the signed database manifest prior to installation.
- Upon successful verification, the package is atomically renamed to its active path (`AtomicPackageInstaller`).
- In case of hash mismatch or corruption, the download is discarded and the previous valid version remains in use.

---

## 11. Operational Support Tooling
- Authorized platform admins and support engineers can inspect school operational health via audited RPC `get_school_operational_summary(school_id)`.
- Student sync diagnostics can be inspected via `get_student_sync_diagnostic(student_id)`.
- Support tooling strictly enforces tenant isolation: support queries automatically write audit records to `public.audit_log` with actor ID and timestamp. Direct manual database repair is avoided.

---

## 12. Pilot School Readiness
- Step-by-step validation checklist established in `docs/pilot-school-checklist.md`.
- Exercises end-to-end commercial onboarding: license provisioning, classroom creation, teacher subject assignments (with Natural/Social Math segregation), bulk student roster import, and seat limit enforcement.
- Verified on representative low/mid-range Android hardware under intermittent connectivity.
