-- FidelLearn Supabase Seed Data for Development
INSERT INTO public.subjects (id, code, name_en, name_am, grade, stream, icon_asset, sort_order) VALUES
    ('math_g12', 'MATH12', 'Mathematics', 'ሂሳብ', 12, 'natural', 'assets/images/math_icon.png', 1),
    ('aptitude_g12', 'APT12', 'Scholastic Aptitude', 'አፕቲትዩድ', 12, 'common', 'assets/images/aptitude_icon.png', 2)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.units (id, subject_id, unit_number, title_en, title_am) VALUES
    ('math_u1', 'math_g12', 1, 'Sequences and Series', 'ተከታታዮችና ድምሮች'),
    ('math_u2', 'math_g12', 2, 'Introduction to Calculus & Limits', 'የካልኩለስ መግቢያ እና ገደቦች'),
    ('apt_u1', 'aptitude_g12', 1, 'Numerical Reasoning', 'የቁጥር አመክንዮ'),
    ('apt_u2', 'aptitude_g12', 2, 'Verbal Reasoning & Analogies', 'የቃል አመክንዮና ዝምድናዎች')
ON CONFLICT (id) DO NOTHING;
