# Production Security Review & Hardening Audit

## 1. Executive Summary
This document provides a comprehensive security review for the FidelLearn platform entering Priority 12 (Production Launch & Pilot Readiness). The review covers PostgreSQL Row Level Security (RLS), `SECURITY DEFINER` posture, secret isolation, network resilience, tenant separation, and operational audit trails.

## 2. Row Level Security (RLS) Posture
- **Default Deny**: All public application tables have `ROW LEVEL SECURITY` enabled.
- **Tenant Scope**: Institutional tables (`schools`, `classrooms`, `school_memberships`, `classroom_memberships`, `school_licenses`, `assignments`, `student_interventions`, `report_runs`) enforce strict tenant ownership checks matching the authenticated user's active membership or platform admin role.
- **Audit Log Shielding**: Direct client inserts into `public.audit_log` are strictly blocked (`WITH CHECK (FALSE)`). Audited events can only be written by trusted `SECURITY DEFINER` stored procedures. Read access is restricted to verified `platform_admin` roles via the non-recursive function `public.is_platform_admin()`.

## 3. SECURITY DEFINER & Search Path Hardening
All privileged database functions executed in the system are configured with:
```sql
SECURITY DEFINER
SET search_path = public, pg_temp;
```
This guarantees protection against search-path hijacking attacks. Privileged functions execute with bounded authority and explicitly revoke public execution (`REVOKE ALL ON FUNCTION ... FROM PUBLIC, anon`).

## 4. Multi-Tenant Isolation
- **No Shared State**: Schools operate in logically isolated partitions governed by immutable school IDs.
- **Cross-School Denial**: Cross-school queries by teachers, students, or school admins are rejected at both the RLS policy layer and within stored procedures.
- **Administrative Oversight**: Operational support functions (`get_school_operational_summary`, `get_student_sync_diagnostic`) require authenticated caller authority, reject cross-school snooping, and automatically write tamper-evident audit records into `public.audit_log`.

## 5. Secret Management & Client-Safe Architecture
- **Zero Client Secrets**: The Flutter mobile/web client contains only public endpoints and anonymous Supabase public keys.
- **Service Role Key Shielding**: The Supabase `service_role` key is strictly confined to secure Edge Functions and backend CI/CD runners. It is never compiled into Flutter binaries, committed to version control, or exposed in network payloads.
- **Payload Redaction**: `AppLogger` and `ErrorTelemetry` implement automated data scrubbers that redact passwords, bearer tokens, credit card numbers, CVVs, and raw student payloads prior to disk writing or transmission.

## 6. Offline Data & Session Security
- **Local Storage Isolation**: Local Drift SQLite and secure token caches reside inside the sandboxed operating system app sandbox.
- **Session Expiry & Revocation**: Revoked or deactivated school memberships take effect on the very next network call to the Supabase backend. Cached offline UI cannot override server-authoritative entitlement decisions.
- **Account Switch Boundaries**: User sign-out securely purges session tokens and resets active user context. Device sync queues are tagged with unique user IDs, preventing data from User A from synchronizing under User B's account.

## 7. Storage Bucket Policies
- **Curriculum Packages**: Public read-only bucket for verified `.flpkg` files. Upload and modification privileges restricted to `platform_admin` and `service_role`.
- **Institutional Reports**: Private bucket with scoped signed URL generation. Cross-tenant path access is prohibited.
