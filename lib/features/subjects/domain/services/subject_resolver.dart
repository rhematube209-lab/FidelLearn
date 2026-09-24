import '../models/subject_models.dart';

/// Canonical resolver for eligible subjects and assessment tracks in FidelLearn.
/// Aligns with the frozen P0 Grade 12 Launch Curriculum Specification.
class SubjectResolver {
  SubjectResolver._();

  /// Resolves the primary assessment tracks that a student is eligible to take.
  ///
  /// For Grade 12:
  /// - Natural Science: English (Shared), Mathematics (Natural Science), Scholastic Aptitude (Shared),
  ///   Physics (Natural Science), Chemistry (Natural Science), Biology (Natural Science).
  /// - Social Science: English (Shared), Mathematics (Social Science), Scholastic Aptitude (Shared),
  ///   History (Social Science), Geography (Social Science), Economics (Social Science).
  ///
  /// Supplementary (Civics) is excluded by default from the primary national-exam plan.
  static List<SubjectExamVariant> resolveEligibleTracks({
    required int grade,
    required String stream,
    bool includeSupplementary = false,
  }) {
    final normStream = stream.trim().toLowerCase();
    final isSocial = normStream == 'social' || normStream == 'social_science';

    final List<SubjectExamVariant> tracks = [];

    // 1. English — Common Exam (Mixed Assessment Structure)
    tracks.add(
      SubjectExamVariant(
        variantId: 'english_g${grade}_shared',
        subjectId: 'english_g$grade',
        variantCode: ExamVariantCode.shared,
        nameEn: 'English',
        nameAm: 'እንግሊዝኛ',
        streamEligibility: 'common',
        assessmentStructure: AssessmentStructure.mixed,
        packageId: 'pkg_g${grade}_english_2026',
        manifestId: 'manifest_english_g$grade',
      ),
    );

    // 2. Mathematics — Track Specific Variant (Curriculum Assessment Structure)
    if (isSocial) {
      tracks.add(
        SubjectExamVariant(
          variantId: 'math_g${grade}_social',
          subjectId: 'math_g$grade',
          variantCode: ExamVariantCode.socialScience,
          nameEn: 'Mathematics (Social Science)',
          nameAm: 'ሒሳብ (የማህበራዊ ሳይንስ)',
          streamEligibility: 'social',
          assessmentStructure: AssessmentStructure.curriculum,
          packageId: 'pkg_g${grade}_math_soc_2026',
          manifestId: 'manifest_math_social_g$grade',
        ),
      );
    } else {
      tracks.add(
        SubjectExamVariant(
          variantId: 'math_g${grade}_natural',
          subjectId: 'math_g$grade',
          variantCode: ExamVariantCode.naturalScience,
          nameEn: 'Mathematics (Natural Science)',
          nameAm: 'ሒሳብ (የተፈጥሮ ሳይንስ)',
          streamEligibility: 'natural',
          assessmentStructure: AssessmentStructure.curriculum,
          packageId: 'pkg_g${grade}_math_nat_2026',
          manifestId: 'manifest_math_natural_g$grade',
        ),
      );
    }

    // 3. Scholastic Aptitude — Common Exam (Skill-Based Assessment Structure)
    tracks.add(
      SubjectExamVariant(
        variantId: 'aptitude_g${grade}_shared',
        subjectId: 'aptitude_g$grade',
        variantCode: ExamVariantCode.shared,
        nameEn: 'Scholastic Aptitude',
        nameAm: 'የተፈጥሮ ተሰጥኦ (አፕቲትዩድ)',
        streamEligibility: 'common',
        assessmentStructure: AssessmentStructure.skillBased,
        packageId: 'pkg_g${grade}_aptitude_2026',
        manifestId: 'manifest_aptitude_g$grade',
      ),
    );

    // 4. Stream-Specific Assessment Papers
    if (isSocial) {
      tracks.addAll([
        SubjectExamVariant(
          variantId: 'history_g${grade}_social',
          subjectId: 'history_g$grade',
          variantCode: ExamVariantCode.socialScience,
          nameEn: 'History',
          nameAm: 'ታሪክ',
          streamEligibility: 'social',
          assessmentStructure: AssessmentStructure.curriculum,
          packageId: 'pkg_g${grade}_history_2026',
          manifestId: 'manifest_history_g$grade',
        ),
        SubjectExamVariant(
          variantId: 'geography_g${grade}_social',
          subjectId: 'geography_g$grade',
          variantCode: ExamVariantCode.socialScience,
          nameEn: 'Geography',
          nameAm: 'ጂኦግራፊ',
          streamEligibility: 'social',
          assessmentStructure: AssessmentStructure.curriculum,
          packageId: 'pkg_g${grade}_geography_2026',
          manifestId: 'manifest_geography_g$grade',
        ),
        SubjectExamVariant(
          variantId: 'economics_g${grade}_social',
          subjectId: 'economics_g$grade',
          variantCode: ExamVariantCode.socialScience,
          nameEn: 'Economics',
          nameAm: 'ኢኮኖሚክስ',
          streamEligibility: 'social',
          assessmentStructure: AssessmentStructure.curriculum,
          packageId: 'pkg_g${grade}_economics_2026',
          manifestId: 'manifest_economics_g$grade',
        ),
      ]);
    } else {
      tracks.addAll([
        SubjectExamVariant(
          variantId: 'physics_g${grade}_natural',
          subjectId: 'physics_g$grade',
          variantCode: ExamVariantCode.naturalScience,
          nameEn: 'Physics',
          nameAm: 'ፊዚክስ',
          streamEligibility: 'natural',
          assessmentStructure: AssessmentStructure.curriculum,
          packageId: 'pkg_g${grade}_physics_2026',
          manifestId: 'manifest_physics_g$grade',
        ),
        SubjectExamVariant(
          variantId: 'chemistry_g${grade}_natural',
          subjectId: 'chemistry_g$grade',
          variantCode: ExamVariantCode.naturalScience,
          nameEn: 'Chemistry',
          nameAm: 'ኬሚስትሪ',
          streamEligibility: 'natural',
          assessmentStructure: AssessmentStructure.curriculum,
          packageId: 'pkg_g${grade}_chem_2026',
          manifestId: 'manifest_chemistry_g$grade',
        ),
        SubjectExamVariant(
          variantId: 'biology_g${grade}_natural',
          subjectId: 'biology_g$grade',
          variantCode: ExamVariantCode.naturalScience,
          nameEn: 'Biology',
          nameAm: 'ባዮሎጂ',
          streamEligibility: 'natural',
          assessmentStructure: AssessmentStructure.curriculum,
          packageId: 'pkg_g${grade}_bio_2026',
          manifestId: 'manifest_biology_g$grade',
        ),
      ]);
    }

    // 5. Supplementary Curriculum Track (Civics)
    if (includeSupplementary) {
      tracks.add(
        SubjectExamVariant(
          variantId: 'civics_g${grade}_supplementary',
          subjectId: 'civics_g$grade',
          variantCode: ExamVariantCode.shared,
          nameEn: 'Civics and Ethical Education',
          nameAm: 'ስነ-ዜጋና ስነ-ምግባር',
          streamEligibility: 'common',
          assessmentStructure: AssessmentStructure.curriculum,
          packageId: 'pkg_g${grade}_civics_2026',
          manifestId: 'manifest_civics_g$grade',
        ),
      );
    }

    return tracks;
  }

  /// Resolves the primary Subjects list for a student, incorporating the correct exam variant.
  static List<Subject> resolveSubjectsForStudent({
    required int grade,
    required String stream,
    bool includeSupplementary = false,
  }) {
    final tracks = resolveEligibleTracks(
      grade: grade,
      stream: stream,
      includeSupplementary: includeSupplementary,
    );

    int order = 1;
    return tracks.map((track) {
      final isCommon = track.streamEligibility == 'common';
      final isSupplementary = track.subjectId.contains('civics');

      return Subject(
        id: track.subjectId,
        code: _subjectCodeFor(track.subjectId, grade),
        nameEn: track.nameEn,
        nameAm: track.nameAm,
        grade: grade,
        stream: isCommon
            ? 'common'
            : (stream.toLowerCase().contains('social') ? 'social' : 'natural'),
        scope: isSupplementary
            ? SubjectScope.curriculumOnly
            : (isCommon ? SubjectScope.commonExam : SubjectScope.streamExam),
        assessmentStructure: track.assessmentStructure,
        availableVariants: [track],
        sortOrder: order++,
      );
    }).toList();
  }

  static String _subjectCodeFor(String subjectId, int grade) {
    final lower = subjectId.toLowerCase();
    if (lower.contains('math')) return 'MATH$grade';
    if (lower.contains('eng')) return 'ENG$grade';
    if (lower.contains('apt')) return 'APT$grade';
    if (lower.contains('phys')) return 'PHYS$grade';
    if (lower.contains('chem')) return 'CHEM$grade';
    if (lower.contains('bio')) return 'BIO$grade';
    if (lower.contains('hist')) return 'HIST$grade';
    if (lower.contains('geo')) return 'GEO$grade';
    if (lower.contains('econ')) return 'ECON$grade';
    if (lower.contains('civ')) return 'CIV$grade';
    return 'SUBJ$grade';
  }
}
