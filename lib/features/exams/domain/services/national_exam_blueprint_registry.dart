import '../../../subjects/domain/models/subject_models.dart';
import '../models/exam_mode.dart';

/// Registry of canonical Grade 12 National Exam blueprints for Natural & Social Science tracks
class NationalExamBlueprintRegistry {
  NationalExamBlueprintRegistry._();

  /// Gets the authoritative blueprint for a given subject and exam variant
  static NationalExamBlueprint? getBlueprint({
    required String subjectId,
    required ExamVariantCode examVariant,
    int? customQuestionCount,
    int? customTimeMinutes,
  }) {
    final lowerId = subjectId.toLowerCase().trim();

    // 1. Mathematics (Natural Science)
    if (lowerId.contains('math') &&
        examVariant == ExamVariantCode.naturalScience) {
      final totalQ = customQuestionCount ?? 60;
      final timeM = customTimeMinutes ?? 120;
      return NationalExamBlueprint(
        blueprintVersion: 'esslce_sim_math_nat_v1',
        subjectId: 'math_g12',
        examVariant: ExamVariantCode.naturalScience,
        totalQuestions: totalQ,
        timeLimitMinutes: timeM,
        partitions: const [
          BlueprintPartition(
            nameEn: 'Analysis and Calculus',
            nameAm: 'አናሊሲስና ካልኩለስ',
            requiredCount: 20,
            unitIds: [
              'math_nat_u3',
              'math_nat_u4',
              'math_g12_u2',
              'math_g12_u3'
            ],
          ),
          BlueprintPartition(
            nameEn: 'Vectors and Coordinate Geometry',
            nameAm: 'ቬክተሮችና ኮኦርዲኔት ጂኦሜትሪ',
            requiredCount: 15,
            unitIds: ['math_nat_u1', 'math_nat_u2', 'math_g12_u1'],
          ),
          BlueprintPartition(
            nameEn: 'Matrices, Determinants & Systems',
            nameAm: 'ማትሪክስ፣ ዲተርሚናንትና ስርዓተ-እኩልታዎች',
            requiredCount: 12,
            unitIds: ['math_nat_u5', 'math_g11_u1'],
          ),
          BlueprintPartition(
            nameEn: 'Algebra, Sequences and Series',
            nameAm: 'አልጀብራ፣ ሲክዌንስና ሲሪስ',
            requiredCount: 13,
            unitIds: ['math_nat_u6', 'math_g11_u2', 'math_g12_u4'],
          ),
        ],
        sections: const [
          ExamSection(
            id: 'sec_math_nat_a',
            titleEn: 'Section A: Pure Mathematics & Calculus',
            titleAm: 'ክፍል ሀ፦ ንፁህ ሒሳብና ካልኩለስ',
            startIndex: 0,
            questionCount: 30,
          ),
          ExamSection(
            id: 'sec_math_nat_b',
            titleEn: 'Section B: Vectors, Geometry & Applications',
            titleAm: 'ክፍል ለ፦ ቬክተሮች፣ ጂኦሜትሪና ተግባራዊ ሒሳብ',
            startIndex: 30,
            questionCount: 30,
          ),
        ],
      );
    }

    // 2. Mathematics (Social Science)
    if (lowerId.contains('math') &&
        examVariant == ExamVariantCode.socialScience) {
      final totalQ = customQuestionCount ?? 60;
      final timeM = customTimeMinutes ?? 120;
      return NationalExamBlueprint(
        blueprintVersion: 'esslce_sim_math_soc_v1',
        subjectId: 'math_g12',
        examVariant: ExamVariantCode.socialScience,
        totalQuestions: totalQ,
        timeLimitMinutes: timeM,
        partitions: const [
          BlueprintPartition(
            nameEn: 'Statistics and Probability',
            nameAm: 'ስታቲስቲክስና ፕሮባቢሊቲ',
            requiredCount: 18,
            unitIds: ['math_soc_u1', 'math_soc_u2'],
          ),
          BlueprintPartition(
            nameEn: 'Matrices and Linear Programming',
            nameAm: 'ማትሪክስና ሊኒየር ፕሮግራሚንግ',
            requiredCount: 16,
            unitIds: ['math_soc_u3', 'math_soc_u4'],
          ),
          BlueprintPartition(
            nameEn: 'Business Mathematics & Financial Functions',
            nameAm: 'የቢዝነስና ፋይናንስ ሒሳብ',
            requiredCount: 14,
            unitIds: ['math_soc_u5'],
          ),
          BlueprintPartition(
            nameEn: 'Consumer Math & Basic Algebra',
            nameAm: 'የተጠቃሚዎች ሒሳብና አልጀብራ',
            requiredCount: 12,
            unitIds: ['math_soc_u6'],
          ),
        ],
        sections: const [
          ExamSection(
            id: 'sec_math_soc_a',
            titleEn: 'Section A: Applied Business Mathematics',
            titleAm: 'ክፍል ሀ፦ ተግባራዊ የቢዝነስ ሒሳብ',
            startIndex: 0,
            questionCount: 30,
          ),
          ExamSection(
            id: 'sec_math_soc_b',
            titleEn: 'Section B: Statistics & Decision Sciences',
            titleAm: 'ክፍል ለ፦ ስታቲስቲክስና የውሳኔ ሳይንስ',
            startIndex: 30,
            questionCount: 30,
          ),
        ],
      );
    }

    // 3. Physics (Natural Science)
    if (lowerId.contains('phys')) {
      final totalQ = customQuestionCount ?? 60;
      final timeM = customTimeMinutes ?? 120;
      return NationalExamBlueprint(
        blueprintVersion: 'esslce_sim_phys_nat_v1',
        subjectId: 'physics_g12',
        examVariant: ExamVariantCode.naturalScience,
        totalQuestions: totalQ,
        timeLimitMinutes: timeM,
        partitions: const [
          BlueprintPartition(
            nameEn: 'Mechanics & Two-Dimensional Motion',
            nameAm: 'ሜካኒክስና ባለ ሁለት አቅጣጫ እንቅስቃሴ',
            requiredCount: 18,
            unitIds: ['phys_g11_u4', 'phys_g12_u2', 'phys_u1', 'phys_u2'],
          ),
          BlueprintPartition(
            nameEn: 'Electromagnetism and AC Circuits',
            nameAm: 'ኤሌክትሮማግኔቲዝምና ኤሲ ዑደቶች',
            requiredCount: 16,
            unitIds: ['phys_g11_u6', 'phys_g12_u4', 'phys_u4'],
          ),
          BlueprintPartition(
            nameEn: 'Optics and Wave Motion',
            nameAm: 'ኦፕቲክስና የሞገድ እንቅስቃሴ',
            requiredCount: 14,
            unitIds: ['phys_g10_u6', 'phys_u3'],
          ),
          BlueprintPartition(
            nameEn: 'Nuclear & Modern Physics',
            nameAm: 'ኒውክሌርና ዘመናዊ ፊዚክስ',
            requiredCount: 12,
            unitIds: ['phys_g11_u7', 'phys_g12_u5', 'phys_u5'],
          ),
        ],
      );
    }

    // 4. Chemistry (Natural Science)
    if (lowerId.contains('chem')) {
      final totalQ = customQuestionCount ?? 60;
      final timeM = customTimeMinutes ?? 120;
      return NationalExamBlueprint(
        blueprintVersion: 'esslce_sim_chem_nat_v1',
        subjectId: 'chemistry_g12',
        examVariant: ExamVariantCode.naturalScience,
        totalQuestions: totalQ,
        timeLimitMinutes: timeM,
        partitions: const [
          BlueprintPartition(
            nameEn: 'Atomic Structure & Chemical Bonding',
            nameAm: 'የአተም መዋቅርና ኬሚካላዊ ትስስር',
            requiredCount: 15,
            unitIds: ['chem_g9_u3', 'chem_g9_u4', 'chem_g9_u5', 'chem_u1'],
          ),
          BlueprintPartition(
            nameEn: 'Solutions and Chemical Kinetics',
            nameAm: 'መፍትሔዎችና ኬሚካላዊ እንቅስቃሴ',
            requiredCount: 15,
            unitIds: ['chem_g10_u2', 'chem_g12_u1', 'chem_u2'],
          ),
          BlueprintPartition(
            nameEn: 'Electrochemistry and Acid-Base Equilibria',
            nameAm: 'ኤሌክትሮኬሚስትሪና አሲድ-ቤዝ ሚዛን',
            requiredCount: 15,
            unitIds: ['chem_g12_u2', 'chem_u3'],
          ),
          BlueprintPartition(
            nameEn: 'Organic, Polymers and Environmental Chemistry',
            nameAm: 'ኦርጋኒክ ኬሚስትሪ፣ ፖሊመርና አካባቢ',
            requiredCount: 15,
            unitIds: ['chem_g12_u4', 'chem_g12_u5', 'chem_u4', 'chem_u5'],
          ),
        ],
      );
    }

    // 5. Biology (Natural Science)
    if (lowerId.contains('bio')) {
      final totalQ = customQuestionCount ?? 60;
      final timeM = customTimeMinutes ?? 120;
      return NationalExamBlueprint(
        blueprintVersion: 'esslce_sim_bio_nat_v1',
        subjectId: 'biology_g12',
        examVariant: ExamVariantCode.naturalScience,
        totalQuestions: totalQ,
        timeLimitMinutes: timeM,
        partitions: const [
          BlueprintPartition(
            nameEn: 'Biochemical Molecules & Cellular Physiology',
            nameAm: 'ባዮኬሚካል ሞለኪውሎችና የሴል ፊዚዮሎጂ',
            requiredCount: 16,
            unitIds: ['bio_u1', 'bio_u2'],
          ),
          BlueprintPartition(
            nameEn: 'Genetics, Molecular Biology & Inheritance',
            nameAm: 'ጄኔቲክስ፣ ሞለኪውላር ባዮሎጂና ውርስ',
            requiredCount: 16,
            unitIds: ['bio_u3'],
          ),
          BlueprintPartition(
            nameEn: 'Evolution, Human Health & Disease Control',
            nameAm: 'ዝግመተ-ለውጥ፣ የሰው ጤናና የበሽታ ቁጥጥር',
            requiredCount: 14,
            unitIds: ['bio_u4'],
          ),
          BlueprintPartition(
            nameEn: 'Ecology, Conservation & Biodiversity',
            nameAm: 'ኢኮሎጂ፣ ጥበቃና ብዝሃ-ሕይወት',
            requiredCount: 14,
            unitIds: ['bio_u5'],
          ),
        ],
      );
    }

    // 6. English (Shared across Natural & Social Science)
    if (lowerId.contains('eng')) {
      final totalQ = customQuestionCount ?? 60;
      final timeM = customTimeMinutes ?? 120;
      return NationalExamBlueprint(
        blueprintVersion: 'esslce_sim_eng_shared_v1',
        subjectId: 'english_g12',
        examVariant: ExamVariantCode.shared,
        totalQuestions: totalQ,
        timeLimitMinutes: timeM,
        partitions: const [
          BlueprintPartition(
            nameEn: 'Reading Comprehension & Critical Analysis',
            nameAm: 'የንባብ ግንዛቤና ትንተና',
            requiredCount: 18,
            contentDomain: 'Reading Comprehension',
            skill: 'criticalAnalysis',
          ),
          BlueprintPartition(
            nameEn: 'Grammar and Sentence Structure',
            nameAm: 'ሰዋሰውና የአረፍተ-ነገር መዋቅር',
            requiredCount: 22,
            contentDomain: 'Grammar',
            skill: 'sentenceCorrection',
          ),
          BlueprintPartition(
            nameEn: 'Contextual Vocabulary and Word Meaning',
            nameAm: 'አገባባዊ የቃላት አጠቃቀም',
            requiredCount: 20,
            contentDomain: 'Vocabulary',
            skill: 'contextualInference',
          ),
        ],
        sections: const [
          ExamSection(
            id: 'sec_eng_reading',
            titleEn: 'Section 1: Reading Comprehension',
            titleAm: 'ክፍል 1፦ የንባብ ግንዛቤ',
            startIndex: 0,
            questionCount: 18,
          ),
          ExamSection(
            id: 'sec_eng_grammar',
            titleEn: 'Section 2: Grammar & Structure',
            titleAm: 'ክፍል 2፦ ሰዋሰውና አገባብ',
            startIndex: 18,
            questionCount: 22,
          ),
          ExamSection(
            id: 'sec_eng_vocab',
            titleEn: 'Section 3: Vocabulary in Context',
            titleAm: 'ክፍል 3፦ አገባባዊ የቃላት አጠቃቀም',
            startIndex: 40,
            questionCount: 20,
          ),
        ],
      );
    }

    // 7. Scholastic Aptitude (Shared across Natural & Social Science)
    if (lowerId.contains('apt')) {
      final totalQ = customQuestionCount ?? 60;
      final timeM = customTimeMinutes ?? 120;
      return NationalExamBlueprint(
        blueprintVersion: 'esslce_sim_apt_shared_v1',
        subjectId: 'aptitude_g12',
        examVariant: ExamVariantCode.shared,
        totalQuestions: totalQ,
        timeLimitMinutes: timeM,
        partitions: const [
          BlueprintPartition(
            nameEn: 'Verbal Reasoning & Analogies',
            nameAm: 'ቃላዊ አመክንዮና ተመሳሳይነቶች',
            requiredCount: 20,
            contentDomain: 'Verbal Reasoning',
            skill: 'analogy',
          ),
          BlueprintPartition(
            nameEn: 'Quantitative Reasoning & Number Series',
            nameAm: 'መጠናዊ አመክንዮና የቁጥር ተከታታይነት',
            requiredCount: 20,
            contentDomain: 'Quantitative Reasoning',
            skill: 'numberSeries',
          ),
          BlueprintPartition(
            nameEn: 'Analytical Reasoning & Data Interpretation',
            nameAm: 'ትንተናዊ አመክንዮና የመረጃ ማብራሪያ',
            requiredCount: 20,
            contentDomain: 'Analytical Reasoning',
            skill: 'dataSufficiency',
          ),
        ],
        sections: const [
          ExamSection(
            id: 'sec_apt_verbal',
            titleEn: 'Part I: Verbal Reasoning',
            titleAm: 'ክፍል 1፦ ቃላዊ አመክንዮ',
            startIndex: 0,
            questionCount: 20,
          ),
          ExamSection(
            id: 'sec_apt_quant',
            titleEn: 'Part II: Quantitative Reasoning',
            titleAm: 'ክፍል 2፦ መጠናዊ አመክንዮ',
            startIndex: 20,
            questionCount: 20,
          ),
          ExamSection(
            id: 'sec_apt_analytical',
            titleEn: 'Part III: Analytical Reasoning & Data Interpretation',
            titleAm: 'ክፍል 3፦ ትንተናዊ አመክንዮና የመረጃ ትንተና',
            startIndex: 40,
            questionCount: 20,
          ),
        ],
      );
    }

    // 8. History (Social Science)
    if (lowerId.contains('hist')) {
      final totalQ = customQuestionCount ?? 60;
      final timeM = customTimeMinutes ?? 120;
      return NationalExamBlueprint(
        blueprintVersion: 'esslce_sim_hist_soc_v1',
        subjectId: 'history_g12',
        examVariant: ExamVariantCode.socialScience,
        totalQuestions: totalQ,
        timeLimitMinutes: timeM,
        partitions: const [
          BlueprintPartition(
            nameEn: 'Ethiopian State Formation & Sovereignty',
            nameAm: 'የኢትዮጵያ ሀገር ግንባታና ሉዓላዊነት',
            requiredCount: 20,
            unitIds: ['hist_u1', 'hist_u3'],
          ),
          BlueprintPartition(
            nameEn: 'The Horn of Africa and Modernization',
            nameAm: 'የአፍሪካ ቀንድና ዘመናዊነት',
            requiredCount: 20,
            unitIds: ['hist_u2', 'hist_u4'],
          ),
          BlueprintPartition(
            nameEn: 'Contemporary Ethiopia and Global Relations',
            nameAm: 'ወቅታዊቷ ኢትዮጵያና ዓለም አቀፍ ግንኙነቶች',
            requiredCount: 20,
            unitIds: ['hist_u5'],
          ),
        ],
      );
    }

    // 9. Geography (Social Science)
    if (lowerId.contains('geo')) {
      final totalQ = customQuestionCount ?? 60;
      final timeM = customTimeMinutes ?? 120;
      return NationalExamBlueprint(
        blueprintVersion: 'esslce_sim_geo_soc_v1',
        subjectId: 'geography_g12',
        examVariant: ExamVariantCode.socialScience,
        totalQuestions: totalQ,
        timeLimitMinutes: timeM,
        partitions: const [
          BlueprintPartition(
            nameEn: 'Geology & Physical Landscapes of Ethiopia',
            nameAm: 'የኢትዮጵያ ጂኦሎጂና መልክአ-ምድር',
            requiredCount: 20,
            unitIds: ['geo_u1', 'geo_u2'],
          ),
          BlueprintPartition(
            nameEn: 'Climate, Natural Resources and Ecosystems',
            nameAm: 'አየር ንብረት፣ የተፈጥሮ ሃብትና ስነ-ምህዳር',
            requiredCount: 20,
            unitIds: ['geo_u3'],
          ),
          BlueprintPartition(
            nameEn: 'Population, Urbanization and Economic Activities',
            nameAm: 'የህዝብ ቁጥር፣ ከተማ መስፋፋትና ኢኮኖሚያዊ እንቅስቃሴ',
            requiredCount: 20,
            unitIds: ['geo_u4'],
          ),
        ],
      );
    }

    // 10. Economics (Social Science)
    if (lowerId.contains('econ')) {
      final totalQ = customQuestionCount ?? 60;
      final timeM = customTimeMinutes ?? 120;
      return NationalExamBlueprint(
        blueprintVersion: 'esslce_sim_econ_soc_v1',
        subjectId: 'economics_g12',
        examVariant: ExamVariantCode.socialScience,
        totalQuestions: totalQ,
        timeLimitMinutes: timeM,
        partitions: const [
          BlueprintPartition(
            nameEn: 'Microeconomics & Market Mechanisms',
            nameAm: 'ማይክሮ ኢኮኖሚና የገበያ ስርዓቶች',
            requiredCount: 20,
            unitIds: ['econ_u1', 'econ_u2'],
          ),
          BlueprintPartition(
            nameEn: 'Macroeconomic Principles and National Income',
            nameAm: 'የማክሮ ኢኮኖሚ መርሆዎችና ሀገራዊ ገቢ',
            requiredCount: 20,
            unitIds: ['econ_u3'],
          ),
          BlueprintPartition(
            nameEn: 'Monetary, Fiscal Policy and Ethiopian Economy',
            nameAm: 'የገንዘብ፣ የበጀት ፖሊሲና የኢትዮጵያ ኢኮኖሚ',
            requiredCount: 20,
            unitIds: ['econ_u4'],
          ),
        ],
      );
    }

    return null;
  }
}
