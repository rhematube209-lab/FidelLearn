# FidelLearn Security, RBAC & Child Privacy

## 1. Supabase Row Level Security (RLS) Policies
All PostgreSQL tables enforce Row Level Security:

1. **`profiles`**:
   - `SELECT`: Users can view their own profile, plus teachers can view enrolled students in their classes.
   - `UPDATE`: Users can update only their own non-sensitive profile fields (`display_name`, `grade`, `stream`, `preferred_language`).
2. **`attempts` & `attempt_responses`**:
   - `SELECT`: `user_id = auth.uid()` OR `EXISTS (SELECT 1 FROM class_enrollments ce JOIN exam_assignments ea ON ce.class_id = ea.class_id WHERE ce.student_id = attempts.user_id AND ea.teacher_id = auth.uid())`
   - `INSERT`: `user_id = auth.uid()`
   - `UPDATE`/`DELETE`: Forbidden (immutable audit trail).
3. **`coin_ledger`**:
   - `SELECT`: `user_id = auth.uid()`
   - Direct `INSERT`/`UPDATE`/`DELETE` from clients is **FORBIDDEN**. Transactions must execute through server Edge Functions or PostgreSQL RPC security definer procedures (`process_coin_transaction`).
4. **`questions` & `explanations`**:
   - `SELECT`: Allowed for published & approved content, or teachers/admins.
   - `INSERT`/`UPDATE`/`DELETE`: Restricted to `platform_admin` and verified `content_reviewer` roles.

---

## 2. Role-Based Access Control (RBAC)
- Client-side route guards prevent unauthorized navigation in GoRouter.
- Backend RLS provides true zero-trust authorization.
- Supported roles:
  - `student`: Standard access to exam runner, analytics, bookmarks, rewards.
  - `teacher`: Access to assigned classes, question picker, exam assignments, class performance.
  - `school_admin`: Access to school-wide dashboards, teacher rosters, class comparisons.
  - `platform_admin`: Access to content CMS, user/school management, reward economics, audit logs.

---

## 3. Privacy-by-Design & Child Safety
- **Minimal Data Collection**: Only phone number (for OTP login) and student-selected display name are collected.
- **No Public PII Exposure**: Phone numbers and real names are never shown on leaderboards or public views.
- **No Social Chat Between Minors**: Direct messaging between students is explicitly omitted in MVP.
- **Zero Distracting Ads in Exams**: Rewarded video ad simulations occur only on explicit user request in the Rewards tab.
- **Local Credential Storage**: Flutter Secure Storage (AES encryption via Android KeyStore / Windows DPAPI / iOS Keychain).
- **Log Sanitization**: Passwords, tokens, and phone numbers are scrubbed from telemetry and error logs.
