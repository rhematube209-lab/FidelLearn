-- =============================================================================
-- FidelLearn Seed Data: Subjects, Units & Topics
-- =============================================================================

-- 1. Educational Subjects
INSERT INTO public.subjects (id, code, name_en, name_am, grade, stream, icon_asset, sort_order) VALUES ('math_g12', 'MATH12', 'Mathematics', 'ሂሳብ', 12, 'natural', 'assets/images/math_icon.png', 1) ON CONFLICT (id) DO UPDATE SET name_en=EXCLUDED.name_en, name_am=EXCLUDED.name_am;
INSERT INTO public.subjects (id, code, name_en, name_am, grade, stream, icon_asset, sort_order) VALUES ('aptitude_g12', 'APT12', 'Scholastic Aptitude', 'አፕቲትዩድ', 12, 'common', 'assets/images/aptitude_icon.png', 2) ON CONFLICT (id) DO UPDATE SET name_en=EXCLUDED.name_en, name_am=EXCLUDED.name_am;
INSERT INTO public.subjects (id, code, name_en, name_am, grade, stream, icon_asset, sort_order) VALUES ('math_g6', 'MATH6', 'Mathematics (Grade 6)', 'ሂሳብ', 6, 'common', 'assets/images/math_icon.png', 3) ON CONFLICT (id) DO UPDATE SET name_en=EXCLUDED.name_en, name_am=EXCLUDED.name_am;
INSERT INTO public.subjects (id, code, name_en, name_am, grade, stream, icon_asset, sort_order) VALUES ('science_g6', 'SCI6', 'Integrated Science (Grade 6)', 'የተቀናጀ ሳይንስ', 6, 'common', 'assets/images/science_icon.png', 4) ON CONFLICT (id) DO UPDATE SET name_en=EXCLUDED.name_en, name_am=EXCLUDED.name_am;
INSERT INTO public.subjects (id, code, name_en, name_am, grade, stream, icon_asset, sort_order) VALUES ('math_g8', 'MATH8', 'Mathematics (Grade 8)', 'ሂሳብ', 8, 'common', 'assets/images/math_icon.png', 5) ON CONFLICT (id) DO UPDATE SET name_en=EXCLUDED.name_en, name_am=EXCLUDED.name_am;
INSERT INTO public.subjects (id, code, name_en, name_am, grade, stream, icon_asset, sort_order) VALUES ('science_g8', 'SCI8', 'General Science (Grade 8)', 'አጠቃላይ ሳይንስ', 8, 'common', 'assets/images/science_icon.png', 6) ON CONFLICT (id) DO UPDATE SET name_en=EXCLUDED.name_en, name_am=EXCLUDED.name_am;
INSERT INTO public.subjects (id, code, name_en, name_am, grade, stream, icon_asset, sort_order) VALUES ('history_g12', 'HIST12', 'History', 'ታሪክ', 12, 'social', 'assets/images/history_icon.png', 7) ON CONFLICT (id) DO UPDATE SET name_en=EXCLUDED.name_en, name_am=EXCLUDED.name_am;
INSERT INTO public.subjects (id, code, name_en, name_am, grade, stream, icon_asset, sort_order) VALUES ('geography_g12', 'GEO12', 'Geography', 'ጂኦግራፊ', 12, 'social', 'assets/images/geography_icon.png', 8) ON CONFLICT (id) DO UPDATE SET name_en=EXCLUDED.name_en, name_am=EXCLUDED.name_am;
INSERT INTO public.subjects (id, code, name_en, name_am, grade, stream, icon_asset, sort_order) VALUES ('economics_g12', 'ECON12', 'Economics', 'ኢኮኖሚክስ', 12, 'social', 'assets/images/economics_icon.png', 9) ON CONFLICT (id) DO UPDATE SET name_en=EXCLUDED.name_en, name_am=EXCLUDED.name_am;

-- 2. Units
INSERT INTO public.units (id, subject_id, unit_number, title_en, title_am) VALUES ('math_u1', 'math_g12', 1, 'Sequences and Series', 'ተከታታዮችና ድምሮች') ON CONFLICT (id) DO UPDATE SET title_en=EXCLUDED.title_en;
INSERT INTO public.units (id, subject_id, unit_number, title_en, title_am) VALUES ('math_u2', 'math_g12', 2, 'Introduction to Calculus & Limits', 'የካልኩለስ መግቢያ እና ገደቦች') ON CONFLICT (id) DO UPDATE SET title_en=EXCLUDED.title_en;
INSERT INTO public.units (id, subject_id, unit_number, title_en, title_am) VALUES ('apt_u1', 'aptitude_g12', 1, 'Numerical Reasoning', 'የቁጥር አመክንዮ') ON CONFLICT (id) DO UPDATE SET title_en=EXCLUDED.title_en;
INSERT INTO public.units (id, subject_id, unit_number, title_en, title_am) VALUES ('apt_u2', 'aptitude_g12', 2, 'Verbal Reasoning & Analogies', 'የቃል አመክንዮና ዝምድናዎች') ON CONFLICT (id) DO UPDATE SET title_en=EXCLUDED.title_en;
INSERT INTO public.units (id, subject_id, unit_number, title_en, title_am) VALUES ('g6_math_u1', 'math_g6', 1, 'Fractions and Decimals', 'ክፍልፋዮችና አስርዮሾች') ON CONFLICT (id) DO UPDATE SET title_en=EXCLUDED.title_en;
INSERT INTO public.units (id, subject_id, unit_number, title_en, title_am) VALUES ('g6_sci_u1', 'science_g6', 1, 'Living Things & Environments', 'ሕያዋን ፍጥረታትና አካባቢያቸው') ON CONFLICT (id) DO UPDATE SET title_en=EXCLUDED.title_en;
INSERT INTO public.units (id, subject_id, unit_number, title_en, title_am) VALUES ('g8_math_u1', 'math_g8', 1, 'Geometry and Triangles', 'ጂኦሜትሪ እና ባለሶስት ጎኖች') ON CONFLICT (id) DO UPDATE SET title_en=EXCLUDED.title_en;
INSERT INTO public.units (id, subject_id, unit_number, title_en, title_am) VALUES ('g8_sci_u1', 'science_g8', 1, 'Electricity and Circuits', 'ኤሌክትሪክና ዑደቶች') ON CONFLICT (id) DO UPDATE SET title_en=EXCLUDED.title_en;
INSERT INTO public.units (id, subject_id, unit_number, title_en, title_am) VALUES ('g12_hist_u1', 'history_g12', 1, 'State Formation & Sovereignty in Ethiopia', 'የሀገር ግንባታና ሉዓላዊነት በኢትዮጵያ') ON CONFLICT (id) DO UPDATE SET title_en=EXCLUDED.title_en;
INSERT INTO public.units (id, subject_id, unit_number, title_en, title_am) VALUES ('g12_geo_u1', 'geography_g12', 1, 'Geology & Rift Valley of Ethiopia', 'የኢትዮጵያ ጂኦሎጂና ስምጥ ሸለቆ') ON CONFLICT (id) DO UPDATE SET title_en=EXCLUDED.title_en;
INSERT INTO public.units (id, subject_id, unit_number, title_en, title_am) VALUES ('g12_econ_u1', 'economics_g12', 1, 'Market Equilibrium & National Income', 'የገበያ ሚዛንና ብሔራዊ ገቢ') ON CONFLICT (id) DO UPDATE SET title_en=EXCLUDED.title_en;

-- 3. Topics
INSERT INTO public.topics (id, unit_id, topic_number, title_en, title_am) VALUES ('math_t1_1', 'math_u1', 1, 'Arithmetic Progressions', 'አርቲሜቲክ ተከታታይ') ON CONFLICT (id) DO UPDATE SET title_en=EXCLUDED.title_en;
INSERT INTO public.topics (id, unit_id, topic_number, title_en, title_am) VALUES ('math_t1_2', 'math_u1', 2, 'Geometric Series & Convergence', 'ጂኦሜትሪክ ተከታታይ') ON CONFLICT (id) DO UPDATE SET title_en=EXCLUDED.title_en;
INSERT INTO public.topics (id, unit_id, topic_number, title_en, title_am) VALUES ('math_t2_1', 'math_u2', 1, 'Limits at Infinity', 'የወሰን ገደቦች') ON CONFLICT (id) DO UPDATE SET title_en=EXCLUDED.title_en;
INSERT INTO public.topics (id, unit_id, topic_number, title_en, title_am) VALUES ('math_t2_2', 'math_u2', 2, 'Derivatives & Rates of Change', 'ለውጦችና ዲሪቬቲቭ') ON CONFLICT (id) DO UPDATE SET title_en=EXCLUDED.title_en;
INSERT INTO public.topics (id, unit_id, topic_number, title_en, title_am) VALUES ('apt_t1_1', 'apt_u1', 1, 'Number Patterns & Series', 'የቁጥር ቅደም ተከተሎች') ON CONFLICT (id) DO UPDATE SET title_en=EXCLUDED.title_en;
INSERT INTO public.topics (id, unit_id, topic_number, title_en, title_am) VALUES ('apt_t1_2', 'apt_u1', 2, 'Quantitative Proportions & Ratios', 'ተመጣጣኝነትና ንፅፅር') ON CONFLICT (id) DO UPDATE SET title_en=EXCLUDED.title_en;
INSERT INTO public.topics (id, unit_id, topic_number, title_en, title_am) VALUES ('apt_t2_1', 'apt_u2', 1, 'Semantic Analogies', 'የቃላት ዝምድና') ON CONFLICT (id) DO UPDATE SET title_en=EXCLUDED.title_en;
INSERT INTO public.topics (id, unit_id, topic_number, title_en, title_am) VALUES ('apt_t2_2', 'apt_u2', 2, 'Logical Deductions', 'አመክንዮአዊ ድምዳሜ') ON CONFLICT (id) DO UPDATE SET title_en=EXCLUDED.title_en;
INSERT INTO public.topics (id, unit_id, topic_number, title_en, title_am) VALUES ('g6_math_t1', 'g6_math_u1', 1, 'Operations on Fractions', 'የክፍልፋዮች ስሌት') ON CONFLICT (id) DO UPDATE SET title_en=EXCLUDED.title_en;
INSERT INTO public.topics (id, unit_id, topic_number, title_en, title_am) VALUES ('g6_sci_t1', 'g6_sci_u1', 1, 'Plant Ecosystems & Photosynthesis', 'የእፅዋት ስነ-ህይወት') ON CONFLICT (id) DO UPDATE SET title_en=EXCLUDED.title_en;
INSERT INTO public.topics (id, unit_id, topic_number, title_en, title_am) VALUES ('g8_math_t1', 'g8_math_u1', 1, 'Pythagorean Theorem & Right Triangles', 'ፓይታጎረስ ቴዎረም') ON CONFLICT (id) DO UPDATE SET title_en=EXCLUDED.title_en;
INSERT INTO public.topics (id, unit_id, topic_number, title_en, title_am) VALUES ('g8_sci_t1', 'g8_sci_u1', 1, 'Simple Direct Current Circuits', 'ቀላል የኤሌክትሪክ ዑደት') ON CONFLICT (id) DO UPDATE SET title_en=EXCLUDED.title_en;
INSERT INTO public.topics (id, unit_id, topic_number, title_en, title_am) VALUES ('g12_hist_t1', 'g12_hist_u1', 1, 'The Battle of Adwa (1896)', 'የዓድዋ ድል (1896)') ON CONFLICT (id) DO UPDATE SET title_en=EXCLUDED.title_en;
INSERT INTO public.topics (id, unit_id, topic_number, title_en, title_am) VALUES ('g12_geo_t1', 'g12_geo_u1', 1, 'The Great East African Rift System', 'የታላቁ ምስራቅ አፍሪካ ስምጥ ሸለቆ') ON CONFLICT (id) DO UPDATE SET title_en=EXCLUDED.title_en;
INSERT INTO public.topics (id, unit_id, topic_number, title_en, title_am) VALUES ('g12_econ_t1', 'g12_econ_u1', 1, 'Supply, Demand & Price Elasticity', 'ፍላጎት፣ አቅርቦትና ዋጋ') ON CONFLICT (id) DO UPDATE SET title_en=EXCLUDED.title_en;

-- Automatic Profile Provisioning Trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  v_role TEXT;
BEGIN
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
    display_name = COALESCE(EXCLUDED.display_name, profiles.display_name),
    grade = COALESCE(EXCLUDED.grade, profiles.grade),
    stream = COALESCE(EXCLUDED.stream, profiles.stream),
    preferred_language = COALESCE(EXCLUDED.preferred_language, profiles.preferred_language);

  v_role := COALESCE(NEW.raw_user_meta_data->>'role', 'student');
  INSERT INTO public.user_roles (user_id, role_id)
  VALUES (NEW.id, v_role)
  ON CONFLICT (user_id, role_id) DO NOTHING;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
