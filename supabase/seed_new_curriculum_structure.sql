-- =============================================================================
-- New Ethiopian Secondary Curriculum (Grades 9-12) Subject & Unit Hierarchy
-- Standardized schema for all subjects (Biology, Math, Physics, Chemistry, etc.)
-- =============================================================================

-- 1. Ensure Subjects exist for Grades 9, 10, 11, 12
INSERT INTO public.subjects (id, code, name_en, name_am, grade, stream, icon_asset, sort_order) VALUES
('biology_g9', 'BIO9', 'Biology', 'ባዮሎጂ', 9, 'common', 'assets/images/bio_icon.png', 2),
('biology_g10', 'BIO10', 'Biology', 'ባዮሎጂ', 10, 'common', 'assets/images/bio_icon.png', 2),
('biology_g11', 'BIO11', 'Biology', 'ባዮሎጂ', 11, 'natural', 'assets/images/bio_icon.png', 2),
('biology_g12', 'BIO12', 'Biology', 'ባዮሎጂ', 12, 'natural', 'assets/images/bio_icon.png', 2)
ON CONFLICT (id) DO UPDATE SET name_en=EXCLUDED.name_en, name_am=EXCLUDED.name_am;

-- 2. GRADE 9 BIOLOGY UNITS
INSERT INTO public.units (id, subject_id, unit_number, title_en, title_am) VALUES
('bio_g9_u1', 'biology_g9', 1, 'Introduction to Biology & Biological Inquiry', 'የስነ-ህይወት መግቢያ እና ሳይንሳዊ ምርምር'),
('bio_g9_u2', 'biology_g9', 2, 'Characteristics and Classification of Organisms', 'የህያዋን ፍጥረታት ባህሪያትና ምደባ'),
('bio_g9_u3', 'biology_g9', 3, 'Cell Biology & Structure', 'የሴል ስነ-ህይወትና መዋቅር'),
('bio_g9_u4', 'biology_g9', 4, 'Reproduction in Plants and Animals', 'የዕፅዋትና የእንስሳት መራባት'),
('bio_g9_u5', 'biology_g9', 5, 'Human Health, Nutrition & Infectious Diseases', 'የሰው ጤና፣ አመጋገብ እና ተላላፊ በሽታዎች'),
('bio_g9_u6', 'biology_g9', 6, 'Ecology & Environmental Conservation', 'ኢኮሎጂ እና የአካባቢ ጥበቃ')
ON CONFLICT (id) DO UPDATE SET title_en=EXCLUDED.title_en, title_am=EXCLUDED.title_am;

-- 3. GRADE 10 BIOLOGY UNITS
INSERT INTO public.units (id, subject_id, unit_number, title_en, title_am) VALUES
('bio_g10_u1', 'biology_g10', 1, 'Sub-fields of Biology and Biotechnology', 'የባዮሎጂ ንዑሳን ዘርፎችና ባዮቴክኖሎጂ'),
('bio_g10_u2', 'biology_g10', 2, 'Heredity and Classical Genetics', 'የዘር ውርስና ክላሲካል ጄኔቲክስ'),
('bio_g10_u3', 'biology_g10', 3, 'Human Biology: Body Systems', 'የሰው አካል ስርዓቶች'),
('bio_g10_u4', 'biology_g10', 4, 'Food Production, Agriculture & Breeding', 'የምግብ ምርት፣ ግብርና እና ዝርያ ማሻሻል'),
('bio_g10_u5', 'biology_g10', 5, 'Conservation of Natural Resources', 'የተፈጥሮ ሀብት ጥበቃ')
ON CONFLICT (id) DO UPDATE SET title_en=EXCLUDED.title_en, title_am=EXCLUDED.title_am;

-- 4. GRADE 11 BIOLOGY UNITS
INSERT INTO public.units (id, subject_id, unit_number, title_en, title_am) VALUES
('bio_g11_u1', 'biology_g11', 1, 'Biological Research, Methodology & Tools', 'የስነ-ህይወት ምርምር፣ ዘዴዎችና መሳሪያዎች'),
('bio_g11_u2', 'biology_g11', 2, 'Biochemical Molecules & Enzyme Action', 'ባዮኬሚካላዊ ሞለኪዩሎች እና ኢንዛይሞች'),
('bio_g11_u3', 'biology_g11', 3, 'Cellular Transport & Membrane Dynamics', 'የሴል ሽፋን ዝውውር'),
('bio_g11_u4', 'biology_g11', 4, 'Energy Transformation: Photosynthesis & Respiration', 'የሃይል ልውውጥ፡ ፎቶሲንተሲስና ሴሉላር አተነፋፈስ'),
('bio_g11_u5', 'biology_g11', 5, 'Molecular Genetics & Protein Synthesis', 'ሞለኪዩላር ጄኔቲክስ እና የፕሮቲን ቅንብር')
ON CONFLICT (id) DO UPDATE SET title_en=EXCLUDED.title_en, title_am=EXCLUDED.title_am;

-- 5. GRADE 12 BIOLOGY UNITS
INSERT INTO public.units (id, subject_id, unit_number, title_en, title_am) VALUES
('bio_g12_u1', 'biology_g12', 1, 'Microorganisms and Human Health', 'ደቂቅ አካላትና የሰው ጤና'),
('bio_g12_u2', 'biology_g12', 2, 'Evolution & Animal Behavior (Ethology)', 'ዝግመተ-ለውጥ እና የእንስሳት ባህሪ'),
('bio_g12_u3', 'biology_g12', 3, 'Applied Biotechnology & Genetic Engineering', 'የተግባራዊ ባዮቴክኖሎጂና ጄኔቲክ ምህንድስና'),
('bio_g12_u4', 'biology_g12', 4, 'Population Ecology, Biomes & Environment', 'የህዝብ ብዛት ኢኮሎጂ፣ ባዮሞችና አካባቢ')
ON CONFLICT (id) DO UPDATE SET title_en=EXCLUDED.title_en, title_am=EXCLUDED.title_am;
