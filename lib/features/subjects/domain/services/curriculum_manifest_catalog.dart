import '../models/subject_manifest.dart';
import '../models/subject_models.dart';

/// Authoritative catalog of official curriculum manifests for Ethiopian Grade 12 ESSLCE.
/// Defines official denominators verified against Ministry of Education syllabus guides,
/// student textbooks, and EAES (Educational Assessment and Examinations Service) specifications.
class CurriculumManifestCatalog {
  CurriculumManifestCatalog._();

  static const List<int> defaultTargetYears = [
    2013,
    2014,
    2015,
    2016,
    2017,
    2018
  ];

  // 1. English Manifest (Mixed Assessment: Passages + Language Skills)
  static const SubjectManifest english = SubjectManifest(
    manifestId: 'manifest_english_g12',
    canonicalSubjectId: 'english_g12',
    variantCode: ExamVariantCode.shared,
    title: 'Grade 12 English Language Assessment Specification',
    sourceAuthority: 'FDRE Ministry of Education',
    sourceDocumentTitle: 'Grade 12 English Language Assessment Specification',
    sourceDocumentId: 'MOE-ESSLCE-G12-ENG-SPEC-2015',
    sourceReference:
        'FDRE Ministry of Education Grade 12 English Syllabus & EAES Subject Code 07 Specification',
    sourceUrlOrReference: 'https://moe.gov.et/curriculum/grade-12/english',
    curriculumVersion: 'current_grade12',
    verifiedAt: '2024-08-15',
    verifiedBy:
        'MoE National Curriculum Review Committee & EAES Subject Specialists',
    verificationStatus: ManifestVerificationStatus.confirmed,
    assessmentStructure: AssessmentStructure.mixed,
    scope: SubjectScope.commonExam,
    targetPastExamYears: defaultTargetYears,
    expectedUnitsOrDomains: [
      ExpectedUnitOrDomain(
        index: 1,
        id: 'eng_domain_reading',
        titleEn: 'Reading Comprehension',
        titleAm: 'የንባብ ግንዛቤ',
        domainType: 'skill_domain',
        sourceReference: 'MoE Grade 12 English Syllabus Section 1',
        sourcePage: 'pp. 12-18',
        primaryTopics: [
          'Unseen Prose Passages',
          'Main Idea & Supporting Details',
          'Contextual Vocabulary & Referencing',
          'Author Purpose & Inference',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 2,
        id: 'eng_domain_vocabulary',
        titleEn: 'Vocabulary & Idiomatic Expressions',
        titleAm: 'የቃላት ትርጉምና ፈሊጣዊ አነጋገሮች',
        domainType: 'skill_domain',
        sourceReference: 'MoE Grade 12 English Syllabus Section 2',
        sourcePage: 'pp. 19-25',
        primaryTopics: [
          'Synonyms & Antonyms in Context',
          'Collocations & Phrasal Verbs',
          'Idioms & Figurative Language',
          'Affixes & Word Formation',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 3,
        id: 'eng_domain_grammar',
        titleEn: 'Grammar & Syntactic Structures',
        titleAm: 'ሰዋስው እና የአረፍተ ነገር አወቃቀር',
        domainType: 'skill_domain',
        sourceReference: 'MoE Grade 12 English Syllabus Section 3',
        sourcePage: 'pp. 26-38',
        primaryTopics: [
          'Tense & Aspect System',
          'Conditionals & Modals',
          'Relative Clauses & Subordination',
          'Passive Voice & Reported Speech',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 4,
        id: 'eng_domain_communication',
        titleEn: 'Language Usage & Communication',
        titleAm: 'የቋንቋ አጠቃቀም እና ተግባቦት',
        domainType: 'skill_domain',
        sourceReference: 'MoE Grade 12 English Syllabus Section 4',
        sourcePage: 'pp. 39-44',
        primaryTopics: [
          'Situational Dialogues',
          'Functional Language (Apologies, Requests, Preferences)',
          'Conversational Turn-taking',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 5,
        id: 'eng_domain_sentence_completion',
        titleEn: 'Sentence Completion & Connectors',
        titleAm: 'አረፍተ ነገር ማሟላት እና አያያዥ ቃላት',
        domainType: 'skill_domain',
        sourceReference: 'MoE Grade 12 English Syllabus Section 5',
        sourcePage: 'pp. 45-52',
        primaryTopics: [
          'Discourse Markers & Transition Words',
          'Logical Connectors (Contrast, Cause-Effect, Addition)',
          'Cloze Passage Evaluation',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 6,
        id: 'eng_domain_writing',
        titleEn: 'Writing Skills & Punctuation',
        titleAm: 'የመጻፍ ክህሎት እና ስርዓተ ነጥብ',
        domainType: 'skill_domain',
        sourceReference: 'MoE Grade 12 English Syllabus Section 6',
        sourcePage: 'pp. 53-61',
        primaryTopics: [
          'Paragraph Unity & Coherence',
          'Sentence Combining & Error Recognition',
          'Punctuation Rules & Mechanics',
          'Formal & Informal Letter Conventions',
        ],
      ),
    ],
  );

  // 2. Mathematics (Natural Science Track)
  static const SubjectManifest mathNatural = SubjectManifest(
    manifestId: 'manifest_math_natural_g12',
    canonicalSubjectId: 'math_g12',
    variantCode: ExamVariantCode.naturalScience,
    title: 'Grade 12 Mathematics (Natural Science Track)',
    sourceAuthority: 'FDRE Ministry of Education',
    sourceDocumentTitle:
        'Grade 12 Mathematics (Natural Science Track) Syllabus Specification',
    sourceDocumentId: 'MOE-ESSLCE-G12-MATH-NAT-2015',
    sourceReference:
        'FDRE Ministry of Education Grade 12 Mathematics Syllabus & EAES Subject Code 01',
    sourceUrlOrReference: 'https://moe.gov.et/curriculum/grade-12/math-natural',
    curriculumVersion: 'current_grade12',
    verifiedAt: '2024-08-15',
    verifiedBy:
        'MoE National Curriculum Review Committee & EAES Subject Specialists',
    verificationStatus: ManifestVerificationStatus.confirmed,
    assessmentStructure: AssessmentStructure.curriculum,
    scope: SubjectScope.commonExam,
    targetPastExamYears: defaultTargetYears,
    expectedUnitsOrDomains: [
      ExpectedUnitOrDomain(
        index: 1,
        id: 'math_nat_u1',
        titleEn: 'Sequences and Series',
        titleAm: 'ቅደም ተከተሎች እና ዝርዝሮች',
        sourceReference: 'MoE G12 Natural Mathematics Syllabus',
        sourcePage: 'Unit 1, pp. 1-28',
        primaryTopics: [
          'Arithmetic Sequences & Partial Sums',
          'Geometric Sequences & Infinite Series',
          'Sigma Notation & Convergence Tests',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 2,
        id: 'math_nat_u2',
        titleEn: 'Limits and Continuity',
        titleAm: 'ወሰኖች እና ቀጣይነት',
        sourceReference: 'MoE G12 Natural Mathematics Syllabus',
        sourcePage: 'Unit 2, pp. 29-56',
        primaryTopics: [
          'Intuitive and Formal Definition of Limits',
          'One-sided Limits & Limits at Infinity',
          'Continuity of Elementary Functions',
          'Intermediate Value Theorem',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 3,
        id: 'math_nat_u3',
        titleEn: 'Introduction to Differential Calculus',
        titleAm: 'የልዩነት ካልኩለስ መግቢያ',
        sourceReference: 'MoE G12 Natural Mathematics Syllabus',
        sourcePage: 'Unit 3, pp. 57-92',
        primaryTopics: [
          'Definition of the Derivative',
          'Differentiation Rules (Product, Quotient, Chain)',
          'Derivatives of Trigonometric, Exponential & Logarithmic Functions',
          'Implicit Differentiation',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 4,
        id: 'math_nat_u4',
        titleEn: 'Applications of Differential Calculus',
        titleAm: 'የልዩነት ካልኩለስ ተግባራዊ አጠቃቀም',
        sourceReference: 'MoE G12 Natural Mathematics Syllabus',
        sourcePage: 'Unit 4, pp. 93-134',
        primaryTopics: [
          'Rates of Change & Related Rates',
          'Extreme Values & Critical Points',
          'Mean Value Theorem & Monotonicity',
          'Concavity, Inflection Points & Curve Sketching',
          'Optimization Problems',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 5,
        id: 'math_nat_u5',
        titleEn: 'Integral Calculus & Differential Equations',
        titleAm: 'የጥቅልል ካልኩለስ እና ዲፈረንሻል እኩልታዎች',
        sourceReference: 'MoE G12 Natural Mathematics Syllabus',
        sourcePage: 'Unit 5, pp. 135-180',
        primaryTopics: [
          'Antiderivatives & Indefinite Integrals',
          'Integration by Substitution & by Parts',
          'Fundamental Theorem of Calculus',
          'Definite Integrals & Areas under Curves',
          'First-Order Separable Differential Equations',
        ],
      ),
    ],
  );

  // 3. Mathematics (Social Science Track)
  static const SubjectManifest mathSocial = SubjectManifest(
    manifestId: 'manifest_math_social_g12',
    canonicalSubjectId: 'math_g12',
    variantCode: ExamVariantCode.socialScience,
    title: 'Grade 12 Mathematics (Social Science Track)',
    sourceAuthority: 'FDRE Ministry of Education',
    sourceDocumentTitle:
        'Grade 12 Mathematics (Social Science Track) Syllabus Specification',
    sourceDocumentId: 'MOE-ESSLCE-G12-MATH-SOC-2015',
    sourceReference:
        'FDRE Ministry of Education Grade 12 Mathematics (Social Science) Syllabus & EAES Subject Code 02',
    sourceUrlOrReference: 'https://moe.gov.et/curriculum/grade-12/math-social',
    curriculumVersion: 'current_grade12',
    verifiedAt: '2024-08-15',
    verifiedBy:
        'MoE National Curriculum Review Committee & EAES Subject Specialists',
    verificationStatus: ManifestVerificationStatus.confirmed,
    assessmentStructure: AssessmentStructure.curriculum,
    scope: SubjectScope.commonExam,
    targetPastExamYears: defaultTargetYears,
    expectedUnitsOrDomains: [
      ExpectedUnitOrDomain(
        index: 1,
        id: 'math_soc_u1',
        titleEn: 'Sequences and Series',
        titleAm: 'ቅደም ተከተሎች እና ዝርዝሮች',
        sourceReference: 'MoE G12 Social Mathematics Syllabus',
        sourcePage: 'Unit 1, pp. 1-24',
        primaryTopics: [
          'Arithmetic Progressions',
          'Geometric Progressions',
          'Financial Applications: Simple & Compound Interest, Annuities',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 2,
        id: 'math_soc_u2',
        titleEn: 'Differential Calculus for Social Sciences',
        titleAm: 'የልዩነት ካልኩለስ ለማህበራዊ ሳይንስ',
        sourceReference: 'MoE G12 Social Mathematics Syllabus',
        sourcePage: 'Unit 2, pp. 25-50',
        primaryTopics: [
          'Limits of Polynomial & Rational Functions',
          'Derivatives of Algebraic Functions',
          'Marginal Functions (Marginal Cost, Marginal Revenue, Marginal Profit)',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 3,
        id: 'math_soc_u3',
        titleEn: 'Applications of Derivatives to Business & Economics',
        titleAm: 'የውፅኢቶች ተግባራዊ አጠቃቀም ለንግድ እና ኢኮኖሚክስ',
        sourceReference: 'MoE G12 Social Mathematics Syllabus',
        sourcePage: 'Unit 3, pp. 51-78',
        primaryTopics: [
          'Profit Maximization & Cost Minimization',
          'Elasticity of Demand & Supply',
          'Inventory & Economic Order Models',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 4,
        id: 'math_soc_u4',
        titleEn: 'Integral Calculus for Social Sciences',
        titleAm: 'የጥቅልል ካልኩለስ ለማህበራዊ ሳይንስ',
        sourceReference: 'MoE G12 Social Mathematics Syllabus',
        sourcePage: 'Unit 4, pp. 79-106',
        primaryTopics: [
          'Indefinite Integrals of Polynomials',
          'Definite Integrals',
          'Consumer Surplus & Producer Surplus',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 5,
        id: 'math_soc_u5',
        titleEn: 'Statistics and Probability',
        titleAm: 'ስታቲስቲክስ እና ፕሮባብሊቲ',
        sourceReference: 'MoE G12 Social Mathematics Syllabus',
        sourcePage: 'Unit 5, pp. 107-138',
        primaryTopics: [
          'Measures of Central Tendency & Dispersion',
          'Probability Rules & Conditional Probability',
          'Normal Distribution & Z-Scores',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 6,
        id: 'math_soc_u6',
        titleEn: 'Business Mathematics & Linear Programming',
        titleAm: 'የንግድ ሂሳብ እና መስመራዊ ፕሮግራሚንግ',
        sourceReference: 'MoE G12 Social Mathematics Syllabus',
        sourcePage: 'Unit 6, pp. 139-172',
        primaryTopics: [
          'Linear Inequalities in Two Variables',
          'Graphical Method for Linear Programming',
          'Objective Function Optimization under Constraints',
        ],
      ),
    ],
  );

  // 4. Scholastic Aptitude Test (Skill-Based Assessment)
  static const SubjectManifest scholasticAptitude = SubjectManifest(
    manifestId: 'manifest_aptitude_g12',
    canonicalSubjectId: 'aptitude_g12',
    variantCode: ExamVariantCode.shared,
    title: 'Grade 12 Scholastic Aptitude National Examination Specification',
    sourceAuthority: 'Educational Assessment and Examinations Service (EAES)',
    sourceDocumentTitle:
        'Grade 12 Scholastic Aptitude National Examination Specification',
    sourceDocumentId: 'EAES-ESSLCE-G12-APT-2015',
    sourceReference:
        'EAES National Assessment Specification for Scholastic Aptitude',
    sourceUrlOrReference: 'https://eaes.et/specifications/scholastic-aptitude',
    curriculumVersion: 'current_grade12',
    verifiedAt: '2024-08-15',
    verifiedBy: 'EAES National Test Design & Assessment Committee',
    verificationStatus: ManifestVerificationStatus.confirmed,
    assessmentStructure: AssessmentStructure.skillBased,
    scope: SubjectScope.commonExam,
    targetPastExamYears: defaultTargetYears,
    expectedUnitsOrDomains: [
      ExpectedUnitOrDomain(
        index: 1,
        id: 'apt_domain_verbal',
        titleEn: 'Verbal Reasoning',
        titleAm: 'ቃላዊ አመክንዮ',
        domainType: 'cognitive_domain',
        sourceReference: 'EAES Scholastic Aptitude Specification Domain 1',
        sourcePage: 'pp. 4-12',
        primaryTopics: [
          'Word Analogies & Conceptual Relationships',
          'Synonymic & Antonymic Discriminators',
          'Analytical Deduction & Logical Syllogisms',
          'Reading Comprehension Inference',
          'Sentence Logic & Semantic Completion',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 2,
        id: 'apt_domain_quantitative',
        titleEn: 'Quantitative Reasoning',
        titleAm: 'ቁጥራዊ አመክንዮ',
        domainType: 'cognitive_domain',
        sourceReference: 'EAES Scholastic Aptitude Specification Domain 2',
        sourcePage: 'pp. 13-26',
        primaryTopics: [
          'Number Sequences & Pattern Recognition',
          'Arithmetic Properties, Percentages & Ratios',
          'Algebraic Relationships & Equations',
          'Quantitative Comparison Problems',
          'Data Interpretation (Tables, Bar Charts, Line Graphs)',
          'Mathematical Word Problem Solving',
        ],
      ),
    ],
  );

  // 5. Physics Manifest (9 Units)
  static const SubjectManifest physics = SubjectManifest(
    manifestId: 'manifest_physics_g12',
    canonicalSubjectId: 'physics_g12',
    variantCode: ExamVariantCode.naturalScience,
    title: 'Grade 12 Physics Syllabus Specification',
    sourceAuthority: 'FDRE Ministry of Education',
    sourceDocumentTitle: 'Grade 12 Physics Syllabus Specification',
    sourceDocumentId: 'MOE-ESSLCE-G12-PHYS-2015',
    sourceReference:
        'FDRE Ministry of Education Grade 12 Physics Syllabus & EAES Subject Code 03',
    sourceUrlOrReference: 'https://moe.gov.et/curriculum/grade-12/physics',
    curriculumVersion: 'current_grade12',
    verifiedAt: '2024-08-15',
    verifiedBy:
        'MoE National Curriculum Review Committee & EAES Subject Specialists',
    verificationStatus: ManifestVerificationStatus.confirmed,
    assessmentStructure: AssessmentStructure.curriculum,
    targetPastExamYears: defaultTargetYears,
    expectedUnitsOrDomains: [
      ExpectedUnitOrDomain(
        index: 1,
        id: 'phys_u1',
        titleEn: 'Thermodynamics',
        titleAm: 'ቴርሞዳይናሚክስ',
        sourceReference: 'MoE Grade 12 Physics Syllabus',
        sourcePage: 'Unit 1, pp. 1-32',
        primaryTopics: [
          'Thermal Equilibrium & Zeroth Law',
          'First Law of Thermodynamics & Work Done by Gases',
          'Second Law of Thermodynamics & Heat Engines',
          'Carnot Cycle & Entropy',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 2,
        id: 'phys_u2',
        titleEn: 'Oscillations and Waves',
        titleAm: 'ኦስሌሽኖች እና ሞገዶች',
        sourceReference: 'MoE Grade 12 Physics Syllabus',
        sourcePage: 'Unit 2, pp. 33-64',
        primaryTopics: [
          'Simple Harmonic Motion (SHM)',
          'Pendulums and Mass-Spring Systems',
          'Wave Properties, Speed & Wave Equation',
          'Superposition, Interference & Standing Waves',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 3,
        id: 'phys_u3',
        titleEn: 'Wave Optics',
        titleAm: 'የሞገድ ኦፕቲክስ',
        sourceReference: 'MoE Grade 12 Physics Syllabus',
        sourcePage: 'Unit 3, pp. 65-98',
        primaryTopics: [
          'Huygens Principle',
          'Young Double-Slit Interference',
          'Diffraction Grating & Single-Slit Diffraction',
          'Polarization of Light',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 4,
        id: 'phys_u4',
        titleEn: 'Electrostatics',
        titleAm: 'ኤሌክትሮስታቲክስ',
        sourceReference: 'MoE Grade 12 Physics Syllabus',
        sourcePage: 'Unit 4, pp. 99-138',
        primaryTopics: [
          'Coulombs Law & Electric Field',
          'Electric Potential & Potential Energy',
          'Capacitance & Dielectrics',
          'Capacitor Combinations & Energy Storage',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 5,
        id: 'phys_u5',
        titleEn: 'Steady Electric Currents & DC Circuits',
        titleAm: 'የማይለዋወጡ የኤሌክትሪክ ፍሰቶች እና ወረዳዎች',
        sourceReference: 'MoE Grade 12 Physics Syllabus',
        sourcePage: 'Unit 5, pp. 139-178',
        primaryTopics: [
          'Electric Current, Drift Velocity & Ohms Law',
          'Resistance, Resistivity & Temperature Dependence',
          'Kirchhoffs Laws & Multi-Loop Circuits',
          'Electrical Power & Energy',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 6,
        id: 'phys_u6',
        titleEn: 'Magnetism',
        titleAm: 'መግነጢሳዊነት',
        sourceReference: 'MoE Grade 12 Physics Syllabus',
        sourcePage: 'Unit 6, pp. 179-218',
        primaryTopics: [
          'Magnetic Fields & Field Lines',
          'Magnetic Force on Moving Charges & Current-Carrying Wires',
          'Biot-Savart Law & Amperes Law',
          'Magnetic Properties of Matter',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 7,
        id: 'phys_u7',
        titleEn: 'Electromagnetic Induction & AC Circuits',
        titleAm: 'ኤሌክትሮማግኔቲክ ኢንዳክሽን እና ተለዋጭ ፍሰት ወረዳዎች',
        sourceReference: 'MoE Grade 12 Physics Syllabus',
        sourcePage: 'Unit 7, pp. 219-262',
        primaryTopics: [
          'Magnetic Flux & Faradays Law',
          'Lenzs Law & Motional EMF',
          'Self & Mutual Inductance',
          'AC Circuits (RL, RC, RLC Resonance)',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 8,
        id: 'phys_u8',
        titleEn: 'Atomic Physics',
        titleAm: 'የአቶም ፊዚክስ',
        sourceReference: 'MoE Grade 12 Physics Syllabus',
        sourcePage: 'Unit 8, pp. 263-298',
        primaryTopics: [
          'Photoelectric Effect & Photons',
          'Bohr Model of the Hydrogen Atom',
          'De Broglie Wavelength & Wave-Particle Duality',
          'X-Rays & Laser Principles',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 9,
        id: 'phys_u9',
        titleEn: 'Nuclear Physics',
        titleAm: 'የኒውክሌር ፊዚክስ',
        sourceReference: 'MoE Grade 12 Physics Syllabus',
        sourcePage: 'Unit 9, pp. 299-338',
        primaryTopics: [
          'Nuclear Composition, Radius & Binding Energy',
          'Radioactivity & Half-life Decay Law',
          'Nuclear Fission & Fusion',
          'Radiation Detectors & Safety',
        ],
      ),
    ],
  );

  // 6. Chemistry Manifest (6 Units)
  static const SubjectManifest chemistry = SubjectManifest(
    manifestId: 'manifest_chemistry_g12',
    canonicalSubjectId: 'chemistry_g12',
    variantCode: ExamVariantCode.naturalScience,
    title: 'Grade 12 Chemistry Syllabus Specification',
    sourceAuthority: 'FDRE Ministry of Education',
    sourceDocumentTitle: 'Grade 12 Chemistry Syllabus Specification',
    sourceDocumentId: 'MOE-ESSLCE-G12-CHEM-2015',
    sourceReference:
        'FDRE Ministry of Education Grade 12 Chemistry Syllabus & EAES Subject Code 05',
    sourceUrlOrReference: 'https://moe.gov.et/curriculum/grade-12/chemistry',
    curriculumVersion: 'current_grade12',
    verifiedAt: '2024-08-15',
    verifiedBy:
        'MoE National Curriculum Review Committee & EAES Subject Specialists',
    verificationStatus: ManifestVerificationStatus.confirmed,
    assessmentStructure: AssessmentStructure.curriculum,
    targetPastExamYears: defaultTargetYears,
    expectedUnitsOrDomains: [
      ExpectedUnitOrDomain(
        index: 1,
        id: 'chem_u1',
        titleEn: 'Solutions',
        titleAm: 'ውህዶች (መፍትሄዎች)',
        sourceReference: 'MoE Grade 12 Chemistry Syllabus',
        sourcePage: 'Unit 1, pp. 1-36',
        primaryTopics: [
          'Types of Solutions & Dissolution Process',
          'Concentration Units (Molarity, Molality, Mole Fraction)',
          'Colligative Properties of Solutions',
          'Colloids & Suspensions',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 2,
        id: 'chem_u2',
        titleEn: 'Acid-Base Equilibria',
        titleAm: 'የአሲድ-ቤዝ ሚዛናዊነት',
        sourceReference: 'MoE Grade 12 Chemistry Syllabus',
        sourcePage: 'Unit 2, pp. 37-78',
        primaryTopics: [
          'Acid-Base Concepts (Arrhenius, Bronsted-Lowry, Lewis)',
          'Autoionization of Water & pH Scale',
          'Strengths of Acids and Bases & Ionization Constants',
          'Buffer Solutions & Henderson-Hasselbalch Equation',
          'Acid-Base Titrations & Indicators',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 3,
        id: 'chem_u3',
        titleEn: 'Energy Changes in Chemical Reactions (Thermodynamics)',
        titleAm: 'የኢነርጂ ለውጦች በኬሚካላዊ ግብረ-መልሶች ውስጥ',
        sourceReference: 'MoE Grade 12 Chemistry Syllabus',
        sourcePage: 'Unit 3, pp. 79-114',
        primaryTopics: [
          'First Law of Thermodynamics & Enthalpy',
          'Hesss Law & Standard Enthalpy of Formation',
          'Entropy & Second Law of Thermodynamics',
          'Gibbs Free Energy & Reaction Spontaneity',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 4,
        id: 'chem_u4',
        titleEn: 'Electrochemistry',
        titleAm: 'ኤሌክትሮኬሚስትሪ',
        sourceReference: 'MoE Grade 12 Chemistry Syllabus',
        sourcePage: 'Unit 4, pp. 115-156',
        primaryTopics: [
          'Redox Reactions & Balancing',
          'Electrochemical Cells (Galvanic & Electrolytic)',
          'Standard Electrode Potentials & Nernst Equation',
          'Faradays Laws of Electrolysis',
          'Batteries, Fuel Cells & Corrosion',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 5,
        id: 'chem_u5',
        titleEn: 'Some Elements in Chemistry and Industry',
        titleAm: 'አንዳንድ ንጥረ ነገሮች በኢንዱስትሪ ኬሚስትሪ ውስጥ',
        sourceReference: 'MoE Grade 12 Chemistry Syllabus',
        sourcePage: 'Unit 5, pp. 157-198',
        primaryTopics: [
          'Metallurgy of Iron, Copper & Aluminum',
          'Manufacture of Ammonia, Nitric Acid & Sulfuric Acid',
          'Fertilizer Production in Ethiopia',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 6,
        id: 'chem_u6',
        titleEn: 'Polymers',
        titleAm: 'ፖሊመሮች',
        sourceReference: 'MoE Grade 12 Chemistry Syllabus',
        sourcePage: 'Unit 6, pp. 199-232',
        primaryTopics: [
          'Natural vs Synthetic Polymers',
          'Addition & Condensation Polymerization',
          'Properties and Environmental Impacts of Plastics',
        ],
      ),
    ],
  );

  // 7. Biology Manifest (6 Units)
  static const SubjectManifest biology = SubjectManifest(
    manifestId: 'manifest_biology_g12',
    canonicalSubjectId: 'biology_g12',
    variantCode: ExamVariantCode.naturalScience,
    title: 'Grade 12 Biology Syllabus Specification',
    sourceAuthority: 'FDRE Ministry of Education',
    sourceDocumentTitle: 'Grade 12 Biology Syllabus Specification',
    sourceDocumentId: 'MOE-ESSLCE-G12-BIO-2015',
    sourceReference:
        'FDRE Ministry of Education Grade 12 Biology Syllabus & EAES Subject Code 04',
    sourceUrlOrReference: 'https://moe.gov.et/curriculum/grade-12/biology',
    curriculumVersion: 'current_grade12',
    verifiedAt: '2024-08-15',
    verifiedBy:
        'MoE National Curriculum Review Committee & EAES Subject Specialists',
    verificationStatus: ManifestVerificationStatus.confirmed,
    assessmentStructure: AssessmentStructure.curriculum,
    targetPastExamYears: defaultTargetYears,
    expectedUnitsOrDomains: [
      ExpectedUnitOrDomain(
        index: 1,
        id: 'bio_u1',
        titleEn: 'Microorganisms',
        titleAm: 'ደቂቅ አካላት',
        sourceReference: 'MoE Grade 12 Biology Syllabus',
        sourcePage: 'Unit 1, pp. 1-38',
        primaryTopics: [
          'Bacteria, Archaea, Viruses & Fungi',
          'Microbial Growth & Culturing',
          'Beneficial and Pathogenic Microbes',
          'Antibiotics & Resistance',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 2,
        id: 'bio_u2',
        titleEn: 'Energy Transformation (Respiration & Photosynthesis)',
        titleAm: 'የኢነርጂ ሽግግር (አተነፋፈስ እና ፎቶሲንተሲስ)',
        sourceReference: 'MoE Grade 12 Biology Syllabus',
        sourcePage: 'Unit 2, pp. 39-78',
        primaryTopics: [
          'ATP Structure & Function',
          'Cellular Respiration (Glycolysis, Krebs Cycle, ETC)',
          'Photosynthesis (Light Reactions & Calvin Cycle)',
          'Factors Affecting Rates of Respiration & Photosynthesis',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 3,
        id: 'bio_u3',
        titleEn: 'Evolution',
        titleAm: 'ዝግመተ ለውጥ',
        sourceReference: 'MoE Grade 12 Biology Syllabus',
        sourcePage: 'Unit 3, pp. 79-118',
        primaryTopics: [
          'Theories of Evolution (Lamarckism, Darwinism, Modern Synthesis)',
          'Evidence for Evolution (Fossils, Anatomy, Molecular)',
          'Natural Selection & Speciation',
          'Human Evolution & African Fossil Discoveries',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 4,
        id: 'bio_u4',
        titleEn: 'Genetics and Molecular Biology',
        titleAm: 'ጄኔቲክስ እና ሞለኪውላር ባዮሎጂ',
        sourceReference: 'MoE Grade 12 Biology Syllabus',
        sourcePage: 'Unit 4, pp. 119-166',
        primaryTopics: [
          'DNA Structure, Replication & Protein Synthesis',
          'Mendelian Inheritance & Non-Mendelian Extensions',
          'Mutations & Genetic Disorders',
          'Biotechnology & Genetic Engineering',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 5,
        id: 'bio_u5',
        titleEn: 'Behavior',
        titleAm: 'የእንስሳት ባህሪ',
        sourceReference: 'MoE Grade 12 Biology Syllabus',
        sourcePage: 'Unit 5, pp. 167-202',
        primaryTopics: [
          'Innate Behavior (Reflexes, Kinesis, Taxis, FAP)',
          'Learned Behavior (Habituation, Conditioning, Imprinting, Insight)',
          'Social Behavior & Communication in Animals',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 6,
        id: 'bio_u6',
        titleEn: 'Ecology',
        titleAm: 'ስነ-ምህዳር',
        sourceReference: 'MoE Grade 12 Biology Syllabus',
        sourcePage: 'Unit 6, pp. 203-248',
        primaryTopics: [
          'Ecosystem Structure, Energy Flow & Trophic Levels',
          'Biogeochemical Cycles (Carbon, Nitrogen, Water)',
          'Population Dynamics & Ecological Succession',
          'Conservation of Biodiversity in Ethiopia',
        ],
      ),
    ],
  );

  // 8. History Manifest (5 Units)
  static const SubjectManifest history = SubjectManifest(
    manifestId: 'manifest_history_g12',
    canonicalSubjectId: 'history_g12',
    variantCode: ExamVariantCode.socialScience,
    title: 'Grade 12 History Syllabus Specification',
    sourceAuthority: 'FDRE Ministry of Education',
    sourceDocumentTitle: 'Grade 12 History Syllabus Specification',
    sourceDocumentId: 'MOE-ESSLCE-G12-HIST-2015',
    sourceReference:
        'FDRE Ministry of Education Grade 12 History Syllabus & EAES Subject Code 06',
    sourceUrlOrReference: 'https://moe.gov.et/curriculum/grade-12/history',
    curriculumVersion: 'current_grade12',
    verifiedAt: '2024-08-15',
    verifiedBy:
        'MoE National Curriculum Review Committee & EAES Subject Specialists',
    verificationStatus: ManifestVerificationStatus.confirmed,
    assessmentStructure: AssessmentStructure.curriculum,
    targetPastExamYears: defaultTargetYears,
    expectedUnitsOrDomains: [
      ExpectedUnitOrDomain(
        index: 1,
        id: 'hist_u1',
        titleEn: 'Historiography & Sources of Ethiopian History',
        titleAm: 'የታሪክ አጻጻፍ እና የኢትዮጵያ ታሪክ ምንጮች',
        sourceReference: 'MoE Grade 12 History Syllabus',
        sourcePage: 'Unit 1, pp. 1-28',
        primaryTopics: [
          'Nature and Uses of History',
          'Primary and Secondary Sources',
          'Indigenous and External Written Accounts',
          'Archaeology, Linguistics & Oral Traditions',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 2,
        id: 'hist_u2',
        titleEn: 'Zemene Mesafint & Regional States in the 19th Century',
        titleAm: 'ዘመነ መሳፍንት እና የ19ኛው ክፍለ ዘመን ክልላዊ መንግስታት',
        sourceReference: 'MoE Grade 12 History Syllabus',
        sourcePage: 'Unit 2, pp. 29-64',
        primaryTopics: [
          'Characteristics of Zemene Mesafint',
          'The Yejju Dynasty & Regional Power Centers',
          'States of the South, South-West & Horn',
          'Socio-Economic Life & Trade Routes',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 3,
        id: 'hist_u3',
        titleEn: 'The Making of the Modern Ethiopian State (1855–1913)',
        titleAm: 'የዘመናዊው የኢትዮጵያ መንግስት ምሥረታ (1855–1913)',
        sourceReference: 'MoE Grade 12 History Syllabus',
        sourcePage: 'Unit 3, pp. 65-104',
        primaryTopics: [
          'Emperor Tewodros II & Modernization Efforts',
          'Emperor Yohannes IV & Religious/External Challenges',
          'Emperor Menilek II: Territorial Expansion & Modern Institutions',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 4,
        id: 'hist_u4',
        titleEn: 'Anti-Colonial Resistance & the Battle of Adwa',
        titleAm: 'የጸረ-ቅኝ አገዛዝ ተጋድሎ እና የዐድዋ ድል',
        sourceReference: 'MoE Grade 12 History Syllabus',
        sourcePage: 'Unit 4, pp. 105-144',
        primaryTopics: [
          'European Imperialist Scramble for Africa',
          'Treaty of Wuchale (Article XVII Controversy)',
          'Mobilization & Military Strategy at Adwa (1896)',
          'National & Global Significance of Adwas Victory',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 5,
        id: 'hist_u5',
        titleEn: 'The Horn of Africa in the 20th Century & Regional Alliances',
        titleAm: 'የአፍሪካ ቀንድ በ20ኛው ክፍለ ዘመን እና ቀጠናዊ ትብብሮች',
        sourceReference: 'MoE Grade 12 History Syllabus',
        sourcePage: 'Unit 5, pp. 145-188',
        primaryTopics: [
          'Ethiopia in the Inter-War Period & Italian Fascist Occupation',
          'Patriotic Resistance Movement (1936–1941)',
          'Post-Liberation Political Developments',
          'Establishment of the OAU/AU in Addis Ababa',
        ],
      ),
    ],
  );

  // 9. Geography Manifest (8 Units Independently Confirmed)
  static const SubjectManifest geography = SubjectManifest(
    manifestId: 'manifest_geography_g12',
    canonicalSubjectId: 'geography_g12',
    variantCode: ExamVariantCode.socialScience,
    title: 'Grade 12 Geography of Ethiopia & The Horn Syllabus Specification',
    sourceAuthority: 'FDRE Ministry of Education',
    sourceDocumentTitle:
        'Grade 12 Geography Student Textbook & Curriculum Guide',
    sourceDocumentId: 'MOE-ESSLCE-G12-GEO-2015',
    sourceReference:
        'FDRE Ministry of Education Grade 12 Geography Student Textbook & EAES Examination Specification (8 Units Verified)',
    sourceUrlOrReference: 'https://moe.gov.et/curriculum/grade-12/geography',
    curriculumVersion: 'current_grade12',
    verifiedAt: '2024-08-15',
    verifiedBy:
        'MoE National Curriculum Review Committee & EAES Subject Specialists',
    verificationStatus: ManifestVerificationStatus.confirmed,
    assessmentStructure: AssessmentStructure.curriculum,
    targetPastExamYears: defaultTargetYears,
    expectedUnitsOrDomains: [
      ExpectedUnitOrDomain(
        index: 1,
        id: 'geo_u1',
        titleEn: 'Topographic Maps and Geographical Information Systems (GIS)',
        titleAm: 'ቶፖግራፊያዊ ካርታዎች እና የጂኦግራፊያዊ መረጃ ስርዓቶች (ጂአይኤስ)',
        sourceReference: 'MoE Grade 12 Geography Textbook',
        sourcePage: 'Unit 1, pp. 1-38',
        primaryTopics: [
          'Map Reading, Grid References & Scale Calculations',
          'Contour Lines, Gradient & Intervisibility',
          'Introduction to Remote Sensing & GIS Applications',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 2,
        id: 'geo_u2',
        titleEn: 'The Physical Geology and Topography of Ethiopia & The Horn',
        titleAm: 'የኢትዮጵያ እና የአፍሪካ ቀንድ ፊዚካል ጂኦሎጂ እና መልክዓ ምድር',
        sourceReference: 'MoE Grade 12 Geography Textbook',
        sourcePage: 'Unit 2, pp. 39-78',
        primaryTopics: [
          'Geological Eras & Rock Formations in the Horn',
          'Cenozoic Tectonic Events & the East African Rift Valley',
          'Physiographic Divisions: Western Highlands, SE Highlands, Lowlands',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 3,
        id: 'geo_u3',
        titleEn: 'Drainage Systems and Water Resources of Ethiopia & The Horn',
        titleAm: 'የኢትዮጵያ እና የአፍሪካ ቀንድ የፍሳሽ ስርዓቶች እና የውሃ ሀብቶች',
        sourceReference: 'MoE Grade 12 Geography Textbook',
        sourcePage: 'Unit 3, pp. 79-118',
        primaryTopics: [
          'Major Drainage Basins (Western/Nile, SE/Rift Valley, Inland)',
          'Lakes of the Rift Valley & Highland Crater Lakes',
          'Hydroelectric Potential, Irrigation & Transboundary Water Issues',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 4,
        id: 'geo_u4',
        titleEn: 'The Climate of Ethiopia and The Horn',
        titleAm: 'የኢትዮጵያ እና የአፍሪካ ቀንድ አየር ንብረት',
        sourceReference: 'MoE Grade 12 Geography Textbook',
        sourcePage: 'Unit 4, pp. 119-158',
        primaryTopics: [
          'Factors Influencing Climate (Latitude, Altitude, Pressure Systems)',
          'Seasonal Rainfall Mechanisms (ITCZ, Monsoons)',
          'Traditional Agro-Climatic Zones (Bereha, Kolla, Woina Dega, Dega, Wurch)',
          'Droughts, Climate Change & Mitigation Strategies',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 5,
        id: 'geo_u5',
        titleEn: 'Natural Vegetation and Wildlife of Ethiopia & The Horn',
        titleAm: 'የተፈጥሮ እፅዋት እና የዱር እንስሳት በኢትዮጵያ እና አፍሪካ ቀንድ',
        sourceReference: 'MoE Grade 12 Geography Textbook',
        sourcePage: 'Unit 5, pp. 159-198',
        primaryTopics: [
          'Vegetation Belts (Afro-Alpine, Montane Forest, Savanna, Semi-Desert)',
          'Endemic Wildlife Species of Ethiopia',
          'Protected Areas (National Parks, Sanctuaries & Reserves)',
          'Deforestation & Habitat Conservation',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 6,
        id: 'geo_u6',
        titleEn: 'Soils of Ethiopia and The Horn',
        titleAm: 'የኢትዮጵያ እና የአፍሪካ ቀንድ አፈር',
        sourceReference: 'MoE Grade 12 Geography Textbook',
        sourcePage: 'Unit 6, pp. 199-238',
        primaryTopics: [
          'Major Soil Types (Nitosols, Vertisols, Fluvisols, Regosols)',
          'Soil Formation Processes & Fertility',
          'Soil Erosion Mechanisms & Soil Conservation Practices',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 7,
        id: 'geo_u7',
        titleEn: 'The Population of Ethiopia and The Horn',
        titleAm: 'የኢትዮጵያ እና የአፍሪካ ቀንድ ህዝብ',
        sourceReference: 'MoE Grade 12 Geography Textbook',
        sourcePage: 'Unit 7, pp. 239-278',
        primaryTopics: [
          'Population Size, Growth Rates & Demographic Transition',
          'Spatial Distribution & Factors Affecting Density',
          'Age-Sex Composition & Demographic Dividend',
          'Migration Dynamics, Urbanization & Development Implications',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 8,
        id: 'geo_u8',
        titleEn:
            'Economic Activities, Resource Utilization & Environmental Challenges',
        titleAm: 'የኢኮኖሚ እንቅስቃሴዎች፣ የሀብት አጠቃቀም እና የአካባቢ ተግዳሮቶች',
        sourceReference: 'MoE Grade 12 Geography Textbook',
        sourcePage: 'Unit 8, pp. 279-324',
        primaryTopics: [
          'Agricultural Systems: Subsistence, Cash Crop, Pastoralism',
          'Mining, Energy & Manufacturing Sectors',
          'Transportation, Trade & Tourism Potentials',
          'Environmental Degradation & Sustainable Resource Management',
        ],
      ),
    ],
  );

  // 10. Economics Manifest (8 Units Independently Confirmed)
  static const SubjectManifest economics = SubjectManifest(
    manifestId: 'manifest_economics_g12',
    canonicalSubjectId: 'economics_g12',
    variantCode: ExamVariantCode.socialScience,
    title: 'Grade 12 Economics Syllabus Specification',
    sourceAuthority: 'FDRE Ministry of Education',
    sourceDocumentTitle:
        'Grade 12 Economics Student Textbook & Curriculum Guide',
    sourceDocumentId: 'MOE-ESSLCE-G12-ECON-2015',
    sourceReference:
        'FDRE Ministry of Education Grade 12 Economics Student Textbook & EAES Examination Specification (8 Units Verified)',
    sourceUrlOrReference: 'https://moe.gov.et/curriculum/grade-12/economics',
    curriculumVersion: 'current_grade12',
    verifiedAt: '2024-08-15',
    verifiedBy:
        'MoE National Curriculum Review Committee & EAES Subject Specialists',
    verificationStatus: ManifestVerificationStatus.confirmed,
    assessmentStructure: AssessmentStructure.curriculum,
    targetPastExamYears: defaultTargetYears,
    expectedUnitsOrDomains: [
      ExpectedUnitOrDomain(
        index: 1,
        id: 'econ_u1',
        titleEn: 'Fundamental Concepts of Macroeconomics',
        titleAm: 'የማክሮ ኢኮኖሚክስ መሰረታዊ ፅንሰ ሀሳቦች',
        sourceReference: 'MoE Grade 12 Economics Textbook',
        sourcePage: 'Unit 1, pp. 1-32',
        primaryTopics: [
          'Microeconomics vs Macroeconomics',
          'Circular Flow of Income (Two, Three & Four Sector Models)',
          'National Income Accounting: GDP, GNP, NNP, Real vs Nominal',
          'Approaches to Measuring National Output (Expenditure, Income, Output)',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 2,
        id: 'econ_u2',
        titleEn: 'Aggregate Demand (AD) and Aggregate Supply (AS) Analysis',
        titleAm: 'የአጠቃላይ ፍላጎት (AD) እና አጠቃላይ አቅርቦት (AS) ትንተና',
        sourceReference: 'MoE Grade 12 Economics Textbook',
        sourcePage: 'Unit 2, pp. 33-68',
        primaryTopics: [
          'Components of Aggregate Demand & AD Shifts',
          'Short-Run & Long-Run Aggregate Supply Curves',
          'Macroeconomic Equilibrium & Output Gaps',
          'Keynesian vs Classical Multiplier Concepts',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 3,
        id: 'econ_u3',
        titleEn: 'Market Structures and Market Failures',
        titleAm: 'የገበያ አወቃቀሮች እና የገበያ ክፍተቶች',
        sourceReference: 'MoE Grade 12 Economics Textbook',
        sourcePage: 'Unit 3, pp. 69-106',
        primaryTopics: [
          'Perfect Competition, Monopoly, Monopolistic Competition, Oligopoly',
          'Price and Output Determination under Market Types',
          'Externalities, Public Goods & Market Inefficiencies',
          'Government Interventions & Regulatory Measures',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 4,
        id: 'econ_u4',
        titleEn: 'Inflation and Unemployment',
        titleAm: 'የዋጋ ግሽበት እና ስራ አጥነት',
        sourceReference: 'MoE Grade 12 Economics Textbook',
        sourcePage: 'Unit 4, pp. 107-142',
        primaryTopics: [
          'Types and Causes of Inflation (Demand-Pull, Cost-Push)',
          'Measuring Inflation: Consumer Price Index (CPI) & GDP Deflator',
          'Types of Unemployment: Frictional, Structural, Cyclical',
          'The Phillips Curve & Economic Trade-offs',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 5,
        id: 'econ_u5',
        titleEn: 'Money, Banking and Financial Markets',
        titleAm: 'ገንዘብ፣ ባንክ እና የፋይናንስ ገበያዎች',
        sourceReference: 'MoE Grade 12 Economics Textbook',
        sourcePage: 'Unit 5, pp. 143-182',
        primaryTopics: [
          'Functions and Evolution of Money',
          'Money Supply Measures (M1, M2)',
          'Commercial Banking & Deposit Creation Multiplier',
          'The National Bank of Ethiopia (NBE) & Monetary Policy Tools',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 6,
        id: 'econ_u6',
        titleEn: 'Public Finance, Taxation and Fiscal Policy',
        titleAm: 'የህዝብ ፋይናንስ፣ ታክስ እና የፊስካል ፖሊሲ',
        sourceReference: 'MoE Grade 12 Economics Textbook',
        sourcePage: 'Unit 6, pp. 183-222',
        primaryTopics: [
          'Sources of Government Revenue (Direct & Indirect Taxes)',
          'Principles & Canons of Taxation',
          'Government Budget Deficits & National Debt',
          'Expansionary & Contractionary Fiscal Policies',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 7,
        id: 'econ_u7',
        titleEn: 'International Trade, Exchange Rates and Balance of Payments',
        titleAm: 'አለም አቀፍ ንግድ፣ የምንዛሪ ተመኖች እና የክፍያ ሚዛን',
        sourceReference: 'MoE Grade 12 Economics Textbook',
        sourcePage: 'Unit 7, pp. 223-264',
        primaryTopics: [
          'Absolute and Comparative Advantage (Smith & Ricardo)',
          'Trade Restrictions: Tariffs, Quotas, Subsidies',
          'Foreign Exchange Market & Exchange Rate Regimes',
          'Structure of Balance of Payments (Current & Capital Accounts)',
        ],
      ),
      ExpectedUnitOrDomain(
        index: 8,
        id: 'econ_u8',
        titleEn:
            'Economic Growth, Economic Development & Ethiopian Development Policies',
        titleAm: 'የኢኮኖሚ እድገት፣ ልማት እና የኢትዮጵያ የልማት ፖሊሲዎች',
        sourceReference: 'MoE Grade 12 Economics Textbook',
        sourcePage: 'Unit 8, pp. 265-312',
        primaryTopics: [
          'Differentiating Growth from Sustainable Development',
          'Development Indicators: HDI, Poverty Indices, Gini Coefficient',
          'Historical & Contemporary Ethiopian Economic Frameworks',
          'Industrialization, Agricultural Modernization & Growth Strategies',
        ],
      ),
    ],
  );

  // 11. Civics and Ethical Education (Supplementary Content - 11 Units)
  static const SubjectManifest civicsSupplementary = SubjectManifest(
    manifestId: 'manifest_civics_g12',
    canonicalSubjectId: 'civics_g12',
    variantCode: ExamVariantCode.shared,
    title: 'Grade 12 Civics and Ethical Education (Supplementary Syllabus)',
    sourceAuthority: 'FDRE Ministry of Education',
    sourceDocumentTitle:
        'Grade 12 Civics and Ethical Education Student Textbook',
    sourceDocumentId: 'MOE-ESSLCE-G12-CIV-2015',
    sourceReference:
        'FDRE Ministry of Education Grade 12 Civics Student Textbook (11 Units)',
    sourceUrlOrReference: 'https://moe.gov.et/curriculum/grade-12/civics',
    curriculumVersion: 'current_grade12',
    verifiedAt: '2024-08-15',
    verifiedBy: 'MoE National Curriculum Review Committee',
    verificationStatus: ManifestVerificationStatus.confirmed,
    assessmentStructure: AssessmentStructure.curriculum,
    scope: SubjectScope.curriculumOnly,
    isSupplementary: true,
    targetPastExamYears: defaultTargetYears,
    expectedUnitsOrDomains: [
      ExpectedUnitOrDomain(
        index: 1,
        id: 'civ_u1',
        titleEn: 'Building a Democratic System',
        titleAm: 'ዲሞክራሲያዊ ስርዓት መገንባት',
        sourceReference: 'MoE Grade 12 Civics Textbook',
        sourcePage: 'Unit 1, pp. 1-22',
      ),
      ExpectedUnitOrDomain(
        index: 2,
        id: 'civ_u2',
        titleEn: 'Rule of Law',
        titleAm: 'የህግ የበላይነት',
        sourceReference: 'MoE Grade 12 Civics Textbook',
        sourcePage: 'Unit 2, pp. 23-44',
      ),
      ExpectedUnitOrDomain(
        index: 3,
        id: 'civ_u3',
        titleEn: 'Equality',
        titleAm: 'እኩልነት',
        sourceReference: 'MoE Grade 12 Civics Textbook',
        sourcePage: 'Unit 3, pp. 45-66',
      ),
      ExpectedUnitOrDomain(
        index: 4,
        id: 'civ_u4',
        titleEn: 'Justice',
        titleAm: 'ፍትህ',
        sourceReference: 'MoE Grade 12 Civics Textbook',
        sourcePage: 'Unit 4, pp. 67-88',
      ),
      ExpectedUnitOrDomain(
        index: 5,
        id: 'civ_u5',
        titleEn: 'Patriotism',
        titleAm: 'ሀገር ወዳድነት',
        sourceReference: 'MoE Grade 12 Civics Textbook',
        sourcePage: 'Unit 5, pp. 89-110',
      ),
      ExpectedUnitOrDomain(
        index: 6,
        id: 'civ_u6',
        titleEn: 'Responsibility',
        titleAm: 'ኃላፊነት',
        sourceReference: 'MoE Grade 12 Civics Textbook',
        sourcePage: 'Unit 6, pp. 111-132',
      ),
      ExpectedUnitOrDomain(
        index: 7,
        id: 'civ_u7',
        titleEn: 'Industriousness',
        titleAm: 'ታታሪነት',
        sourceReference: 'MoE Grade 12 Civics Textbook',
        sourcePage: 'Unit 7, pp. 133-154',
      ),
      ExpectedUnitOrDomain(
        index: 8,
        id: 'civ_u8',
        titleEn: 'Self-Reliance',
        titleAm: 'በራስ መተማመን',
        sourceReference: 'MoE Grade 12 Civics Textbook',
        sourcePage: 'Unit 8, pp. 155-176',
      ),
      ExpectedUnitOrDomain(
        index: 9,
        id: 'civ_u9',
        titleEn: 'Saving',
        titleAm: 'ቁጠባ',
        sourceReference: 'MoE Grade 12 Civics Textbook',
        sourcePage: 'Unit 9, pp. 177-198',
      ),
      ExpectedUnitOrDomain(
        index: 10,
        id: 'civ_u10',
        titleEn: 'Active Community Participation',
        titleAm: 'ንቁ የህብረተሰብ ተሳትፎ',
        sourceReference: 'MoE Grade 12 Civics Textbook',
        sourcePage: 'Unit 10, pp. 199-220',
      ),
      ExpectedUnitOrDomain(
        index: 11,
        id: 'civ_u11',
        titleEn: 'The Pursuit of Wisdom',
        titleAm: 'ጥበብን መሻት',
        sourceReference: 'MoE Grade 12 Civics Textbook',
        sourcePage: 'Unit 11, pp. 221-246',
      ),
    ],
  );

  /// All 10 primary entrance exam manifests.
  static const List<SubjectManifest> primaryLaunchManifests = [
    english,
    mathNatural,
    mathSocial,
    scholasticAptitude,
    physics,
    chemistry,
    biology,
    history,
    geography,
    economics,
  ];

  /// All manifests including supplementary.
  static const List<SubjectManifest> allManifests = [
    ...primaryLaunchManifests,
    civicsSupplementary,
  ];

  /// Resolves manifest by subject ID and optional variant code.
  static SubjectManifest? findManifest(
    String subjectId, {
    ExamVariantCode? variantCode,
    String? stream,
  }) {
    final lowerId = subjectId.toLowerCase();

    // Check Mathematics
    if (lowerId.contains('math')) {
      if (variantCode == ExamVariantCode.socialScience ||
          lowerId.contains('soc') ||
          stream == 'social') {
        return mathSocial;
      }
      return mathNatural;
    }

    if (lowerId.contains('eng')) return english;
    if (lowerId.contains('apt')) return scholasticAptitude;
    if (lowerId.contains('phys')) return physics;
    if (lowerId.contains('chem')) return chemistry;
    if (lowerId.contains('bio')) return biology;
    if (lowerId.contains('hist')) return history;
    if (lowerId.contains('geo')) return geography;
    if (lowerId.contains('econ')) return economics;
    if (lowerId.contains('civ')) return civicsSupplementary;

    return null;
  }
}
