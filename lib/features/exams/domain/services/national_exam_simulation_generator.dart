import 'dart:math';

import '../../../../core/errors/failures.dart';
import '../../../question_bank/domain/models/question_models.dart';
import '../../../subjects/domain/models/subject_models.dart';
import '../models/exam_models.dart';

/// Pure, deterministic service responsible for validating blueprints and generating
/// national exam simulations from verified offline question pools.
class NationalExamSimulationGenerator {
  const NationalExamSimulationGenerator();

  /// Validates content sufficiency and deterministically generates an [Exam]
  /// simulation adhering strictly to the provided [blueprint] and [seed].
  ///
  /// Throws [SimulationSufficiencyFailure] if any partition lacks required questions.
  Exam generateSimulation({
    required NationalExamBlueprint blueprint,
    required List<Question> questionPool,
    required int seed,
  }) {
    // 1. Filter question pool for baseline eligibility
    final eligiblePool =
        questionPool.where((q) => _isEligible(q, blueprint)).toList();

    // 2. Deterministic RNG seeded by the simulation seed
    final rng = Random(seed);

    final selectedQuestions = <Question>[];
    final selectedIds = <String>{};

    // 3. For each partition in the blueprint, verify sufficiency and select deterministically
    for (final partition in blueprint.partitions) {
      final matchingCandidates = eligiblePool.where((q) {
        if (selectedIds.contains(q.id)) return false;
        return _matchesPartition(q, partition);
      }).toList();

      if (matchingCandidates.length < partition.requiredCount) {
        throw SimulationSufficiencyFailure(
          subjectId: blueprint.subjectId,
          partitionName: partition.nameEn,
          requiredCount: partition.requiredCount,
          availableCount: matchingCandidates.length,
        );
      }

      // Sort deterministically before seeded shuffle to guarantee identical output across devices
      matchingCandidates.sort((a, b) => a.id.compareTo(b.id));
      matchingCandidates.shuffle(rng);

      // Handle stimulus / reading passage grouping if applicable
      final partitionSelected = _selectWithStimulusGrouping(
        candidates: matchingCandidates,
        requiredCount: partition.requiredCount,
        difficultyQuotas: partition.difficultyQuotas,
        rng: rng,
      );

      for (final q in partitionSelected) {
        selectedIds.add(q.id);
        selectedQuestions.add(q);
      }
    }

    final streamStr = blueprint.examVariant == ExamVariantCode.socialScience
        ? 'social'
        : 'natural';

    final examTitle = _formatExamTitle(blueprint);

    return Exam(
      id: 'sim_${blueprint.subjectId}_${blueprint.examVariant.name}_$seed',
      title: examTitle,
      examType: ExamType.mockFull,
      examMode: ExamMode.nationalSimulation,
      sourceType: ExamSourceType.generatedSimulation,
      grade: 12,
      stream: streamStr,
      subjectId: blueprint.subjectId,
      examVariant: blueprint.examVariant,
      blueprintVersion: blueprint.blueprintVersion,
      simulationSeed: seed,
      sections: blueprint.sections,
      timeLimitMinutes: blueprint.timeLimitMinutes,
      totalQuestions: selectedQuestions.length,
      questions: List.unmodifiable(selectedQuestions),
      createdAt: DateTime.now(),
    );
  }

  /// Verifies whether question matches Grade 12, subject, and variant constraints
  bool _isEligible(Question q, NationalExamBlueprint blueprint) {
    if (q.grade != 12) return false;

    // Verification check: only verified / approved / published / corrected
    final isVerified = q.verificationStatus == VerificationStatus.verified ||
        q.verificationStatus == VerificationStatus.published ||
        q.verificationStatus == VerificationStatus.approved ||
        q.verificationStatus == VerificationStatus.corrected ||
        q.verificationStatus == VerificationStatus.intendedAnswer ||
        q.verificationStatus == VerificationStatus.bestAnswer;
    if (!isVerified) return false;

    if (!q.isPracticeEligible || !q.isScorable) return false;
    if (q.choices.length < 2) return false;

    // Strict Subject match
    final qSub = q.subjectId.toLowerCase().trim();
    final bpSub = blueprint.subjectId.toLowerCase().trim();
    final isSubjectMatch = qSub == bpSub ||
        (bpSub.contains('math') && qSub.contains('math')) ||
        (bpSub.contains('eng') && qSub.contains('eng')) ||
        (bpSub.contains('apt') && qSub.contains('apt')) ||
        (bpSub.contains('phy') && qSub.contains('phy')) ||
        (bpSub.contains('chem') && qSub.contains('chem')) ||
        (bpSub.contains('bio') && qSub.contains('bio')) ||
        (bpSub.contains('hist') && qSub.contains('hist')) ||
        (bpSub.contains('geo') && qSub.contains('geo')) ||
        (bpSub.contains('econ') && qSub.contains('econ'));
    if (!isSubjectMatch) return false;

    // Strict Subject and Variant Isolation
    final isMath = bpSub.contains('math') || qSub.contains('math');
    if (isMath) {
      if (!validateMathQuestionEligibility(
        question: q,
        targetVariant: blueprint.examVariant,
      )) {
        return false;
      }
    } else {
      // Strict Natural vs Social variant isolation for non-Math subjects
      if (blueprint.examVariant == ExamVariantCode.naturalScience) {
        if (q.examVariant == ExamVariantCode.socialScience) return false;
        if (q.stream.toLowerCase() == 'social') return false;
      } else if (blueprint.examVariant == ExamVariantCode.socialScience) {
        if (q.examVariant == ExamVariantCode.naturalScience) return false;
        if (q.stream.toLowerCase() == 'natural') return false;
      }
    }

    return true;
  }

  /// Strictly validates whether a Math question qualifies for a national exam simulation.
  ///
  /// Enforces:
  /// - Natural Science: exact match `q.examVariant == ExamVariantCode.naturalScience`
  /// - Social Science: exact match `q.examVariant == ExamVariantCode.socialScience`
  /// - Null or shared variant: strictly excluded from national simulation (no legacy fallback)
  /// - Secondary consistency check: conflicting stream and variant (e.g. naturalScience + social stream) is rejected.
  static bool validateMathQuestionEligibility({
    required Question question,
    required ExamVariantCode targetVariant,
  }) {
    // 1. Math questions must have an explicit stream-specific variant (no null or shared allowed)
    if (question.examVariant == null ||
        question.examVariant == ExamVariantCode.shared) {
      return false;
    }

    // 2. Exact variant matching
    if (targetVariant == ExamVariantCode.naturalScience) {
      if (question.examVariant != ExamVariantCode.naturalScience) return false;
      // Secondary guard: reject if stream metadata is explicitly inconsistent
      if (question.stream.toLowerCase() == 'social') return false;
      return true;
    } else if (targetVariant == ExamVariantCode.socialScience) {
      if (question.examVariant != ExamVariantCode.socialScience) return false;
      // Secondary guard: reject if stream metadata is explicitly inconsistent
      if (question.stream.toLowerCase() == 'natural') return false;
      return true;
    }

    return false;
  }

  /// Checks if a question matches a blueprint partition definition
  bool _matchesPartition(Question q, BlueprintPartition partition) {
    // 1. Check unitIds if specified
    if (partition.unitIds != null && partition.unitIds!.isNotEmpty) {
      final unitMatch = partition.unitIds!.contains(q.unitId) ||
          (q.curriculumUnitId != null &&
              partition.unitIds!.contains(q.curriculumUnitId));
      if (unitMatch) return true;
    }

    // 2. Check contentDomain if specified
    if (partition.contentDomain != null &&
        partition.contentDomain!.isNotEmpty) {
      if (q.contentDomain != null &&
          q.contentDomain!
              .toLowerCase()
              .contains(partition.contentDomain!.toLowerCase())) {
        return true;
      }
      if (q.topicId
          .toLowerCase()
          .contains(partition.contentDomain!.toLowerCase())) {
        return true;
      }
    }

    // 3. Check skill if specified
    if (partition.skill != null && partition.skill!.isNotEmpty) {
      if (q.skill != null &&
          q.skill!.toLowerCase().contains(partition.skill!.toLowerCase())) {
        return true;
      }
    }

    // 4. If partition has no unitIds, contentDomain, or skill filters, it matches any eligible item
    if ((partition.unitIds == null || partition.unitIds!.isEmpty) &&
        (partition.contentDomain == null || partition.contentDomain!.isEmpty) &&
        (partition.skill == null || partition.skill!.isEmpty)) {
      return true;
    }

    return false;
  }

  /// Deterministically selects [requiredCount] questions, grouping companion passage questions
  List<Question> _selectWithStimulusGrouping({
    required List<Question> candidates,
    required int requiredCount,
    required Map<String, int>? difficultyQuotas,
    required Random rng,
  }) {
    final result = <Question>[];
    final selectedIds = <String>{};

    // If reading passages exist, map them
    final passageMap = <String, List<Question>>{};
    for (final q in candidates) {
      final pId = q.readingPassage?.id;
      if (pId != null && pId.isNotEmpty) {
        passageMap.putIfAbsent(pId, () => []).add(q);
      }
    }

    // Difficulty selection if quotas provided
    if (difficultyQuotas != null && difficultyQuotas.isNotEmpty) {
      for (final entry in difficultyQuotas.entries) {
        final diff = entry.key.toLowerCase();
        final quota = entry.value;
        int diffPicked = 0;
        final diffCandidates = candidates
            .where((q) =>
                !selectedIds.contains(q.id) &&
                q.difficulty.toLowerCase() == diff)
            .toList();

        for (final q in diffCandidates) {
          if (diffPicked >= quota || result.length >= requiredCount) break;
          if (selectedIds.contains(q.id)) continue;

          // If question belongs to a passage, try to keep companion questions together
          final pId = q.readingPassage?.id;
          if (pId != null && passageMap.containsKey(pId)) {
            final passageQuestions = passageMap[pId]!
                .where((pq) => !selectedIds.contains(pq.id))
                .toList();
            if (result.length + passageQuestions.length <= requiredCount) {
              for (final pq in passageQuestions) {
                result.add(pq);
                selectedIds.add(pq.id);
              }
              diffPicked += passageQuestions.length;
            } else {
              result.add(q);
              selectedIds.add(q.id);
              diffPicked++;
            }
          } else {
            result.add(q);
            selectedIds.add(q.id);
            diffPicked++;
          }
        }
      }
    }

    // Fill remaining quota with available candidates
    for (final q in candidates) {
      if (result.length >= requiredCount) break;
      if (selectedIds.contains(q.id)) continue;

      final pId = q.readingPassage?.id;
      if (pId != null && passageMap.containsKey(pId)) {
        final passageQuestions = passageMap[pId]!
            .where((pq) => !selectedIds.contains(pq.id))
            .toList();
        if (result.length + passageQuestions.length <= requiredCount) {
          for (final pq in passageQuestions) {
            result.add(pq);
            selectedIds.add(pq.id);
          }
        } else {
          result.add(q);
          selectedIds.add(q.id);
        }
      } else {
        result.add(q);
        selectedIds.add(q.id);
      }
    }

    return result.take(requiredCount).toList();
  }

  String _formatExamTitle(NationalExamBlueprint bp) {
    final sub =
        bp.subjectId.replaceAll('_g12', '').replaceAll('_', ' ').toUpperCase();
    final variant = bp.examVariant == ExamVariantCode.naturalScience
        ? 'Natural Science'
        : 'Social Science';
    final prefix = bp.allowsOfficialWording
        ? 'Official ESSLCE Exam'
        : 'FidelLearn ESSLCE Simulation';
    return '$prefix — $sub ($variant)';
  }
}
