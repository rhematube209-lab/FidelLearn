import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:equatable/equatable.dart';

import '../models/question_models.dart';
import '../../../subjects/domain/models/subject_models.dart';
import '../../../subjects/domain/models/subject_manifest.dart';

enum ValidationSeverity { error, warning, info }

enum ValidationIssueType {
  missingAnswerKey,
  duplicateId,
  exactDuplicateQuestion,
  nearDuplicateQuestion,
  invalidAnswerChoices,
  missingCurriculumMapping,
  missingSubject,
  invalidStreamAssignment,
  missingSourceMetadata,
  brokenDiagramReference,
  emptyExplanation,
  unverifiedPublished,
  orphanCurriculumUnit,
  // Manifest Source Evidence Validation
  missingManifestSourceAuthority,
  missingManifestSourceReference,
  missingManifestCurriculumVersion,
  unverifiedConfirmedManifest,
  duplicateManifestId,
  conflictingCurriculumVersions,
  unverifiedManifestUsedForCoverage,
}

class ValidationIssue extends Equatable {
  final String? questionId;
  final ValidationIssueType issueType;
  final ValidationSeverity severity;
  final String description;
  final String? subjectId;

  const ValidationIssue({
    this.questionId,
    required this.issueType,
    required this.severity,
    required this.description,
    this.subjectId,
  });

  @override
  List<Object?> get props => [
        questionId,
        issueType,
        severity,
        description,
        subjectId,
      ];
}

class DuplicateGroup extends Equatable {
  final String normalizedHash;
  final String canonicalText;
  final List<String> questionIds;

  const DuplicateGroup({
    required this.normalizedHash,
    required this.canonicalText,
    required this.questionIds,
  });

  @override
  List<Object?> get props => [normalizedHash, canonicalText, questionIds];
}

class NearDuplicateMatch extends Equatable {
  final String questionId1;
  final String questionId2;
  final double similarityScore; // 0.0 to 1.0
  final String text1;
  final String text2;

  const NearDuplicateMatch({
    required this.questionId1,
    required this.questionId2,
    required this.similarityScore,
    required this.text1,
    required this.text2,
  });

  @override
  List<Object?> get props => [questionId1, questionId2, similarityScore];
}

class ValidationReport extends Equatable {
  final int totalQuestionsAnalyzed;
  final List<ValidationIssue> issues;
  final List<DuplicateGroup> exactDuplicates;
  final List<NearDuplicateMatch> nearDuplicates;

  const ValidationReport({
    required this.totalQuestionsAnalyzed,
    required this.issues,
    required this.exactDuplicates,
    required this.nearDuplicates,
  });

  int get errorCount =>
      issues.where((i) => i.severity == ValidationSeverity.error).length;

  int get warningCount =>
      issues.where((i) => i.severity == ValidationSeverity.warning).length;

  bool get isClean => errorCount == 0 && exactDuplicates.isEmpty;

  @override
  List<Object?> get props => [
        totalQuestionsAnalyzed,
        issues,
        exactDuplicates,
        nearDuplicates,
      ];
}

/// Automated Content Quality & Duplicate Detection Service.
class ContentValidationService {
  /// Normalizes question text for consistent hashing & comparison.
  static String normalizeText(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Calculates text hash using SHA-256 over normalized text.
  static String hashNormalizedText(String input) {
    final normalized = normalizeText(input);
    final bytes = utf8.encode(normalized);
    return sha256.convert(bytes).toString();
  }

  /// Computes word-level Jaccard similarity coefficient between two strings (0.0 to 1.0).
  static double computeJaccardSimilarity(String textA, String textB) {
    final wordsA =
        normalizeText(textA).split(' ').where((w) => w.length > 2).toSet();
    final wordsB =
        normalizeText(textB).split(' ').where((w) => w.length > 2).toSet();

    if (wordsA.isEmpty || wordsB.isEmpty) return 0.0;

    final intersection = wordsA.intersection(wordsB).length;
    final union = wordsA.union(wordsB).length;

    return union == 0 ? 0.0 : intersection / union;
  }

  /// Detects exact duplicate questions using normalized text hashing.
  List<DuplicateGroup> detectExactDuplicates(List<Question> questions) {
    final Map<String, List<Question>> hashMap = {};

    for (final q in questions) {
      final h = hashNormalizedText(q.questionTextEn);
      hashMap.putIfAbsent(h, () => []).add(q);
    }

    final List<DuplicateGroup> duplicates = [];
    for (final entry in hashMap.entries) {
      if (entry.value.length > 1) {
        duplicates.add(DuplicateGroup(
          normalizedHash: entry.key,
          canonicalText: entry.value.first.questionTextEn,
          questionIds: entry.value.map((q) => q.id).toList(),
        ));
      }
    }

    return duplicates;
  }

  /// Detects near-duplicate questions within the same subject.
  List<NearDuplicateMatch> detectNearDuplicates(
    List<Question> questions, {
    double threshold = 0.80,
  }) {
    final List<NearDuplicateMatch> matches = [];

    // Group by subject to keep pairwise comparison performant
    final Map<String, List<Question>> bySubject = {};
    for (final q in questions) {
      bySubject.putIfAbsent(q.subjectId, () => []).add(q);
    }

    for (final subjectQuestions in bySubject.values) {
      final n = subjectQuestions.length;
      for (int i = 0; i < n; i++) {
        for (int j = i + 1; j < n; j++) {
          final q1 = subjectQuestions[i];
          final q2 = subjectQuestions[j];

          // Skip if exact duplicate (handled by detectExactDuplicates)
          if (hashNormalizedText(q1.questionTextEn) ==
              hashNormalizedText(q2.questionTextEn)) {
            continue;
          }

          final sim =
              computeJaccardSimilarity(q1.questionTextEn, q2.questionTextEn);
          if (sim >= threshold) {
            matches.add(NearDuplicateMatch(
              questionId1: q1.id,
              questionId2: q2.id,
              similarityScore: sim,
              text1: q1.questionTextEn,
              text2: q2.questionTextEn,
            ));
          }
        }
      }
    }

    return matches;
  }

  /// Validates official curriculum manifests for source authority, references, and verification integrity.
  static List<ValidationIssue> validateCurriculumManifests(
      List<SubjectManifest> manifests) {
    final List<ValidationIssue> issues = [];
    final Set<String> seenIds = {};
    final Map<String, String> versionsBySubject = {};

    for (final m in manifests) {
      // 1. Duplicate Manifest IDs
      if (!seenIds.add(m.manifestId)) {
        issues.add(ValidationIssue(
          issueType: ValidationIssueType.duplicateManifestId,
          severity: ValidationSeverity.error,
          description: 'Duplicate manifest ID encountered: "${m.manifestId}"',
          subjectId: m.canonicalSubjectId,
        ));
      }

      // 2. Missing Source Authority
      if (m.sourceAuthority.trim().isEmpty) {
        issues.add(ValidationIssue(
          issueType: ValidationIssueType.missingManifestSourceAuthority,
          severity: ValidationSeverity.error,
          description:
              'Manifest "${m.manifestId}" is missing source authority.',
          subjectId: m.canonicalSubjectId,
        ));
      }

      // 3. Missing Source Reference
      if (m.sourceReference.trim().isEmpty) {
        issues.add(ValidationIssue(
          issueType: ValidationIssueType.missingManifestSourceReference,
          severity: ValidationSeverity.error,
          description:
              'Manifest "${m.manifestId}" is missing authoritative source reference citation.',
          subjectId: m.canonicalSubjectId,
        ));
      }

      // 4. Missing Curriculum Version
      if (m.curriculumVersion.trim().isEmpty) {
        issues.add(ValidationIssue(
          issueType: ValidationIssueType.missingManifestCurriculumVersion,
          severity: ValidationSeverity.error,
          description:
              'Manifest "${m.manifestId}" is missing curriculum version.',
          subjectId: m.canonicalSubjectId,
        ));
      }

      // 5. Confirmed manifest without verification metadata
      if (m.verificationStatus == ManifestVerificationStatus.confirmed) {
        if (m.verifiedAt == null ||
            m.verifiedAt!.trim().isEmpty ||
            m.verifiedBy == null ||
            m.verifiedBy!.trim().isEmpty) {
          issues.add(ValidationIssue(
            issueType: ValidationIssueType.unverifiedConfirmedManifest,
            severity: ValidationSeverity.error,
            description:
                'Manifest "${m.manifestId}" marked CONFIRMED without complete verification metadata (verifiedAt or verifiedBy missing).',
            subjectId: m.canonicalSubjectId,
          ));
        }
      }

      // 6. Conflicting curriculum versions for same canonical subject
      if (versionsBySubject.containsKey(m.canonicalSubjectId)) {
        final existingVersion = versionsBySubject[m.canonicalSubjectId]!;
        if (existingVersion != m.curriculumVersion) {
          issues.add(ValidationIssue(
            issueType: ValidationIssueType.conflictingCurriculumVersions,
            severity: ValidationSeverity.error,
            description:
                'Conflicting curriculum versions for subject "${m.canonicalSubjectId}": "$existingVersion" vs "${m.curriculumVersion}".',
            subjectId: m.canonicalSubjectId,
          ));
        }
      } else {
        versionsBySubject[m.canonicalSubjectId] = m.curriculumVersion;
      }
    }

    return issues;
  }

  /// Performs full quality and schema validation on the question bank.
  ValidationReport validateQuestionBank({
    required List<Question> questions,
    List<Subject>? subjects,
    List<Unit>? units,
    List<Topic>? topics,
    List<SubjectManifest>? manifests,
  }) {
    final List<ValidationIssue> issues = [];
    final Set<String> seenIds = {};
    final validSubjectIds = subjects?.map((s) => s.id).toSet() ?? {};
    final validUnitIds = units?.map((u) => u.id).toSet() ?? {};
    final validTopicIds = topics?.map((t) => t.id).toSet() ?? {};

    // Validate manifests if provided
    if (manifests != null) {
      issues.addAll(validateCurriculumManifests(manifests));
    }

    for (final q in questions) {
      // 1. Duplicate ID Check
      if (!seenIds.add(q.id)) {
        issues.add(ValidationIssue(
          questionId: q.id,
          issueType: ValidationIssueType.duplicateId,
          severity: ValidationSeverity.error,
          description: 'Duplicate question ID encountered: "${q.id}"',
          subjectId: q.subjectId,
        ));
      }

      // 2. Missing Answer Key / Choice Validation
      final correctChoices = q.choices.where((c) => c.isCorrect).toList();
      if (correctChoices.isEmpty) {
        issues.add(ValidationIssue(
          questionId: q.id,
          issueType: ValidationIssueType.missingAnswerKey,
          severity: ValidationSeverity.error,
          description: 'Question has NO correct answer designated.',
          subjectId: q.subjectId,
        ));
      }

      // 3. Minimum Answer Choices (standard Ethiopian national exam requires 4 options: A, B, C, D)
      if (q.choices.length < 2) {
        issues.add(ValidationIssue(
          questionId: q.id,
          issueType: ValidationIssueType.invalidAnswerChoices,
          severity: ValidationSeverity.error,
          description:
              'Question has fewer than 2 choices (${q.choices.length}).',
          subjectId: q.subjectId,
        ));
      }

      // 4. Empty Explanation Validation
      if (q.explanation.solutionTextEn.trim().isEmpty ||
          q.explanation.solutionTextEn == 'No explanation available.') {
        issues.add(ValidationIssue(
          questionId: q.id,
          issueType: ValidationIssueType.emptyExplanation,
          severity: ValidationSeverity.warning,
          description: 'Question is missing a detailed step-by-step rationale.',
          subjectId: q.subjectId,
        ));
      }

      // 5. Published Without Verification Check
      if (q.verificationStatus == VerificationStatus.published) {
        if (q.questionTextEn.trim().isEmpty) {
          issues.add(ValidationIssue(
            questionId: q.id,
            issueType: ValidationIssueType.unverifiedPublished,
            severity: ValidationSeverity.error,
            description: 'Question marked Published but statement is empty.',
            subjectId: q.subjectId,
          ));
        }
      }

      // 6. Curriculum Mapping & Subject Integrity
      if (validSubjectIds.isNotEmpty &&
          !validSubjectIds.contains(q.subjectId)) {
        issues.add(ValidationIssue(
          questionId: q.id,
          issueType: ValidationIssueType.missingSubject,
          severity: ValidationSeverity.error,
          description: 'Question maps to unknown subject ID: "${q.subjectId}"',
          subjectId: q.subjectId,
        ));
      }

      if (validUnitIds.isNotEmpty && !validUnitIds.contains(q.unitId)) {
        issues.add(ValidationIssue(
          questionId: q.id,
          issueType: ValidationIssueType.missingCurriculumMapping,
          severity: ValidationSeverity.warning,
          description:
              'Question unit "${q.unitId}" is not in curriculum catalog.',
          subjectId: q.subjectId,
        ));
      }

      if (validTopicIds.isNotEmpty && !validTopicIds.contains(q.topicId)) {
        issues.add(ValidationIssue(
          questionId: q.id,
          issueType: ValidationIssueType.missingCurriculumMapping,
          severity: ValidationSeverity.warning,
          description:
              'Question topic "${q.topicId}" is not in curriculum catalog.',
          subjectId: q.subjectId,
        ));
      }

      // 7. Source Metadata Validation
      if (q.sourceName.trim().isEmpty) {
        issues.add(ValidationIssue(
          questionId: q.id,
          issueType: ValidationIssueType.missingSourceMetadata,
          severity: ValidationSeverity.warning,
          description: 'Question source metadata is empty.',
          subjectId: q.subjectId,
        ));
      }

      // 8. Stream Assignment Validation
      if (q.grade == 12) {
        final stream = q.stream.toLowerCase();
        if (stream != 'natural' && stream != 'social' && stream != 'common') {
          issues.add(ValidationIssue(
            questionId: q.id,
            issueType: ValidationIssueType.invalidStreamAssignment,
            severity: ValidationSeverity.error,
            description: 'Invalid stream "$stream" for Grade 12 question.',
            subjectId: q.subjectId,
          ));
        }
      }
    }

    // 9. Orphan Units Check
    if (units != null) {
      final activeUnitIds = questions.map((q) => q.unitId).toSet();
      for (final u in units) {
        if (!activeUnitIds.contains(u.id)) {
          issues.add(ValidationIssue(
            issueType: ValidationIssueType.orphanCurriculumUnit,
            severity: ValidationSeverity.info,
            description:
                'Curriculum unit "${u.titleEn}" (${u.id}) has no questions.',
            subjectId: u.subjectId,
          ));
        }
      }
    }

    final exactDupes = detectExactDuplicates(questions);
    final nearDupes = detectNearDuplicates(questions);

    return ValidationReport(
      totalQuestionsAnalyzed: questions.length,
      issues: issues,
      exactDuplicates: exactDupes,
      nearDuplicates: nearDupes,
    );
  }
}
