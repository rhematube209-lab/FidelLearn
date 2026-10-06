# FidelLearn P11: Institutional Commercial Access, Seat Accounting, Billing Abstraction & School Onboarding Architecture

## 1. Executive Summary & Core Principle

FidelLearn's institutional commercial architecture (P11) establishes a robust, tenant-isolated foundation that transitions schools from **prospective institutions** to **licensed, staffed, student-enrolled, seat-controlled, and fully operational learning environments**.

### The Tripartite Architectural Separation
Crucially, P11 enforces a strict boundary between three distinct concerns:

```text
1. Billing Layer
   Question: "Was money paid or contract signed?"
   Tables: billing_customers, billing_subscriptions, billing_events
   
2. Licensing / Entitlements Layer
   Question: "What is this school allowed to access and how many students may enroll?"
   Tables: school_licenses, institutional_plans, school_license_events
   
3. Membership / Authorization Layer
   Question: "What is this specific user allowed to do inside this school?"
   Tables: school_memberships, classroom_memberships, teacher_subject_assignments
```

> **Cardinal Architectural Invariant**:
> **Billing does not directly equal authorization.**
> An incoming payment webhook or manual contract invoice updates the licensing record via trusted business logic. User requests never evaluate external payment APIs or raw billing records directly; they consume server-authoritative entitlements and tenant memberships.

---

## 2. Institutional Licensing & Entitlements Model (P11A)

### 2.1 Canonical `school_licenses` Entity
```sql
CREATE TABLE public.school_licenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID NOT NULL REFERENCES public.schools(id) ON DELETE CASCADE,
    plan_code TEXT NOT NULL REFERENCES public.institutional_plans(plan_code),
    status TEXT NOT NULL CHECK (status IN ('trial', 'active', 'grace', 'suspended', 'expired', 'cancelled')),
    starts_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ,
    grace_ends_at TIMESTAMPTZ,
    student_seat_limit INT NOT NULL CHECK (student_seat_limit >= 0),
    feature_entitlements JSONB NOT NULL DEFAULT '{}'::jsonb,
    billing_customer_ref TEXT,
    billing_subscription_ref TEXT,
    source TEXT NOT NULL CHECK (source IN ('manual_contract', 'bank_transfer', 'telebirr', 'chapa', 'stripe', 'system')),
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT uq_school_licenses_school_id UNIQUE (school_id)
);
```

### 2.2 License Lifecycle States
| Status | Meaning | Operational Access | Expiration Behavior |
| :--- | :--- | :--- | :--- |
| `trial` | Evaluation period before contract finalization | Fully enabled up to trial seat cap | Hard cutoff at `ends_at` unless extended |
| `active` | Fully paid or verified manual contract in effect | Fully enabled up to contract seat limit | Normal operations |
| `grace` | Payment or renewal issue detected; temporary access granted | Enabled until `grace_ends_at` with warning banners | Transitions to `suspended` if unresolved |
| `suspended` | Commercial access blocked due to non-payment or breach | Institutional cloud mutations blocked; student data preserved | Can be reactivated without data loss |
| `expired` | Contract period terminated normally | Institutional operations restricted | Historical data remains read-only |
| `cancelled` | Institution voluntarily or contractually exited | Access terminated; historical audits preserved | Permanent archival |

### 2.3 Feature Entitlements
Entitlements are granular, server-evaluated feature flags stored in `feature_entitlements`:
- `student_learning`: Access to student national exam preparation, questions, and mock exams.
- `teacher_portal`: P7 Teacher dashboard, class rosters, and subject topic insights.
- `leadership_dashboard`: P8 School administration metrics and teacher management.
- `assignments_interventions`: P9 Homework, remedial drills, and teacher interventions.
- `institutional_reporting`: P10 School executive, subject performance, and teacher coverage reports.
- `national_exam_simulation`: P5 Full timed ESSLCE mock exams and national rankings.

Plans (`trial`, `school_standard`, `custom_contract`) define default entitlements, but authorization code strictly checks `school_has_entitlement(school_id, entitlement)` rather than hardcoded plan names.

---

## 3. Student Seat Management & Accounting (P11B)

### 3.1 Commercial Unit: Distinct Active Students
- **Primary Metric**: The license regulates the number of distinct active student users within an institution.
- **Multi-Classroom Deduplication**: A student enrolled in multiple classrooms (e.g. Grade 12 Section A and an Advanced Remedial Cohort) occupies **exactly 1 seat**.
- **Role Isolation**: Teachers and School Admins do not consume student seats.

### 3.2 Concurrency-Safe Seat Enforcement
When enrolling a student (individually, via CSV bulk import, or through invitation), the server executes an atomic capacity check with row-level locking:
```sql
SELECT student_seat_limit, status INTO v_seat_limit, v_license_status
FROM public.school_licenses
WHERE school_id = p_school_id
FOR UPDATE;

-- Derive currently occupied seats across all active classrooms in school
SELECT COUNT(DISTINCT cm.user_id) INTO v_occupied_seats
FROM public.classroom_memberships cm
JOIN public.classrooms c ON c.id = cm.classroom_id
WHERE c.school_id = p_school_id
  AND cm.role = 'student'
  AND cm.status = 'active';

IF (v_occupied_seats + v_new_unique_students) > v_seat_limit THEN
    RAISE EXCEPTION 'SEAT_LIMIT_EXCEEDED: School has % seats occupied out of % limit',
        v_occupied_seats, v_seat_limit;
END IF;
```

### 3.3 Deactivation, Transfers & Capacity Decreases
- **Seat Release**: When a student is transferred or marked `inactive`/`withdrawn`, their seat is immediately made available for other students.
- **Data Preservation**: Deactivating a student **never** deletes historical exam attempts, mistake records, assignment submissions, or report evidence.
- **Seat Limit Decreases**: If an institutional contract drops from 500 to 400 seats while 450 students are enrolled, FidelLearn flags the license as `is_over_capacity = true`. Existing students are **never deleted or deactivated silently**; new student enrollments are blocked until administrators reconcile rosters.

---

## 4. Progressive School Onboarding (P11C)

### 4.1 Onboarding Steps & Verification Matrix
To ensure schools are operational before launch, onboarding tracks 10 deterministic stages in `school_onboarding_state`:
1. **School Profile Created**: Base metadata, name, region, and contact info registered.
2. **License Configured**: Trial or active license with student seat cap established.
3. **Academic Year Configured**: Current Ethiopian calendar year (e.g. `2017 E.C.`) set.
4. **Classrooms & Sections Configured**: Sections created for Grade 12 Natural/Social Science.
5. **School Admin Assigned**: Active institutional administrator designated.
6. **Teachers Onboarded**: Teaching staff registered with active school memberships.
7. **Teacher-Subject Assignments**: Teachers assigned to classroom subject slots.
8. **Student Enrollments**: Students imported or enrolled into their respective classrooms.
9. **Curriculum Coverage Validated**: Required Grade 12 stream subjects verified.
10. **Activation Ready**: All integrity checks passed; school ready for operational launch.

### 4.2 Bulk Student Ingestion & Idempotency
Bulk student ingestion via CSV follows a two-phase transactional pipeline:
- **Phase 1: Validation & Preview**: CSV rows are validated against stream options, classroom IDs, and seat limits without modifying the database.
- **Phase 2: Atomic Ingestion**: Ingests up to hundreds of students in a single transaction. Repeated requests with the same `idempotency_key` return the existing run results without creating duplicate users or incrementing seat counts.

---

## 5. Subscription Lifecycle & Grace Period Policies (P11D)

### 5.1 Permitted Lifecycle State Machine
```text
           ┌──────────────┐
           │    trial     │
           └──────┬───────┘
                  │ (convert)
                  ▼
┌─────────────────────────────────────┐
│               active                │◄─────────┐
└───┬─────────────┬───────────────┬───┘          │ (reactivate / renew)
    │             │               │              │
    │ (fail)      │ (term end)    │ (terminate)  │
    ▼             ▼               ▼              │
┌───────┐     ┌─────────┐    ┌───────────┐       │
│ grace │     │ expired │    │ cancelled │       │
└───┬───┘     └────┬────┘    └───────────┘       │
    │              │                             │
    │ (unresolved) │                             │
    ▼              │                             │
┌───────────┐      │                             │
│ suspended │◄─────┴─────────────────────────────┘
└───────────┘
```

- **Grace Policy**: When an institutional payment fails or renewal is pending, a 14-day grace period is initiated (`status = 'grace'`, `grace_ends_at = now() + interval '14 days'`). School operations continue uninterrupted, with clear warning notices displayed on the administrative dashboard.
- **Suspension Policy**: If the grace period expires without resolution, the school transitions to `suspended`. Institutional reporting, new assignments, and staff mutations are blocked.
- **Preservation of Student Learning**: Suspended schools do not lock out students from local downloaded revision material, and no historical academic data is destroyed.
- **Reactivation**: Upon renewal or manual payment reconciliation, the license transitions back to `active` immediately, fully restoring institutional access without requiring tenant reconstruction.

---

## 6. Provider-Neutral Billing Abstraction (P11E)

### 6.1 Architecture Overview
The billing layer accommodates diverse African and international payment rails:
- **Domestic Ethiopian Rails**: Telebirr, Chapa, CBE Birr, direct commercial bank transfer / manual contract.
- **International Rails**: Stripe, credit card.

All external webhooks and payment events are normalized into `billing_events`:
```sql
CREATE TABLE public.billing_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider TEXT NOT NULL,
    provider_event_id TEXT NOT NULL,
    event_type TEXT NOT NULL,
    school_id UUID REFERENCES public.schools(id) ON DELETE SET NULL,
    payload_hash TEXT NOT NULL,
    raw_payload JSONB NOT NULL,
    processed_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    status TEXT NOT NULL CHECK (status IN ('received', 'processed', 'ignored', 'failed')),
    error_message TEXT,
    CONSTRAINT uq_billing_events_provider_event UNIQUE (provider, provider_event_id)
);
```

### 6.2 Webhook Idempotency & Replay Protection
- Every webhook must present a valid signature and unique `(provider, provider_event_id)`.
- If a webhook is redelivered, the database detects the existing record and returns `status = 'ignored'` without triggering redundant license transitions or duplicate audit entries.
- Out-of-order events are guarded by checking event timestamps against the current license period.

---

## 7. Commercial Administration & Security Model (P11F)

### 7.1 Separation of Privileges
| Capability | Platform Admin | School Admin | Teacher | Student |
| :--- | :---: | :---: | :---: | :---: |
| Create / configure school licenses | ✅ | ❌ | ❌ | ❌ |
| Adjust seat limits | ✅ | ❌ | ❌ | ❌ |
| Override feature entitlements | ✅ | ❌ | ❌ | ❌ |
| Trigger suspension / reactivation | ✅ | ❌ | ❌ | ❌ |
| View own school license & seat usage | ✅ | ✅ | ❌ | ❌ |
| View onboarding checklist | ✅ | ✅ | ❌ | ❌ |
| Execute student bulk import | ✅ | ✅ | ❌ | ❌ |
| Access cross-school license data | ✅ | ❌ | ❌ | ❌ |

### 7.2 Audit Trail Enforcement
All commercial and onboarding operations record immutable events in `public.audit_log`:
- `school_license_created`, `school_trial_started`, `school_license_activated`
- `school_license_suspended`, `school_license_reactivated`
- `school_seat_limit_changed`, `school_entitlements_changed`
- `school_onboarding_completed`, `school_bulk_import_completed`
- `billing_event_processed`

Audit metadata adheres strictly to privacy standards: no payment card credentials, student personal identity, or sensitive tokens are stored.

---

## 8. Offline & Local Storage Invariants
- **Cloud Authoritative**: Commercial licensing, seat limit enforcement, billing webhooks, and school activation are strictly cloud-authoritative operations. Offline clients cannot synthetically self-grant licenses or alter seat allocations.
- **Drift SQLite Invariance**: Drift SQLite schema remains at **v9**; no client-side commercial tables are introduced.
- **Local Learning Continuity**: Students with downloaded offline subject packages retain continuous access to practice questions and offline mock exams even if their school's institutional cloud license is suspended or in grace.
