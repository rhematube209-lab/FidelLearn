-- =============================================================================
-- FidelLearn Production Hardening Migration
-- Version: 20260924000000
-- Description:
--   1. Fix privilege-escalation vulnerability in handle_new_user trigger
--   2. Add content_packages table (queried by SupabaseContentRepository)
--   3. Add reward_rules table (server-controlled reward amounts)
--   4. Add redemption_catalog table (server-controlled redemption costs)
--   5. Add audit_log table
--   6. Add server-side coin RPC functions (SECURITY DEFINER, restricted EXECUTE)
--   7. Add grant_role_internal function
--   8. Harden RLS: block direct coin_ledger INSERT, block direct user_roles INSERT
--   9. Add admin write policies for content tables
--  10. Add UPDATE policy on attempt_responses (sync upsert support)
--  11. Add missing performance indexes
-- =============================================================================

-- =============================================================================
-- 1. FIX PRIVILEGE ESCALATION: handle_new_user trigger
--    BEFORE: assigned role from raw_user_meta_data (client-controlled)
--    AFTER:  always assigns 'student'; ignores any client-supplied role claim
-- =============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Populate profile from registration metadata (display info only — not role)
  INSERT INTO public.profiles (
    id,
    phone_number,
    display_name,
    grade,
    stream,
    preferred_language
  ) VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'phone_number', NEW.phone, NEW.email, 'student_' || SUBSTRING(NEW.id::TEXT, 1, 8)),
    COALESCE(NEW.raw_user_meta_data->>'display_name', 'Student'),
    COALESCE((NEW.raw_user_meta_data->>'grade')::INT, 12),
    COALESCE(NEW.raw_user_meta_data->>'stream', 'natural'),
    COALESCE(NEW.raw_user_meta_data->>'preferred_language', 'en')
  )
  ON CONFLICT (id) DO UPDATE SET
    display_name       = COALESCE(EXCLUDED.display_name, public.profiles.display_name),
    grade              = COALESCE(EXCLUDED.grade, public.profiles.grade),
    stream             = COALESCE(EXCLUDED.stream, public.profiles.stream),
    preferred_language = COALESCE(EXCLUDED.preferred_language, public.profiles.preferred_language);

  -- SECURITY: Always assign 'student' regardless of any client-supplied role.
  -- Role upgrades require a privileged Edge Function call by a platform_admin.
  INSERT INTO public.user_roles (user_id, role_id)
  VALUES (NEW.id, 'student')
  ON CONFLICT (user_id, role_id) DO NOTHING;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = public, pg_temp;

-- Recreate trigger (function replace above keeps the trigger, but be explicit)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =============================================================================
-- 2. CONTENT PACKAGES TABLE
--    Required by SupabaseContentRepository.getPackages()
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.content_packages (
    id TEXT PRIMARY KEY,
    name_en TEXT NOT NULL,
    name_am TEXT NOT NULL,
    grade INT NOT NULL CHECK (grade IN (6, 7, 8, 9, 10, 11, 12)),
    stream TEXT NOT NULL CHECK (stream IN ('natural', 'social', 'common')),
    subject_id TEXT REFERENCES public.subjects(id) ON DELETE SET NULL,
    version INT NOT NULL DEFAULT 1,
    file_size_bytes BIGINT,
    question_count INT NOT NULL DEFAULT 0,
    is_published BOOLEAN NOT NULL DEFAULT FALSE,
    download_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

ALTER TABLE public.content_packages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "content_packages_read_published"
    ON public.content_packages FOR SELECT
    USING (is_published = TRUE);

CREATE POLICY "content_packages_admin_all"
    ON public.content_packages FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.user_roles ur
            WHERE ur.user_id = auth.uid() AND ur.role_id = 'platform_admin'
        )
    );

-- =============================================================================
-- 3. REWARD RULES TABLE (server-controlled — client cannot set amounts)
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.reward_rules (
    event_type TEXT PRIMARY KEY,
    reward_amount INT NOT NULL CHECK (reward_amount > 0),
    source_table TEXT NOT NULL,
    description_en TEXT,
    description_am TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

-- Seed initial reward rules (amounts controlled only by platform admins)
INSERT INTO public.reward_rules (event_type, reward_amount, source_table, description_en)
VALUES
    ('exam_completed',      10, 'attempts',   'Coins awarded for completing any exam'),
    ('daily_streak',         5, 'profiles',   'Coins awarded for daily study streak'),
    ('challenge_completed', 20, 'challenges', 'Coins awarded for completing a challenge'),
    ('signup_bonus',        50, 'profiles',   'One-time welcome bonus for new students'),
    ('mistake_mastered',     3, 'mistake_records', 'Coins awarded when a mistake question is mastered')
ON CONFLICT (event_type) DO NOTHING;

ALTER TABLE public.reward_rules ENABLE ROW LEVEL SECURITY;

-- All authenticated users may read rules (for local display only — server enforces)
CREATE POLICY "reward_rules_read_authenticated"
    ON public.reward_rules FOR SELECT
    USING (auth.role() = 'authenticated');

-- Only platform_admin may modify rules (must go through SECURITY DEFINER in practice)
CREATE POLICY "reward_rules_admin_write"
    ON public.reward_rules FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.user_roles ur
            WHERE ur.user_id = auth.uid() AND ur.role_id = 'platform_admin'
        )
    );

-- =============================================================================
-- 4. REDEMPTION CATALOG TABLE (server-controlled — client cannot set costs)
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.redemption_catalog (
    item_id TEXT PRIMARY KEY,
    name_en TEXT NOT NULL,
    name_am TEXT NOT NULL,
    cost INT NOT NULL CHECK (cost > 0),
    item_type TEXT NOT NULL CHECK (item_type IN ('exam_unlock', 'hint', 'cosmetic', 'airtime')),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    metadata JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

ALTER TABLE public.redemption_catalog ENABLE ROW LEVEL SECURITY;

CREATE POLICY "redemption_catalog_read_authenticated"
    ON public.redemption_catalog FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "redemption_catalog_admin_write"
    ON public.redemption_catalog FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.user_roles ur
            WHERE ur.user_id = auth.uid() AND ur.role_id = 'platform_admin'
        )
    );

-- =============================================================================
-- 5. AUDIT LOG TABLE
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    actor_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE SET NULL,
    action TEXT NOT NULL,       -- e.g. 'grant_role', 'revoke_role', 'publish_question'
    target_table TEXT,
    target_id TEXT,
    metadata JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

CREATE INDEX IF NOT EXISTS idx_audit_log_actor ON public.audit_log(actor_id, created_at DESC);

ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;

-- Only platform admins may read the audit log
CREATE POLICY "audit_log_admin_read"
    ON public.audit_log FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.user_roles ur
            WHERE ur.user_id = auth.uid() AND ur.role_id = 'platform_admin'
        )
    );

-- No direct inserts — audit log rows are created only by SECURITY DEFINER functions
CREATE POLICY "audit_log_no_direct_insert"
    ON public.audit_log FOR INSERT
    WITH CHECK (FALSE);

-- =============================================================================
-- 6. SERVER-SIDE COIN FUNCTIONS (SECURITY DEFINER, restricted EXECUTE)
--
--    These functions are called ONLY by Edge Functions using the service key.
--    They must never be directly callable by 'anon' or 'authenticated' clients.
-- =============================================================================

-- Helper: verify an event belongs to the user and exists
-- Returns the attempt row for validation inside a transaction
CREATE OR REPLACE FUNCTION public._verify_attempt_ownership(
    p_attempt_id UUID,
    p_user_id    UUID
) RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.attempts
        WHERE id = p_attempt_id AND user_id = p_user_id AND is_completed = TRUE
    );
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = public, pg_temp;

-- 6a. claim_reward_internal
-- Called by the claim-reward Edge Function.
-- Server determines amount from reward_rules — client-supplied amounts are ignored.
CREATE OR REPLACE FUNCTION public.claim_reward_internal(
    p_user_id         UUID,
    p_event_type      TEXT,
    p_source_id       TEXT,   -- Opaque ID referencing the source entity
    p_idempotency_key TEXT,
    p_ledger_id       UUID    -- Pre-generated by Edge Function for the new row
) RETURNS public.coin_ledger AS $$
DECLARE
    v_rule           public.reward_rules%ROWTYPE;
    v_existing       public.coin_ledger%ROWTYPE;
    v_new_entry      public.coin_ledger%ROWTYPE;
BEGIN
    -- 1. Load server-controlled rule (determines amount — not the client)
    SELECT * INTO v_rule FROM public.reward_rules
    WHERE event_type = p_event_type AND is_active = TRUE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Unknown or inactive event_type: %', p_event_type
            USING ERRCODE = 'invalid_parameter_value';
    END IF;

    -- 2. Verify source entity ownership for applicable event types
    IF p_event_type = 'exam_completed' THEN
        IF NOT public._verify_attempt_ownership(p_source_id::UUID, p_user_id) THEN
            RAISE EXCEPTION 'Attempt % does not exist or does not belong to user %',
                p_source_id, p_user_id
                USING ERRCODE = 'insufficient_privilege';
        END IF;
    END IF;
    -- Additional event type ownership checks can be added here for
    -- daily_streak, challenge_completed, etc.

    -- 3. Check idempotency (prevent double-claiming the same event)
    SELECT * INTO v_existing FROM public.coin_ledger
    WHERE idempotency_key = p_idempotency_key;

    IF FOUND THEN
        -- Return the existing entry (idempotent response — not an error)
        RETURN v_existing;
    END IF;

    -- 4. Insert ledger entry with server-determined amount
    INSERT INTO public.coin_ledger (
        id,
        user_id,
        transaction_type,
        amount,
        reason,
        related_entity_id,
        idempotency_key,
        server_verified
    ) VALUES (
        p_ledger_id,
        p_user_id,
        'CREDIT',
        v_rule.reward_amount,            -- Server-controlled amount
        v_rule.description_en,
        p_source_id,
        p_idempotency_key,
        TRUE
    )
    RETURNING * INTO v_new_entry;

    RETURN v_new_entry;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = public, pg_temp;

-- 6b. redeem_coins_atomic
-- Called by the redeem-coins Edge Function.
-- Performs balance check and DEBIT atomically using advisory lock to prevent races.
CREATE OR REPLACE FUNCTION public.redeem_coins_atomic(
    p_user_id         UUID,
    p_item_id         TEXT,
    p_idempotency_key TEXT,
    p_ledger_id       UUID
) RETURNS public.coin_ledger AS $$
DECLARE
    v_item         public.redemption_catalog%ROWTYPE;
    v_existing     public.coin_ledger%ROWTYPE;
    v_balance      BIGINT;
    v_new_entry    public.coin_ledger%ROWTYPE;
BEGIN
    -- 1. Load server-controlled catalog item (determines cost)
    SELECT * INTO v_item FROM public.redemption_catalog
    WHERE item_id = p_item_id AND is_active = TRUE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Unknown or inactive redemption item: %', p_item_id
            USING ERRCODE = 'invalid_parameter_value';
    END IF;

    -- 2. Check idempotency
    SELECT * INTO v_existing FROM public.coin_ledger
    WHERE idempotency_key = p_idempotency_key;

    IF FOUND THEN
        RETURN v_existing;
    END IF;

    -- 3. Acquire advisory lock keyed by user_id to prevent concurrent redemptions
    --    This prevents two simultaneous redemptions from both seeing sufficient balance.
    PERFORM pg_advisory_xact_lock(hashtext(p_user_id::TEXT));

    -- 4. Calculate current balance inside the lock
    SELECT COALESCE(
        SUM(CASE WHEN transaction_type = 'CREDIT' THEN amount ELSE -amount END),
        0
    ) INTO v_balance
    FROM public.coin_ledger
    WHERE user_id = p_user_id;

    -- 5. Validate sufficient balance
    IF v_balance < v_item.cost THEN
        RAISE EXCEPTION 'Insufficient balance: have %, need %', v_balance, v_item.cost
            USING ERRCODE = 'check_violation';
    END IF;

    -- 6. Atomically insert DEBIT record
    INSERT INTO public.coin_ledger (
        id,
        user_id,
        transaction_type,
        amount,
        reason,
        related_entity_id,
        idempotency_key,
        server_verified
    ) VALUES (
        p_ledger_id,
        p_user_id,
        'DEBIT',
        v_item.cost,             -- Server-controlled cost
        'Redeemed: ' || v_item.name_en,
        p_item_id,
        p_idempotency_key,
        TRUE
    )
    RETURNING * INTO v_new_entry;

    RETURN v_new_entry;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = public, pg_temp;

-- =============================================================================
-- 7. ROLE GRANT FUNCTION (SECURITY DEFINER, restricted EXECUTE)
-- =============================================================================

CREATE OR REPLACE FUNCTION public.grant_role_internal(
    p_actor_id   UUID,
    p_target_id  UUID,
    p_role_id    TEXT
) RETURNS VOID AS $$
BEGIN
    -- 1. Validate role exists
    IF NOT EXISTS (SELECT 1 FROM public.roles WHERE id = p_role_id) THEN
        RAISE EXCEPTION 'Unknown role: %', p_role_id
            USING ERRCODE = 'invalid_parameter_value';
    END IF;

    -- 2. Verify actor is a platform_admin (re-verified server-side, never trust client)
    IF NOT EXISTS (
        SELECT 1 FROM public.user_roles
        WHERE user_id = p_actor_id AND role_id = 'platform_admin'
    ) THEN
        RAISE EXCEPTION 'Actor % does not have platform_admin role', p_actor_id
            USING ERRCODE = 'insufficient_privilege';
    END IF;

    -- 3. Grant the role
    INSERT INTO public.user_roles (user_id, role_id, granted_by)
    VALUES (p_target_id, p_role_id, p_actor_id)
    ON CONFLICT (user_id, role_id) DO NOTHING;

    -- 4. Write audit log
    INSERT INTO public.audit_log (actor_id, action, target_table, target_id, metadata)
    VALUES (
        p_actor_id,
        'grant_role',
        'user_roles',
        p_target_id::TEXT,
        jsonb_build_object('role_id', p_role_id)
    );
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = public, pg_temp;

-- =============================================================================
-- 8. RESTRICT EXECUTE PERMISSIONS ON INTERNAL FUNCTIONS
--    These functions must not be directly callable by anon or authenticated roles.
--    They are invoked exclusively by Edge Functions via the service key.
-- =============================================================================

REVOKE EXECUTE ON FUNCTION public.claim_reward_internal(UUID, TEXT, TEXT, TEXT, UUID)   FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.redeem_coins_atomic(UUID, TEXT, TEXT, UUID)           FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.grant_role_internal(UUID, UUID, TEXT)                 FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public._verify_attempt_ownership(UUID, UUID)                 FROM PUBLIC;

-- Grant to the role used by Supabase Edge Function runtime (service_role bypasses this
-- via superuser privileges, but explicit grants are best practice for least-privilege)
-- Note: 'supabase_functions_admin' exists in Supabase-managed projects.
-- These grants are no-ops if the role doesn't exist (local dev), which is safe.
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'supabase_functions_admin') THEN
        EXECUTE 'GRANT EXECUTE ON FUNCTION public.claim_reward_internal(UUID, TEXT, TEXT, TEXT, UUID) TO supabase_functions_admin';
        EXECUTE 'GRANT EXECUTE ON FUNCTION public.redeem_coins_atomic(UUID, TEXT, TEXT, UUID) TO supabase_functions_admin';
        EXECUTE 'GRANT EXECUTE ON FUNCTION public.grant_role_internal(UUID, UUID, TEXT) TO supabase_functions_admin';
    END IF;
END;
$$;

-- =============================================================================
-- 9. HARDEN COIN LEDGER RLS
--    Block all direct client INSERT operations.
--    Only SECURITY DEFINER functions (called via Edge Functions) may insert rows.
-- =============================================================================

-- Remove any existing INSERT policies on coin_ledger that allow direct client inserts
DROP POLICY IF EXISTS "Users insert own coin ledger" ON public.coin_ledger;

-- Explicit deny for direct INSERT (SECURITY DEFINER functions bypass RLS)
DROP POLICY IF EXISTS "coin_ledger_no_direct_insert" ON public.coin_ledger;
CREATE POLICY "coin_ledger_no_direct_insert"
    ON public.coin_ledger FOR INSERT
    WITH CHECK (FALSE);

-- =============================================================================
-- 10. HARDEN USER_ROLES RLS
--     Block all direct client INSERT/UPDATE/DELETE.
--     Roles are assigned only by handle_new_user trigger (always student)
--     or grant_role_internal SECURITY DEFINER function.
-- =============================================================================

DROP POLICY IF EXISTS "user_roles_no_direct_insert" ON public.user_roles;
CREATE POLICY "user_roles_no_direct_insert"
    ON public.user_roles FOR INSERT
    WITH CHECK (FALSE);

DROP POLICY IF EXISTS "user_roles_no_direct_update" ON public.user_roles;
CREATE POLICY "user_roles_no_direct_update"
    ON public.user_roles FOR UPDATE
    USING (FALSE);

DROP POLICY IF EXISTS "user_roles_no_direct_delete" ON public.user_roles;
CREATE POLICY "user_roles_no_direct_delete"
    ON public.user_roles FOR DELETE
    USING (FALSE);

-- Users may read their own roles
DROP POLICY IF EXISTS "user_roles_read_own" ON public.user_roles;
CREATE POLICY "user_roles_read_own"
    ON public.user_roles FOR SELECT
    USING (auth.uid() = user_id);

-- Platform admins may read all roles (for admin dashboard)
DROP POLICY IF EXISTS "user_roles_admin_read_all" ON public.user_roles;
CREATE POLICY "user_roles_admin_read_all"
    ON public.user_roles FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.user_roles ur
            WHERE ur.user_id = auth.uid() AND ur.role_id = 'platform_admin'
        )
    );

-- =============================================================================
-- 11. ADMIN WRITE POLICIES FOR CONTENT TABLES
-- =============================================================================

-- Questions: platform_admin can create/update (never delete — use archived status)
DROP POLICY IF EXISTS "questions_admin_write" ON public.questions;
CREATE POLICY "questions_admin_write"
    ON public.questions FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.user_roles ur
            WHERE ur.user_id = auth.uid() AND ur.role_id = 'platform_admin'
        )
    );

-- Answer choices: platform_admin write
DROP POLICY IF EXISTS "answer_choices_admin_write" ON public.answer_choices;
CREATE POLICY "answer_choices_admin_write"
    ON public.answer_choices FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.user_roles ur
            WHERE ur.user_id = auth.uid() AND ur.role_id = 'platform_admin'
        )
    );

-- Explanations: platform_admin write
DROP POLICY IF EXISTS "explanations_admin_write" ON public.explanations;
CREATE POLICY "explanations_admin_write"
    ON public.explanations FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.user_roles ur
            WHERE ur.user_id = auth.uid() AND ur.role_id = 'platform_admin'
        )
    );

-- Subjects, units, topics: platform_admin write
DROP POLICY IF EXISTS "subjects_admin_write" ON public.subjects;
CREATE POLICY "subjects_admin_write"
    ON public.subjects FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.user_roles ur
            WHERE ur.user_id = auth.uid() AND ur.role_id = 'platform_admin'
        )
    );

DROP POLICY IF EXISTS "units_admin_write" ON public.units;
CREATE POLICY "units_admin_write"
    ON public.units FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.user_roles ur
            WHERE ur.user_id = auth.uid() AND ur.role_id = 'platform_admin'
        )
    );

DROP POLICY IF EXISTS "topics_admin_write" ON public.topics;
CREATE POLICY "topics_admin_write"
    ON public.topics FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.user_roles ur
            WHERE ur.user_id = auth.uid() AND ur.role_id = 'platform_admin'
        )
    );

-- =============================================================================
-- 12. ADD UPDATE POLICY ON attempt_responses
--     Required by sync upsert operations (retry idempotency)
-- =============================================================================

DROP POLICY IF EXISTS "Users update own attempt responses" ON public.attempt_responses;
CREATE POLICY "Users update own attempt responses"
    ON public.attempt_responses FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.attempts a
            WHERE a.id = attempt_responses.attempt_id AND a.user_id = auth.uid()
        )
    );

-- =============================================================================
-- 13. MISSING PERFORMANCE INDEXES
-- =============================================================================

-- Coin ledger idempotency check (very hot path for sync)
CREATE INDEX IF NOT EXISTS idx_coin_ledger_idempotency_key
    ON public.coin_ledger(idempotency_key);

-- Bookmark unique lookup (user + question)
CREATE INDEX IF NOT EXISTS idx_bookmarks_user_question
    ON public.bookmarks(user_id, question_id);

-- Mistake record unique lookup
CREATE INDEX IF NOT EXISTS idx_mistake_records_user_question
    ON public.mistake_records(user_id, question_id);

-- Attempt history (most common query: user's completed attempts ordered by time)
CREATE INDEX IF NOT EXISTS idx_attempts_user_completed_at
    ON public.attempts(user_id, is_completed, start_time DESC);

-- Audit log: time-ordered admin queries
CREATE INDEX IF NOT EXISTS idx_audit_log_created_at
    ON public.audit_log(created_at DESC);

-- Content packages: browse by grade + stream
CREATE INDEX IF NOT EXISTS idx_content_packages_grade_stream
    ON public.content_packages(grade, stream, is_published);
