# Runbook: License Suspension & Seat-Limit Incident

## 1. Severity
- **Classification**: SEV-2 (High)
- **Impact**: School teachers or leadership blocked from institutional portals, or new student enrollments blocked due to seat limits. Student device-local study continues unhindered.

## 2. Symptoms
- School admin or teachers see `LICENSE_SUSPENDED` or `SEAT_LIMIT_EXCEEDED` error banners.
- API calls to `school_has_entitlement` return `FALSE`.
- Bulk student import fails with error `SEAT_LIMIT_EXCEEDED (available: X, requested: Y)`.

## 3. How to Confirm
1. Query operational summary via support RPC:
   ```sql
   SELECT public.get_school_operational_summary('<school_uuid>');
   ```
2. Inspect license status, dates, and effective entitlement:
   ```sql
   SELECT sl.status, sl.starts_at, sl.ends_at, sl.grace_ends_at,
          public.is_school_license_effective('<school_uuid>') AS is_effective,
          public.get_school_seat_usage('<school_uuid>') AS seat_usage
   FROM public.school_licenses sl
   WHERE sl.school_id = '<school_uuid>';
   ```
3. Check audit log for recent billing or admin lifecycle modifications:
   ```sql
   SELECT * FROM public.audit_log
   WHERE target_id = '<school_uuid>'
   ORDER BY created_at DESC LIMIT 5;
   ```

## 4. Likely Causes
- Contract expiration reached without renewal recorded (transition to `grace` then `suspended`).
- Stale or out-of-order webhook event received (protected by billing watermark).
- School enrollment expanded beyond contracted seat capacity.
- Billing payment failure recorded via automated payment provider.

## 5. Safe Diagnostic Steps
1. Verify if license is in valid contract, trial, or grace period.
2. Confirm whether student count in active classrooms exceeds `student_seat_limit`.
3. Check if deactivation of transferred/inactive students frees occupied seats.

## 6. Safe Mitigation
### A. False Suspension (Administrative or Payment Delay)
- For pilot schools with valid manual contracts, grant a grace extension or manual contract renewal:
  ```sql
  -- Authenticated platform admin action only (audited):
  UPDATE public.school_licenses
  SET status = 'active',
      ends_at = NOW() + interval '30 days',
      updated_at = NOW()
  WHERE school_id = '<school_uuid>';
  ```

### B. Seat Limit Exceeded
- School admin can deactivate transferred students from active classrooms.
- Platform admin can increase the school's licensed seat capacity via commercial amendment.

## 7. Rollback / Recovery
- License state is strictly transactional. Restoring status to `active` immediately re-enables all entitled feature gates (`teacher_portal`, `leadership_dashboard`, `institutional_reporting`).

## 8. Verification
1. Run `SELECT public.is_school_license_effective('<school_uuid>');` and confirm `TRUE`.
2. Verify teacher and school leadership logins succeed without license error.
3. Confirm seat usage report reflects accurate occupied vs available seats.

## 9. Escalation
- **Primary**: School Operations & Account Manager.
- **Secondary**: Platform Support Lead.
