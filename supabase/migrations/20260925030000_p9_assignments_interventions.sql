-- =============================================================================
-- FidelLearn — P9 Assignments + Intervention System Database Migration
-- Migration: 20260925030000
-- Description: Multi-tenant, teacher-controlled, offline-capable assignment
--              and academic intervention tables, atomic publication,
--              recipient snapshotting, RLS, audit logging, and RPC read models.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Table: public.learning_assignments
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.learning_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID NOT NULL REFERENCES public.schools(id) ON DELETE RESTRICT,
    classroom_id UUID NOT NULL REFERENCES public.classrooms(id) ON DELETE RESTRICT,
    teacher_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    subject_id TEXT NOT NULL,
    exam_variant TEXT NULL,
    title TEXT NOT NULL,
    instructions TEXT NULL,
    assignment_type TEXT NOT NULL CHECK (assignment_type IN ('targetedPractice', 'customQuestionSet', 'simulation')),
    status TEXT NOT NULL CHECK (status IN ('draft', 'published', 'closed', 'archived')) DEFAULT 'draft',
    due_at TIMESTAMPTZ NULL,
    allow_late_submission BOOLEAN NOT NULL DEFAULT true,
    time_limit_minutes INT NOT NULL DEFAULT 0,
    total_questions INT NOT NULL DEFAULT 0,
    content_hash TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    published_at TIMESTAMPTZ NULL,
    closed_at TIMESTAMPTZ NULL
);

CREATE INDEX IF NOT EXISTS idx_assignments_school_class_status 
    ON public.learning_assignments(school_id, classroom_id, status);
CREATE INDEX IF NOT EXISTS idx_assignments_teacher_status 
    ON public.learning_assignments(teacher_user_id, status);
CREATE INDEX IF NOT EXISTS idx_assignments_subject_variant 
    ON public.learning_assignments(subject_id, exam_variant);

-- -----------------------------------------------------------------------------
-- 2. Table: public.learning_assignment_questions
-- Immutable question snapshot frozen at publication.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.learning_assignment_questions (
    assignment_id UUID NOT NULL REFERENCES public.learning_assignments(id) ON DELETE CASCADE,
    question_id UUID NOT NULL REFERENCES public.questions(id) ON DELETE RESTRICT,
    position INT NOT NULL,
    question_content_version INT NOT NULL DEFAULT 1,
    package_version TEXT NOT NULL DEFAULT '1.0.0',
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    PRIMARY KEY (assignment_id, question_id),
    CONSTRAINT uq_assignment_question_position UNIQUE (assignment_id, position)
);

CREATE INDEX IF NOT EXISTS idx_assignment_questions_lookup 
    ON public.learning_assignment_questions(assignment_id, position);

-- -----------------------------------------------------------------------------
-- 3. Table: public.learning_assignment_recipients
-- Explicit student recipient snapshot resolved at publication.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.learning_assignment_recipients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assignment_id UUID NOT NULL REFERENCES public.learning_assignments(id) ON DELETE CASCADE,
    student_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    status TEXT NOT NULL CHECK (status IN ('assigned', 'inProgress', 'submitted', 'completed', 'late', 'excused')) DEFAULT 'assigned',
    attempt_id UUID NULL REFERENCES public.attempts(id) ON DELETE SET NULL,
    started_at TIMESTAMPTZ NULL,
    submitted_at TIMESTAMPTZ NULL,
    score INT NULL,
    percentage NUMERIC(5,2) NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    CONSTRAINT uq_assignment_student_recipient UNIQUE (assignment_id, student_user_id)
);

CREATE INDEX IF NOT EXISTS idx_assignment_recipients_student 
    ON public.learning_assignment_recipients(student_user_id, status);
CREATE INDEX IF NOT EXISTS idx_assignment_recipients_assignment_status 
    ON public.learning_assignment_recipients(assignment_id, status);

-- -----------------------------------------------------------------------------
-- 4. Table: public.student_interventions
-- Tracks formal academic intervention actions linked to attention signals or teacher observation.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.student_interventions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID NOT NULL REFERENCES public.schools(id) ON DELETE RESTRICT,
    classroom_id UUID NOT NULL REFERENCES public.classrooms(id) ON DELETE RESTRICT,
    subject_id TEXT NOT NULL,
    exam_variant TEXT NULL,
    student_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    teacher_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    source TEXT NOT NULL CHECK (source IN ('p7Attention', 'teacherObservation', 'assessmentReview', 'mistakeReview')),
    source_reason_codes JSONB NOT NULL DEFAULT '[]'::jsonb,
    severity_at_creation TEXT NULL CHECK (severity_at_creation IN ('high', 'medium', 'low')),
    action_type TEXT NOT NULL CHECK (action_type IN ('targetedPractice', 'reviewMistakes', 'simulation', 'teacherFollowUp')),
    linked_assignment_id UUID NULL REFERENCES public.learning_assignments(id) ON DELETE SET NULL,
    status TEXT NOT NULL CHECK (status IN ('open', 'active', 'completed', 'closed')) DEFAULT 'open',
    teacher_note TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    started_at TIMESTAMPTZ NULL,
    completed_at TIMESTAMPTZ NULL,
    closed_at TIMESTAMPTZ NULL
);

CREATE INDEX IF NOT EXISTS idx_interventions_school_class_status 
    ON public.student_interventions(school_id, classroom_id, status);
CREATE INDEX IF NOT EXISTS idx_interventions_student 
    ON public.student_interventions(student_user_id, status);
CREATE INDEX IF NOT EXISTS idx_interventions_teacher 
    ON public.student_interventions(teacher_user_id, status);
CREATE INDEX IF NOT EXISTS idx_interventions_linked_assignment 
    ON public.student_interventions(linked_assignment_id);

-- -----------------------------------------------------------------------------
-- 5. Row-Level Security (RLS) Configuration
-- -----------------------------------------------------------------------------
ALTER TABLE public.learning_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.learning_assignment_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.learning_assignment_recipients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_interventions ENABLE ROW LEVEL SECURITY;

-- Block direct mutations by untrusted client queries; enforce Security Definer RPCs
CREATE POLICY "assignments_no_direct_insert" ON public.learning_assignments FOR INSERT WITH CHECK (false);
CREATE POLICY "assignments_no_direct_update" ON public.learning_assignments FOR UPDATE USING (false);
CREATE POLICY "assignments_no_direct_delete" ON public.learning_assignments FOR DELETE USING (false);

CREATE POLICY "assignment_questions_no_direct_insert" ON public.learning_assignment_questions FOR INSERT WITH CHECK (false);
CREATE POLICY "assignment_questions_no_direct_update" ON public.learning_assignment_questions FOR UPDATE USING (false);
CREATE POLICY "assignment_questions_no_direct_delete" ON public.learning_assignment_questions FOR DELETE USING (false);

CREATE POLICY "assignment_recipients_no_direct_insert" ON public.learning_assignment_recipients FOR INSERT WITH CHECK (false);
CREATE POLICY "assignment_recipients_no_direct_update" ON public.learning_assignment_recipients FOR UPDATE USING (false);
CREATE POLICY "assignment_recipients_no_direct_delete" ON public.learning_assignment_recipients FOR DELETE USING (false);

CREATE POLICY "interventions_no_direct_insert" ON public.student_interventions FOR INSERT WITH CHECK (false);
CREATE POLICY "interventions_no_direct_update" ON public.student_interventions FOR UPDATE USING (false);
CREATE POLICY "interventions_no_direct_delete" ON public.student_interventions FOR DELETE USING (false);

-- Grant SELECT on P9 tables to authenticated role so RLS policies can take effect
GRANT SELECT ON public.learning_assignments, public.learning_assignment_questions, public.learning_assignment_recipients, public.student_interventions TO authenticated;

-- -----------------------------------------------------------------------------
-- RLS Non-Recursive Helper Functions
-- Executed with table owner privileges to break mutual policy recursion
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_assignment_recipient(
    p_assignment_id   UUID,
    p_student_user_id UUID
)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT EXISTS (
        SELECT 1 
        FROM public.learning_assignment_recipients
        WHERE assignment_id = p_assignment_id
          AND student_user_id = p_student_user_id
    );
$$;

CREATE OR REPLACE FUNCTION public.can_read_assignment_recipient_rows(
    p_assignment_id UUID,
    p_user_id       UUID
)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT EXISTS (
        SELECT 1 
        FROM public.learning_assignments a
        WHERE a.id = p_assignment_id
          AND (
              a.teacher_user_id = p_user_id
              OR EXISTS (
                  SELECT 1 FROM public.school_memberships sm
                  WHERE sm.user_id = p_user_id
                    AND sm.school_id = a.school_id
                    AND sm.role = 'school_admin'
                    AND sm.status = 'active'
              )
          )
    );
$$;

REVOKE ALL ON FUNCTION public.is_assignment_recipient(UUID, UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_assignment_recipient(UUID, UUID) TO authenticated;

REVOKE ALL ON FUNCTION public.can_read_assignment_recipient_rows(UUID, UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.can_read_assignment_recipient_rows(UUID, UUID) TO authenticated;

-- Read Policies:
-- Teachers: Can read assignments in their authorized school/classroom/subject
CREATE POLICY "assignments_teacher_read" ON public.learning_assignments FOR SELECT
USING (
    teacher_user_id = auth.uid()
    OR EXISTS (
        SELECT 1 FROM public.school_memberships sm
        WHERE sm.user_id = auth.uid()
          AND sm.school_id = learning_assignments.school_id
          AND sm.role = 'school_admin'
          AND sm.status = 'active'
    )
);

-- Students: Can read published/closed assignments where they are an active recipient
CREATE POLICY "assignments_student_read" ON public.learning_assignments FOR SELECT
USING (
    status IN ('published', 'closed')
    AND public.is_assignment_recipient(id, auth.uid())
);

CREATE POLICY "assignment_questions_read" ON public.learning_assignment_questions FOR SELECT
USING (
    public.can_read_assignment_recipient_rows(assignment_id, auth.uid())
    OR (
        EXISTS (
            SELECT 1 FROM public.learning_assignments a
            WHERE a.id = learning_assignment_questions.assignment_id
              AND a.status IN ('published', 'closed')
        )
        AND public.is_assignment_recipient(assignment_id, auth.uid())
    )
);

CREATE POLICY "assignment_recipients_read" ON public.learning_assignment_recipients FOR SELECT
USING (
    student_user_id = auth.uid()
    OR public.can_read_assignment_recipient_rows(assignment_id, auth.uid())
);

CREATE POLICY "interventions_read" ON public.student_interventions FOR SELECT
USING (
    teacher_user_id = auth.uid()
    OR student_user_id = auth.uid()
    OR EXISTS (
        SELECT 1 FROM public.school_memberships sm
        WHERE sm.user_id = auth.uid()
          AND sm.school_id = student_interventions.school_id
          AND sm.role = 'school_admin'
          AND sm.status = 'active'
    )
);

-- -----------------------------------------------------------------------------
-- 6. Helper: can_teacher_manage_assignment
-- Verifies active teacher membership, active school status, and active
-- teacher_subject_assignment with strict variant isolation.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.can_teacher_manage_assignment(
    p_school_id    UUID,
    p_classroom_id UUID,
    p_subject_id   TEXT,
    p_exam_variant TEXT
)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM   public.teacher_subject_assignments tsa
        JOIN   public.school_memberships sm
               ON  sm.user_id   = auth.uid()
               AND sm.school_id  = tsa.school_id
               AND sm.role       = 'teacher'
               AND sm.status     = 'active'
        JOIN   public.schools s
               ON  s.id         = tsa.school_id
               AND s.status     = 'active'
        WHERE  tsa.teacher_user_id = auth.uid()
          AND  tsa.school_id       = p_school_id
          AND  tsa.classroom_id    = p_classroom_id
          AND  tsa.subject_id      = p_subject_id
          AND  tsa.status          = 'active'
          AND  (
              -- Mathematics canonical rule: strict variant matching
              CASE
                  WHEN p_subject_id = 'math_g12' THEN tsa.exam_variant = p_exam_variant
                  ELSE (tsa.exam_variant IS NOT DISTINCT FROM p_exam_variant OR tsa.exam_variant IS NULL)
              END
          )
    );
$$;

REVOKE ALL ON FUNCTION public.can_teacher_manage_assignment(UUID, UUID, TEXT, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.can_teacher_manage_assignment(UUID, UUID, TEXT, TEXT) TO authenticated;

-- -----------------------------------------------------------------------------
-- 7. RPC: create_learning_assignment
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.create_learning_assignment(
    p_school_id            UUID,
    p_classroom_id         UUID,
    p_subject_id           TEXT,
    p_exam_variant         TEXT,
    p_title                TEXT,
    p_instructions         TEXT,
    p_assignment_type      TEXT,
    p_time_limit_minutes   INT DEFAULT 0,
    p_due_at               TIMESTAMPTZ DEFAULT NULL,
    p_allow_late_submission BOOLEAN DEFAULT true
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_assignment_id UUID;
    v_title TEXT := trim(COALESCE(p_title, ''));
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Authentication required' USING ERRCODE = '42501';
    END IF;

    IF v_title = '' THEN
        RAISE EXCEPTION 'Assignment title cannot be empty' USING ERRCODE = '22000';
    END IF;

    IF p_assignment_type NOT IN ('targetedPractice', 'customQuestionSet', 'simulation') THEN
        RAISE EXCEPTION 'Invalid assignment type: %', p_assignment_type USING ERRCODE = '22000';
    END IF;

    IF NOT public.can_teacher_manage_assignment(p_school_id, p_classroom_id, p_subject_id, p_exam_variant) THEN
        RAISE EXCEPTION 'Teacher is not authorized to create assignments for this classroom and subject' USING ERRCODE = '42501';
    END IF;

    INSERT INTO public.learning_assignments (
        school_id,
        classroom_id,
        teacher_user_id,
        subject_id,
        exam_variant,
        title,
        instructions,
        assignment_type,
        status,
        time_limit_minutes,
        due_at,
        allow_late_submission,
        total_questions,
        created_at,
        updated_at
    ) VALUES (
        p_school_id,
        p_classroom_id,
        auth.uid(),
        p_subject_id,
        p_exam_variant,
        v_title,
        p_instructions,
        p_assignment_type,
        'draft',
        GREATEST(0, COALESCE(p_time_limit_minutes, 0)),
        p_due_at,
        COALESCE(p_allow_late_submission, true),
        0,
        TIMEZONE('utc', NOW()),
        TIMEZONE('utc', NOW())
    ) RETURNING id INTO v_assignment_id;

    -- Audit log
    INSERT INTO public.audit_log (
        actor_id,
        action,
        target_table,
        target_id,
        metadata
    ) VALUES (
        auth.uid(),
        'assignment_created',
        'learning_assignments',
        v_assignment_id,
        jsonb_build_object(
            'school_id', p_school_id,
            'classroom_id', p_classroom_id,
            'subject_id', p_subject_id,
            'exam_variant', p_exam_variant,
            'assignment_type', p_assignment_type,
            'title', v_title
        )
    );

    RETURN v_assignment_id;
END;
$$;

REVOKE ALL ON FUNCTION public.create_learning_assignment(UUID, UUID, TEXT, TEXT, TEXT, TEXT, TEXT, INT, TIMESTAMPTZ, BOOLEAN) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_learning_assignment(UUID, UUID, TEXT, TEXT, TEXT, TEXT, TEXT, INT, TIMESTAMPTZ, BOOLEAN) TO authenticated;

-- -----------------------------------------------------------------------------
-- 8. RPC: update_learning_assignment_draft
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.update_learning_assignment_draft(
    p_assignment_id        UUID,
    p_title                TEXT,
    p_instructions         TEXT,
    p_time_limit_minutes   INT,
    p_due_at               TIMESTAMPTZ,
    p_allow_late_submission BOOLEAN
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_assign RECORD;
    v_title TEXT := trim(COALESCE(p_title, ''));
BEGIN
    SELECT * INTO v_assign
    FROM public.learning_assignments
    WHERE id = p_assignment_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Assignment not found' USING ERRCODE = 'P0002';
    END IF;

    IF v_assign.status != 'draft' THEN
        RAISE EXCEPTION 'Only draft assignments can be modified' USING ERRCODE = '22000';
    END IF;

    IF v_assign.teacher_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Only the authoring teacher can edit this draft' USING ERRCODE = '42501';
    END IF;

    IF NOT public.can_teacher_manage_assignment(v_assign.school_id, v_assign.classroom_id, v_assign.subject_id, v_assign.exam_variant) THEN
        RAISE EXCEPTION 'Teacher authorization has lapsed' USING ERRCODE = '42501';
    END IF;

    UPDATE public.learning_assignments
    SET title = CASE WHEN v_title != '' THEN v_title ELSE title END,
        instructions = COALESCE(p_instructions, instructions),
        time_limit_minutes = GREATEST(0, COALESCE(p_time_limit_minutes, time_limit_minutes)),
        due_at = p_due_at,
        allow_late_submission = COALESCE(p_allow_late_submission, allow_late_submission),
        updated_at = TIMEZONE('utc', NOW())
    WHERE id = p_assignment_id;

    RETURN true;
END;
$$;

REVOKE ALL ON FUNCTION public.update_learning_assignment_draft(UUID, TEXT, TEXT, INT, TIMESTAMPTZ, BOOLEAN) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.update_learning_assignment_draft(UUID, TEXT, TEXT, INT, TIMESTAMPTZ, BOOLEAN) TO authenticated;

-- -----------------------------------------------------------------------------
-- 9. RPC: publish_learning_assignment (Atomic & Idempotent)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.publish_learning_assignment(
    p_assignment_id        UUID,
    p_question_ids         UUID[],
    p_recipient_student_ids UUID[] DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_assign RECORD;
    v_q_count INT;
    v_recip_count INT := 0;
    v_pos INT;
    v_qid UUID;
    v_sid UUID;
    v_content_hash TEXT;
    v_hash_payload TEXT;
    v_unverified_count INT;
    v_foreign_student_count INT;
BEGIN
    SELECT * INTO v_assign
    FROM public.learning_assignments
    WHERE id = p_assignment_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Assignment not found' USING ERRCODE = 'P0002';
    END IF;

    -- Idempotency check: if already published, return existing counts safely
    IF v_assign.status = 'published' THEN
        SELECT COUNT(*) INTO v_recip_count
        FROM public.learning_assignment_recipients
        WHERE assignment_id = p_assignment_id;

        RETURN jsonb_build_object(
            'success', true,
            'assignment_id', p_assignment_id,
            'status', 'published',
            'total_questions', v_assign.total_questions,
            'recipient_count', v_recip_count,
            'content_hash', v_assign.content_hash,
            'idempotent', true
        );
    END IF;

    IF v_assign.status != 'draft' THEN
        RAISE EXCEPTION 'Cannot publish assignment in status: %', v_assign.status USING ERRCODE = '22000';
    END IF;

    IF v_assign.teacher_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Only the authoring teacher can publish this assignment' USING ERRCODE = '42501';
    END IF;

    IF NOT public.can_teacher_manage_assignment(v_assign.school_id, v_assign.classroom_id, v_assign.subject_id, v_assign.exam_variant) THEN
        RAISE EXCEPTION 'Teacher authorization has lapsed' USING ERRCODE = '42501';
    END IF;

    v_q_count := COALESCE(cardinality(p_question_ids), 0);
    IF v_q_count = 0 THEN
        RAISE EXCEPTION 'Cannot publish assignment without questions' USING ERRCODE = '22000';
    END IF;

    -- 1. Validate questions: must exist, match subject/grade, and be verified
    SELECT COUNT(*) INTO v_unverified_count
    FROM unnest(p_question_ids) AS qid
    LEFT JOIN public.questions q ON q.id = qid
    WHERE q.id IS NULL
       OR q.subject_id != v_assign.subject_id
       OR (v_assign.subject_id = 'math_g12' AND q.exam_variant != v_assign.exam_variant)
       OR q.verification_status NOT IN ('verified', 'approved', 'published', 'corrected');

    IF v_unverified_count > 0 THEN
        RAISE EXCEPTION 'Question selection contains % ineligible or unverified questions for this subject/variant', v_unverified_count USING ERRCODE = '22000';
    END IF;

    -- 2. Freeze questions into learning_assignment_questions
    DELETE FROM public.learning_assignment_questions WHERE assignment_id = p_assignment_id;

    v_pos := 0;
    FOREACH v_qid IN ARRAY p_question_ids LOOP
        INSERT INTO public.learning_assignment_questions (
            assignment_id,
            question_id,
            position,
            question_content_version,
            package_version
        ) VALUES (
            p_assignment_id,
            v_qid,
            v_pos,
            1,
            '1.0.0'
        );
        v_pos := v_pos + 1;
    END LOOP;

    -- Compute SHA-256 fingerprint over ordered question list
    v_hash_payload := p_assignment_id::text || '|' || v_assign.subject_id || '|' || COALESCE(v_assign.exam_variant, 'none') || '|' || array_to_string(p_question_ids, ',');
    v_content_hash := encode(sha256(v_hash_payload::bytea), 'hex');

    -- 3. Resolve and freeze recipients
    DELETE FROM public.learning_assignment_recipients WHERE assignment_id = p_assignment_id;

    IF p_recipient_student_ids IS NOT NULL AND cardinality(p_recipient_student_ids) > 0 THEN
        -- Explicit subset provided: verify all belong to this classroom and active school
        SELECT COUNT(*) INTO v_foreign_student_count
        FROM unnest(p_recipient_student_ids) AS sid
        LEFT JOIN public.classroom_memberships cm 
               ON cm.user_id = sid 
              AND cm.classroom_id = v_assign.classroom_id 
              AND cm.status = 'active'
        LEFT JOIN public.school_memberships sm 
               ON sm.user_id = sid 
              AND sm.school_id = v_assign.school_id 
              AND sm.status = 'active'
        WHERE cm.user_id IS NULL OR sm.user_id IS NULL;

        IF v_foreign_student_count > 0 THEN
            RAISE EXCEPTION 'Target recipients include % students not actively enrolled in this classroom', v_foreign_student_count USING ERRCODE = '42501';
        END IF;

        FOREACH v_sid IN ARRAY p_recipient_student_ids LOOP
            INSERT INTO public.learning_assignment_recipients (
                assignment_id,
                student_user_id,
                assigned_at,
                status
            ) VALUES (
                p_assignment_id,
                v_sid,
                TIMEZONE('utc', NOW()),
                'assigned'
            );
            v_recip_count := v_recip_count + 1;
        END LOOP;
    ELSE
        -- Default: freeze entire active classroom roster
        INSERT INTO public.learning_assignment_recipients (
            assignment_id,
            student_user_id,
            assigned_at,
            status
        )
        SELECT 
            p_assignment_id,
            cm.user_id,
            TIMEZONE('utc', NOW()),
            'assigned'
        FROM public.classroom_memberships cm
        JOIN public.school_memberships sm 
             ON sm.user_id = cm.user_id 
            AND sm.school_id = v_assign.school_id 
            AND sm.status = 'active'
        WHERE cm.classroom_id = v_assign.classroom_id
          AND cm.status = 'active';

        GET DIAGNOSTICS v_recip_count = ROW_COUNT;
    END IF;

    -- 4. Transition to published
    UPDATE public.learning_assignments
    SET status = 'published',
        total_questions = v_q_count,
        content_hash = v_content_hash,
        published_at = TIMEZONE('utc', NOW()),
        updated_at = TIMEZONE('utc', NOW())
    WHERE id = p_assignment_id;

    -- 5. Audit log
    INSERT INTO public.audit_log (
        actor_id,
        action,
        target_table,
        target_id,
        metadata
    ) VALUES (
        auth.uid(),
        'assignment_published',
        'learning_assignments',
        p_assignment_id,
        jsonb_build_object(
            'total_questions', v_q_count,
            'recipient_count', v_recip_count,
            'content_hash', v_content_hash
        )
    );

    RETURN jsonb_build_object(
        'success', true,
        'assignment_id', p_assignment_id,
        'status', 'published',
        'total_questions', v_q_count,
        'recipient_count', v_recip_count,
        'content_hash', v_content_hash,
        'idempotent', false
    );
END;
$$;

REVOKE ALL ON FUNCTION public.publish_learning_assignment(UUID, UUID[], UUID[]) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.publish_learning_assignment(UUID, UUID[], UUID[]) TO authenticated;

-- -----------------------------------------------------------------------------
-- 10. RPC: close_learning_assignment & archive_learning_assignment
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.close_learning_assignment(p_assignment_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_assign RECORD;
BEGIN
    SELECT * INTO v_assign FROM public.learning_assignments WHERE id = p_assignment_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Assignment not found' USING ERRCODE = 'P0002';
    END IF;

    IF v_assign.teacher_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Only authoring teacher can close this assignment' USING ERRCODE = '42501';
    END IF;

    UPDATE public.learning_assignments
    SET status = 'closed',
        closed_at = TIMEZONE('utc', NOW()),
        updated_at = TIMEZONE('utc', NOW())
    WHERE id = p_assignment_id;

    INSERT INTO public.audit_log (actor_id, action, target_table, target_id, metadata)
    VALUES (auth.uid(), 'assignment_closed', 'learning_assignments', p_assignment_id, jsonb_build_object('closed_at', NOW()));

    RETURN true;
END;
$$;

REVOKE ALL ON FUNCTION public.close_learning_assignment(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.close_learning_assignment(UUID) TO authenticated;

CREATE OR REPLACE FUNCTION public.archive_learning_assignment(p_assignment_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_assign RECORD;
BEGIN
    SELECT * INTO v_assign FROM public.learning_assignments WHERE id = p_assignment_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Assignment not found' USING ERRCODE = 'P0002';
    END IF;

    IF v_assign.teacher_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Only authoring teacher can archive this assignment' USING ERRCODE = '42501';
    END IF;

    UPDATE public.learning_assignments
    SET status = 'archived',
        updated_at = TIMEZONE('utc', NOW())
    WHERE id = p_assignment_id;

    INSERT INTO public.audit_log (actor_id, action, target_table, target_id, metadata)
    VALUES (auth.uid(), 'assignment_archived', 'learning_assignments', p_assignment_id, jsonb_build_object('archived_at', NOW()));

    RETURN true;
END;
$$;

REVOKE ALL ON FUNCTION public.archive_learning_assignment(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.archive_learning_assignment(UUID) TO authenticated;

-- -----------------------------------------------------------------------------
-- 11. RPC: add_assignment_recipient
-- Deliberately adds a newly joined student to an already published assignment.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.add_assignment_recipient(
    p_assignment_id  UUID,
    p_student_user_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_assign RECORD;
    v_is_enrolled BOOLEAN;
BEGIN
    SELECT * INTO v_assign FROM public.learning_assignments WHERE id = p_assignment_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Assignment not found' USING ERRCODE = 'P0002';
    END IF;

    IF v_assign.teacher_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Only authoring teacher can add recipients' USING ERRCODE = '42501';
    END IF;

    -- Verify student is active member of this classroom and school
    SELECT EXISTS (
        SELECT 1 
        FROM public.classroom_memberships cm
        JOIN public.school_memberships sm 
             ON sm.user_id = cm.user_id 
            AND sm.school_id = v_assign.school_id 
            AND sm.status = 'active'
        WHERE cm.classroom_id = v_assign.classroom_id
          AND cm.user_id = p_student_user_id
          AND cm.status = 'active'
    ) INTO v_is_enrolled;

    IF NOT v_is_enrolled THEN
        RAISE EXCEPTION 'Student is not actively enrolled in this classroom' USING ERRCODE = '42501';
    END IF;

    INSERT INTO public.learning_assignment_recipients (
        assignment_id,
        student_user_id,
        assigned_at,
        status
    ) VALUES (
        p_assignment_id,
        p_student_user_id,
        TIMEZONE('utc', NOW()),
        'assigned'
    ) ON CONFLICT (assignment_id, student_user_id) DO NOTHING;

    INSERT INTO public.audit_log (actor_id, action, target_table, target_id, metadata)
    VALUES (
        auth.uid(),
        'assignment_recipient_added',
        'learning_assignment_recipients',
        p_assignment_id,
        jsonb_build_object('student_user_id', p_student_user_id)
    );

    RETURN true;
END;
$$;

REVOKE ALL ON FUNCTION public.add_assignment_recipient(UUID, UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.add_assignment_recipient(UUID, UUID) TO authenticated;

-- -----------------------------------------------------------------------------
-- 12. RPC: get_teacher_assignments (Teacher Read Model)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_teacher_assignments(
    p_school_id    UUID,
    p_classroom_id UUID DEFAULT NULL,
    p_subject_id   TEXT DEFAULT NULL,
    p_status       TEXT DEFAULT NULL,
    p_limit        INT DEFAULT 50,
    p_offset       INT DEFAULT 0
)
RETURNS TABLE (
    assignment_id        UUID,
    school_id            UUID,
    classroom_id         UUID,
    classroom_name       TEXT,
    subject_id           TEXT,
    exam_variant         TEXT,
    title                TEXT,
    instructions         TEXT,
    assignment_type      TEXT,
    status               TEXT,
    due_at               TIMESTAMPTZ,
    allow_late_submission BOOLEAN,
    time_limit_minutes   INT,
    total_questions      INT,
    created_at           TIMESTAMPTZ,
    published_at         TIMESTAMPTZ,
    closed_at            TIMESTAMPTZ,
    recipient_count      BIGINT,
    submitted_count      BIGINT,
    avg_score_percentage NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_limit INT := LEAST(GREATEST(1, COALESCE(p_limit, 50)), 100);
    v_offset INT := GREATEST(0, COALESCE(p_offset, 0));
BEGIN
    RETURN QUERY
    SELECT 
        a.id AS assignment_id,
        a.school_id,
        a.classroom_id,
        c.name AS classroom_name,
        a.subject_id,
        a.exam_variant,
        a.title,
        a.instructions,
        a.assignment_type,
        a.status,
        a.due_at,
        a.allow_late_submission,
        a.time_limit_minutes,
        a.total_questions,
        a.created_at,
        a.published_at,
        a.closed_at,
        COALESCE(COUNT(r.id), 0) AS recipient_count,
        COALESCE(COUNT(r.id) FILTER (WHERE r.status IN ('submitted', 'completed', 'late')), 0) AS submitted_count,
        ROUND(COALESCE(AVG(r.percentage) FILTER (WHERE r.status IN ('submitted', 'completed', 'late')), 0.0)::numeric, 1) AS avg_score_percentage
    FROM public.learning_assignments a
    JOIN public.classrooms c ON c.id = a.classroom_id
    LEFT JOIN public.learning_assignment_recipients r ON r.assignment_id = a.id
    WHERE a.school_id = p_school_id
      AND (a.teacher_user_id = auth.uid() OR EXISTS (
          SELECT 1 FROM public.school_memberships sm 
          WHERE sm.user_id = auth.uid() AND sm.school_id = a.school_id AND sm.role = 'school_admin' AND sm.status = 'active'
      ))
      AND (p_classroom_id IS NULL OR a.classroom_id = p_classroom_id)
      AND (p_subject_id IS NULL OR a.subject_id = p_subject_id)
      AND (p_status IS NULL OR a.status = p_status)
    GROUP BY a.id, c.name
    ORDER BY a.created_at DESC
    LIMIT v_limit OFFSET v_offset;
END;
$$;

REVOKE ALL ON FUNCTION public.get_teacher_assignments(UUID, UUID, TEXT, TEXT, INT, INT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_teacher_assignments(UUID, UUID, TEXT, TEXT, INT, INT) TO authenticated;

-- -----------------------------------------------------------------------------
-- 13. RPC: get_teacher_assignment_progress
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_teacher_assignment_progress(
    p_assignment_id UUID,
    p_limit         INT DEFAULT 100,
    p_offset        INT DEFAULT 0
)
RETURNS TABLE (
    recipient_id      UUID,
    student_user_id   UUID,
    student_name      TEXT,
    school_student_id TEXT,
    status            TEXT,
    score             INT,
    percentage        NUMERIC,
    started_at        TIMESTAMPTZ,
    submitted_at      TIMESTAMPTZ,
    assigned_at       TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_limit INT := LEAST(GREATEST(1, COALESCE(p_limit, 100)), 200);
    v_offset INT := GREATEST(0, COALESCE(p_offset, 0));
BEGIN
    RETURN QUERY
    SELECT 
        r.id AS recipient_id,
        r.student_user_id,
        p.display_name AS student_name,
        sm_student.school_student_id,
        r.status,
        r.score,
        r.percentage,
        r.started_at,
        r.submitted_at,
        r.assigned_at
    FROM public.learning_assignment_recipients r
    JOIN public.learning_assignments a ON a.id = r.assignment_id
    JOIN public.profiles p ON p.id = r.student_user_id
    LEFT JOIN public.school_memberships sm_student ON sm_student.user_id = r.student_user_id AND sm_student.school_id = a.school_id
    WHERE r.assignment_id = p_assignment_id
      AND (a.teacher_user_id = auth.uid() OR EXISTS (
          SELECT 1 FROM public.school_memberships sm 
          WHERE sm.user_id = auth.uid() AND sm.school_id = a.school_id AND sm.role = 'school_admin' AND sm.status = 'active'
      ))
    ORDER BY p.display_name ASC
    LIMIT v_limit OFFSET v_offset;
END;
$$;

REVOKE ALL ON FUNCTION public.get_teacher_assignment_progress(UUID, INT, INT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_teacher_assignment_progress(UUID, INT, INT) TO authenticated;

-- -----------------------------------------------------------------------------
-- 14. RPC: get_student_assignments (Student Read Model)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_student_assignments(
    p_status TEXT DEFAULT NULL,
    p_limit  INT DEFAULT 50,
    p_offset INT DEFAULT 0
)
RETURNS TABLE (
    assignment_id        UUID,
    recipient_id         UUID,
    school_id            UUID,
    classroom_id         UUID,
    classroom_name       TEXT,
    teacher_name         TEXT,
    subject_id           TEXT,
    exam_variant         TEXT,
    title                TEXT,
    instructions         TEXT,
    assignment_type      TEXT,
    assignment_status    TEXT,
    student_status       TEXT,
    due_at               TIMESTAMPTZ,
    allow_late_submission BOOLEAN,
    time_limit_minutes   INT,
    total_questions      INT,
    attempt_id           UUID,
    score                INT,
    percentage           NUMERIC,
    submitted_at         TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_limit INT := LEAST(GREATEST(1, COALESCE(p_limit, 50)), 100);
    v_offset INT := GREATEST(0, COALESCE(p_offset, 0));
BEGIN
    RETURN QUERY
    SELECT 
        a.id AS assignment_id,
        r.id AS recipient_id,
        a.school_id,
        a.classroom_id,
        c.name AS classroom_name,
        tp.display_name AS teacher_name,
        a.subject_id,
        a.exam_variant,
        a.title,
        a.instructions,
        a.assignment_type,
        a.status AS assignment_status,
        r.status AS student_status,
        a.due_at,
        a.allow_late_submission,
        a.time_limit_minutes,
        a.total_questions,
        r.attempt_id,
        r.score,
        r.percentage,
        r.submitted_at
    FROM public.learning_assignment_recipients r
    JOIN public.learning_assignments a ON a.id = r.assignment_id
    JOIN public.classrooms c ON c.id = a.classroom_id
    JOIN public.profiles tp ON tp.id = a.teacher_user_id
    WHERE r.student_user_id = auth.uid()
      AND a.status IN ('published', 'closed')
      AND (p_status IS NULL OR r.status = p_status)
    ORDER BY COALESCE(a.due_at, a.created_at) ASC, a.created_at DESC
    LIMIT v_limit OFFSET v_offset;
END;
$$;

REVOKE ALL ON FUNCTION public.get_student_assignments(TEXT, INT, INT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_student_assignments(TEXT, INT, INT) TO authenticated;

-- -----------------------------------------------------------------------------
-- 15. RPC: get_student_assignment_detail
-- Returns assignment info and question IDs in frozen order without answer keys.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_student_assignment_detail(p_assignment_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_assign RECORD;
    v_recip RECORD;
    v_qids UUID[];
BEGIN
    SELECT * INTO v_assign
    FROM public.learning_assignments
    WHERE id = p_assignment_id
      AND status IN ('published', 'closed');

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Assignment not found or not currently available' USING ERRCODE = 'P0002';
    END IF;

    SELECT * INTO v_recip
    FROM public.learning_assignment_recipients
    WHERE assignment_id = p_assignment_id
      AND student_user_id = auth.uid();

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Student is not an authorized recipient of this assignment' USING ERRCODE = '42501';
    END IF;

    SELECT array_agg(question_id ORDER BY position ASC) INTO v_qids
    FROM public.learning_assignment_questions
    WHERE assignment_id = p_assignment_id;

    RETURN jsonb_build_object(
        'assignment_id', v_assign.id,
        'title', v_assign.title,
        'instructions', v_assign.instructions,
        'subject_id', v_assign.subject_id,
        'exam_variant', v_assign.exam_variant,
        'assignment_type', v_assign.assignment_type,
        'status', v_assign.status,
        'time_limit_minutes', v_assign.time_limit_minutes,
        'due_at', v_assign.due_at,
        'allow_late_submission', v_assign.allow_late_submission,
        'total_questions', v_assign.total_questions,
        'question_ids', COALESCE(v_qids, ARRAY[]::UUID[]),
        'student_status', v_recip.status,
        'attempt_id', v_recip.attempt_id,
        'score', v_recip.score,
        'percentage', v_recip.percentage,
        'submitted_at', v_recip.submitted_at
    );
END;
$$;

REVOKE ALL ON FUNCTION public.get_student_assignment_detail(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_student_assignment_detail(UUID) TO authenticated;

-- -----------------------------------------------------------------------------
-- 16. RPC: submit_student_assignment (Idempotent submission link)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.submit_student_assignment(
    p_assignment_id UUID,
    p_attempt_id    UUID,
    p_score         INT,
    p_percentage    NUMERIC,
    p_submitted_at  TIMESTAMPTZ DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_assign RECORD;
    v_recip RECORD;
    v_sub_time TIMESTAMPTZ := COALESCE(p_submitted_at, TIMEZONE('utc', NOW()));
    v_final_status TEXT;
BEGIN
    SELECT * INTO v_assign
    FROM public.learning_assignments
    WHERE id = p_assignment_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Assignment not found' USING ERRCODE = 'P0002';
    END IF;

    SELECT * INTO v_recip
    FROM public.learning_assignment_recipients
    WHERE assignment_id = p_assignment_id
      AND student_user_id = auth.uid()
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Student is not an assigned recipient' USING ERRCODE = '42501';
    END IF;

    -- Idempotent: if already submitted with this attempt, return current state
    IF v_recip.status IN ('submitted', 'completed', 'late') AND v_recip.attempt_id = p_attempt_id THEN
        RETURN jsonb_build_object(
            'success', true,
            'assignment_id', p_assignment_id,
            'attempt_id', p_attempt_id,
            'status', v_recip.status,
            'score', v_recip.score,
            'percentage', v_recip.percentage,
            'idempotent', true
        );
    END IF;

    -- Check deadline policy
    IF v_assign.due_at IS NOT NULL AND v_sub_time > v_assign.due_at THEN
        IF v_assign.allow_late_submission THEN
            v_final_status := 'late';
        ELSE
            -- Closed policy without late submission allowance
            v_final_status := 'submitted';
        END IF;
    ELSE
        v_final_status := 'submitted';
    END IF;

    UPDATE public.learning_assignment_recipients
    SET status = v_final_status,
        attempt_id = p_attempt_id,
        score = p_score,
        percentage = p_percentage,
        submitted_at = v_sub_time,
        updated_at = TIMEZONE('utc', NOW())
    WHERE id = v_recip.id;

    -- If there is an active intervention linked to this assignment, update intervention status
    UPDATE public.student_interventions
    SET status = 'active',
        started_at = COALESCE(started_at, v_sub_time),
        updated_at = TIMEZONE('utc', NOW())
    WHERE linked_assignment_id = p_assignment_id
      AND student_user_id = auth.uid()
      AND status = 'open';

    RETURN jsonb_build_object(
        'success', true,
        'assignment_id', p_assignment_id,
        'attempt_id', p_attempt_id,
        'status', v_final_status,
        'score', p_score,
        'percentage', p_percentage,
        'idempotent', false
    );
END;
$$;

REVOKE ALL ON FUNCTION public.submit_student_assignment(UUID, UUID, INT, NUMERIC, TIMESTAMPTZ) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.submit_student_assignment(UUID, UUID, INT, NUMERIC, TIMESTAMPTZ) TO authenticated;

-- -----------------------------------------------------------------------------
-- 17. RPC: create_student_intervention
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.create_student_intervention(
    p_school_id            UUID,
    p_classroom_id         UUID,
    p_subject_id           TEXT,
    p_exam_variant         TEXT,
    p_student_user_id      UUID,
    p_source               TEXT,
    p_source_reason_codes  JSONB,
    p_severity_at_creation TEXT,
    p_action_type          TEXT,
    p_linked_assignment_id UUID DEFAULT NULL,
    p_teacher_note         TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_intervention_id UUID;
    v_is_enrolled BOOLEAN;
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Authentication required' USING ERRCODE = '42501';
    END IF;

    IF NOT public.can_teacher_manage_assignment(p_school_id, p_classroom_id, p_subject_id, p_exam_variant) THEN
        RAISE EXCEPTION 'Teacher is not authorized for this classroom and subject' USING ERRCODE = '42501';
    END IF;

    -- Verify student is active in classroom
    SELECT EXISTS (
        SELECT 1 FROM public.classroom_memberships cm
        JOIN public.school_memberships sm 
             ON sm.user_id = cm.user_id 
            AND sm.school_id = p_school_id 
            AND sm.status = 'active'
        WHERE cm.classroom_id = p_classroom_id
          AND cm.user_id = p_student_user_id
          AND cm.status = 'active'
    ) INTO v_is_enrolled;

    IF NOT v_is_enrolled THEN
        RAISE EXCEPTION 'Student is not actively enrolled in this classroom' USING ERRCODE = '42501';
    END IF;

    IF p_source NOT IN ('p7Attention', 'teacherObservation', 'assessmentReview', 'mistakeReview') THEN
        RAISE EXCEPTION 'Invalid intervention source: %', p_source USING ERRCODE = '22000';
    END IF;

    IF p_action_type NOT IN ('targetedPractice', 'reviewMistakes', 'simulation', 'teacherFollowUp') THEN
        RAISE EXCEPTION 'Invalid intervention action type: %', p_action_type USING ERRCODE = '22000';
    END IF;

    INSERT INTO public.student_interventions (
        school_id,
        classroom_id,
        subject_id,
        exam_variant,
        student_user_id,
        teacher_user_id,
        source,
        source_reason_codes,
        severity_at_creation,
        action_type,
        linked_assignment_id,
        status,
        teacher_note,
        created_at,
        updated_at
    ) VALUES (
        p_school_id,
        p_classroom_id,
        p_subject_id,
        p_exam_variant,
        p_student_user_id,
        auth.uid(),
        p_source,
        COALESCE(p_source_reason_codes, '[]'::jsonb),
        p_severity_at_creation,
        p_action_type,
        p_linked_assignment_id,
        'open',
        substr(trim(COALESCE(p_teacher_note, '')), 1, 1000),
        TIMEZONE('utc', NOW()),
        TIMEZONE('utc', NOW())
    ) RETURNING id INTO v_intervention_id;

    INSERT INTO public.audit_log (actor_id, action, target_table, target_id, metadata)
    VALUES (
        auth.uid(),
        'intervention_created',
        'student_interventions',
        v_intervention_id,
        jsonb_build_object(
            'student_user_id', p_student_user_id,
            'source', p_source,
            'action_type', p_action_type,
            'linked_assignment_id', p_linked_assignment_id
        )
    );

    RETURN v_intervention_id;
END;
$$;

REVOKE ALL ON FUNCTION public.create_student_intervention(UUID, UUID, TEXT, TEXT, UUID, TEXT, JSONB, TEXT, TEXT, UUID, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_student_intervention(UUID, UUID, TEXT, TEXT, UUID, TEXT, JSONB, TEXT, TEXT, UUID, TEXT) TO authenticated;

-- -----------------------------------------------------------------------------
-- 18. RPC: complete_student_intervention & close_student_intervention
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.complete_student_intervention(p_intervention_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_rec RECORD;
BEGIN
    SELECT * INTO v_rec FROM public.student_interventions WHERE id = p_intervention_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Intervention not found' USING ERRCODE = 'P0002';
    END IF;

    IF v_rec.teacher_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Only authoring teacher can complete intervention' USING ERRCODE = '42501';
    END IF;

    UPDATE public.student_interventions
    SET status = 'completed',
        completed_at = TIMEZONE('utc', NOW()),
        updated_at = TIMEZONE('utc', NOW())
    WHERE id = p_intervention_id;

    INSERT INTO public.audit_log (actor_id, action, target_table, target_id, metadata)
    VALUES (auth.uid(), 'intervention_completed', 'student_interventions', p_intervention_id, jsonb_build_object('completed_at', NOW()));

    RETURN true;
END;
$$;

REVOKE ALL ON FUNCTION public.complete_student_intervention(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.complete_student_intervention(UUID) TO authenticated;

CREATE OR REPLACE FUNCTION public.close_student_intervention(p_intervention_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_rec RECORD;
BEGIN
    SELECT * INTO v_rec FROM public.student_interventions WHERE id = p_intervention_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Intervention not found' USING ERRCODE = 'P0002';
    END IF;

    IF v_rec.teacher_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Only authoring teacher can close intervention' USING ERRCODE = '42501';
    END IF;

    UPDATE public.student_interventions
    SET status = 'closed',
        closed_at = TIMEZONE('utc', NOW()),
        updated_at = TIMEZONE('utc', NOW())
    WHERE id = p_intervention_id;

    INSERT INTO public.audit_log (actor_id, action, target_table, target_id, metadata)
    VALUES (auth.uid(), 'intervention_closed', 'student_interventions', p_intervention_id, jsonb_build_object('closed_at', NOW()));

    RETURN true;
END;
$$;

REVOKE ALL ON FUNCTION public.close_student_intervention(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.close_student_intervention(UUID) TO authenticated;

-- -----------------------------------------------------------------------------
-- 19. RPC: get_teacher_interventions
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_teacher_interventions(
    p_school_id    UUID,
    p_classroom_id UUID DEFAULT NULL,
    p_subject_id   TEXT DEFAULT NULL,
    p_status       TEXT DEFAULT NULL,
    p_limit        INT DEFAULT 50,
    p_offset       INT DEFAULT 0
)
RETURNS TABLE (
    intervention_id        UUID,
    school_id              UUID,
    classroom_id           UUID,
    classroom_name         TEXT,
    subject_id             TEXT,
    exam_variant           TEXT,
    student_user_id        UUID,
    student_name           TEXT,
    school_student_id      TEXT,
    source                 TEXT,
    source_reason_codes    JSONB,
    severity_at_creation   TEXT,
    action_type            TEXT,
    linked_assignment_id   UUID,
    linked_assignment_title TEXT,
    status                 TEXT,
    teacher_note           TEXT,
    created_at             TIMESTAMPTZ,
    started_at             TIMESTAMPTZ,
    completed_at           TIMESTAMPTZ,
    closed_at              TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_limit INT := LEAST(GREATEST(1, COALESCE(p_limit, 50)), 100);
    v_offset INT := GREATEST(0, COALESCE(p_offset, 0));
BEGIN
    RETURN QUERY
    SELECT 
        i.id AS intervention_id,
        i.school_id,
        i.classroom_id,
        c.name AS classroom_name,
        i.subject_id,
        i.exam_variant,
        i.student_user_id,
        p.display_name AS student_name,
        sm_student.school_student_id,
        i.source,
        i.source_reason_codes,
        i.severity_at_creation,
        i.action_type,
        i.linked_assignment_id,
        a.title AS linked_assignment_title,
        i.status,
        i.teacher_note,
        i.created_at,
        i.started_at,
        i.completed_at,
        i.closed_at
    FROM public.student_interventions i
    JOIN public.classrooms c ON c.id = i.classroom_id
    JOIN public.profiles p ON p.id = i.student_user_id
    LEFT JOIN public.school_memberships sm_student ON sm_student.user_id = i.student_user_id AND sm_student.school_id = i.school_id
    LEFT JOIN public.learning_assignments a ON a.id = i.linked_assignment_id
    WHERE i.school_id = p_school_id
      AND (i.teacher_user_id = auth.uid() OR EXISTS (
          SELECT 1 FROM public.school_memberships sm 
          WHERE sm.user_id = auth.uid() AND sm.school_id = i.school_id AND sm.role = 'school_admin' AND sm.status = 'active'
      ))
      AND (p_classroom_id IS NULL OR i.classroom_id = p_classroom_id)
      AND (p_subject_id IS NULL OR i.subject_id = p_subject_id)
      AND (p_status IS NULL OR i.status = p_status)
    ORDER BY i.created_at DESC
    LIMIT v_limit OFFSET v_offset;
END;
$$;

REVOKE ALL ON FUNCTION public.get_teacher_interventions(UUID, UUID, TEXT, TEXT, INT, INT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_teacher_interventions(UUID, UUID, TEXT, TEXT, INT, INT) TO authenticated;
