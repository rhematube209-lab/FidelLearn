import 'package:equatable/equatable.dart';

import 'package:fidel_learn/features/subjects/data/repositories/local_content_repository.dart';
import '../models/subject_models.dart';
import '../models/subject_manifest.dart';
import 'curriculum_manifest_catalog.dart';
import '../../../question_bank/domain/models/question_models.dart';

/// Configurable launch policy determining how historical exam paper depth affects launch readiness.
enum HistoricalDepthLaunchPolicy {
  informationalOnly,
  minimumYearCount,
  requiredSpecificYears,
  allTargetYears;

  String get displayName {
    switch (this) {
      case HistoricalDepthLaunchPolicy.informationalOnly:
        return 'Informational Only';
      case HistoricalDepthLaunchPolicy.minimumYearCount:
        return 'Minimum Year Count';
      case HistoricalDepthLaunchPolicy.requiredSpecificYears:
        return 'Required Specific Years';
      case HistoricalDepthLaunchPolicy.allTargetYears:
        return 'All Target Years (100%)';
    }
  }
}

/// Explicit archive completeness status for past exam papers.
/// Completely separated from academic launch readiness.
enum HistoricalCoverageStatus {
  complete, // all target years verified
  partial, // at least 1 verified target year, but not all
  minimal; // 0 verified target years

  String get displayName {
    switch (this) {
      case HistoricalCoverageStatus.complete:
        return 'HISTORICAL COMPLETE';
      case HistoricalCoverageStatus.partial:
        return 'HISTORICAL PARTIAL';
      case HistoricalCoverageStatus.minimal:
        return 'HISTORICAL MINIMAL';
    }
  }
}

/// Authority level for official curriculum coverage calculations.
enum CoverageAuthorityLevel {
  authoritative, // Manifest verified and confirmed
  provisional, // Manifest partially confirmed
  unverified; // Manifest unverified or pending

  String get displayName {
    switch (this) {
      case CoverageAuthorityLevel.authoritative:
        return 'AUTHORITATIVE';
      case CoverageAuthorityLevel.provisional:
        return 'PROVISIONAL — Manifest verification incomplete';
      case CoverageAuthorityLevel.unverified:
        return 'UNVERIFIED — Manifest verification required';
    }
  }
}

enum SubjectLaunchReadiness {
  notStarted,
  inProgress,
  contentReview,
  qa,
  readyForLaunch;

  String get displayName {
    switch (this) {
      case SubjectLaunchReadiness.notStarted:
        return 'NOT STARTED';
      case SubjectLaunchReadiness.inProgress:
        return 'IN PROGRESS';
      case SubjectLaunchReadiness.contentReview:
        return 'CONTENT REVIEW';
      case SubjectLaunchReadiness.qa:
        return 'QA';
      case SubjectLaunchReadiness.readyForLaunch:
        return 'READY FOR LAUNCH';
    }
  }

  String get description {
    switch (this) {
      case SubjectLaunchReadiness.notStarted:
        return 'No questions ingested yet for this subject.';
      case SubjectLaunchReadiness.inProgress:
        return 'Questions ingested but curriculum units or exam years incomplete.';
      case SubjectLaunchReadiness.contentReview:
        return 'Curriculum covered, but explanations or verification pending.';
      case SubjectLaunchReadiness.qa:
        return 'Verified content undergoing final automated and pedagogical QA.';
      case SubjectLaunchReadiness.readyForLaunch:
        return 'Production ready: verified, curriculum covered, explanations complete.';
    }
  }
}

class SubjectCoverageMetrics extends Equatable {
  final String subjectId;
  final String subjectNameEn;
  final String subjectNameAm;
  final int totalUnits;
  final int unitsWithQuestions;
  final int totalQuestions;
  final int publishedQuestions;
  final int reviewRequiredQuestions;
  final int draftQuestions;
  final Map<int, int> questionsPerExamYear; // year -> count
  final double rationaleCoveragePercent; // 0.0 - 100.0
  final double keyConceptCoveragePercent;
  final double commonPitfallCoveragePercent;
  final double amharicTranslationPercent;
  final SubjectLaunchReadiness readiness;
  final List<String> blockingGaps;

  // Decoupled Metrics & Launch Attributes
  final SubjectScope scope;
  final ExamVariantCode variantCode;
  final AssessmentStructure assessmentStructure;
  final int manifestTotalUnits;
  final List<int> targetExamYears;
  final List<int> availableExamYears;
  final List<int> verifiedExamYears;
  final List<int> missingTargetExamYears;
  final double curriculumBreadthPercent;
  final double pastPaperDepthPercent;
  final int questionBankDepth;
  final double explanationCoveragePercent;

  // Final Hardening: Archive Completeness & Authority Attributes
  final HistoricalCoverageStatus historicalCoverageStatus;
  final CoverageAuthorityLevel coverageAuthorityLevel;
  final ManifestVerificationStatus manifestVerificationStatus;
  final String? sourceAuthority;
  final String? sourceDocumentTitle;
  final String? curriculumVersion;
  final String? manifestVerifiedAt;
  final String? manifestVerifiedBy;

  const SubjectCoverageMetrics({
    required this.subjectId,
    required this.subjectNameEn,
    required this.subjectNameAm,
    required this.totalUnits,
    required this.unitsWithQuestions,
    required this.totalQuestions,
    required this.publishedQuestions,
    required this.reviewRequiredQuestions,
    required this.draftQuestions,
    required this.questionsPerExamYear,
    required this.rationaleCoveragePercent,
    required this.keyConceptCoveragePercent,
    required this.commonPitfallCoveragePercent,
    required this.amharicTranslationPercent,
    required this.readiness,
    required this.blockingGaps,
    this.scope = SubjectScope.streamExam,
    this.variantCode = ExamVariantCode.shared,
    this.assessmentStructure = AssessmentStructure.curriculum,
    int? manifestTotalUnits,
    this.targetExamYears = const [2013, 2014, 2015, 2016, 2017, 2018],
    this.availableExamYears = const [],
    this.verifiedExamYears = const [],
    this.missingTargetExamYears = const [],
    double? curriculumBreadthPercent,
    double? pastPaperDepthPercent,
    int? questionBankDepth,
    double? explanationCoveragePercent,
    this.historicalCoverageStatus = HistoricalCoverageStatus.minimal,
    this.coverageAuthorityLevel = CoverageAuthorityLevel.authoritative,
    this.manifestVerificationStatus = ManifestVerificationStatus.confirmed,
    this.sourceAuthority,
    this.sourceDocumentTitle,
    this.curriculumVersion,
    this.manifestVerifiedAt,
    this.manifestVerifiedBy,
  })  : manifestTotalUnits = manifestTotalUnits ?? totalUnits,
        curriculumBreadthPercent = curriculumBreadthPercent ??
            (totalUnits > 0 ? (unitsWithQuestions / totalUnits) * 100.0 : 0.0),
        pastPaperDepthPercent = pastPaperDepthPercent ?? 100.0,
        questionBankDepth = questionBankDepth ?? totalQuestions,
        explanationCoveragePercent =
            explanationCoveragePercent ?? rationaleCoveragePercent;

  List<int> get effectiveAvailableYears => availableExamYears.isNotEmpty
      ? availableExamYears
      : (questionsPerExamYear.keys.toList()..sort());

  List<int> get effectiveVerifiedYears => verifiedExamYears.isNotEmpty
      ? verifiedExamYears
      : (questionsPerExamYear.entries
          .where((e) => e.value > 0)
          .map((e) => e.key)
          .toList()
        ..sort());

  List<int> get effectiveMissingTargetYears => missingTargetExamYears.isNotEmpty
      ? missingTargetExamYears
      : targetExamYears
          .where((y) => !(questionsPerExamYear.containsKey(y) &&
              questionsPerExamYear[y]! > 0))
          .toList();

  double get unitCoveragePercent =>
      totalUnits > 0 ? (unitsWithQuestions / totalUnits) * 100.0 : 0.0;

  @override
  List<Object?> get props => [
        subjectId,
        totalQuestions,
        publishedQuestions,
        readiness,
        blockingGaps,
        scope,
        variantCode,
        assessmentStructure,
        manifestTotalUnits,
        targetExamYears,
        availableExamYears,
        verifiedExamYears,
        missingTargetExamYears,
        curriculumBreadthPercent,
        pastPaperDepthPercent,
        questionBankDepth,
        explanationCoveragePercent,
        historicalCoverageStatus,
        coverageAuthorityLevel,
        manifestVerificationStatus,
        sourceAuthority,
        sourceDocumentTitle,
        curriculumVersion,
        manifestVerifiedAt,
        manifestVerifiedBy,
      ];
}

class CurriculumCoverageReport extends Equatable {
  final DateTime evaluatedAt;
  final List<SubjectCoverageMetrics> subjectMetrics;

  const CurriculumCoverageReport({
    required this.evaluatedAt,
    required this.subjectMetrics,
  });

  int get totalQuestions =>
      subjectMetrics.fold(0, (acc, m) => acc + m.totalQuestions);

  int get totalPublished =>
      subjectMetrics.fold(0, (acc, m) => acc + m.publishedQuestions);

  int get readySubjectsCount => subjectMetrics
      .where((m) => m.readiness == SubjectLaunchReadiness.readyForLaunch)
      .length;

  bool get allLaunchSubjectsReady =>
      subjectMetrics.isNotEmpty && readySubjectsCount == subjectMetrics.length;

  @override
  List<Object?> get props => [evaluatedAt, subjectMetrics];
}

/// Service evaluating curriculum completeness and production readiness.
class CurriculumCoverageService {
  /// Evaluates launch readiness for a specific subject based on questions and units.
  SubjectCoverageMetrics evaluateSubject({
    required Subject subject,
    required List<Unit> units,
    required List<Question> questions,
    ExamVariantCode? variantCode,
    String? stream,
    bool enforceAuthoritativeBreadth = false,
    HistoricalDepthLaunchPolicy historicalDepthPolicy =
        HistoricalDepthLaunchPolicy.informationalOnly,
    int minimumVerifiedYears = 1,
    List<int> requiredExamYears = const [],
    SubjectManifest? manifestOverride,
  }) {
    final manifest = manifestOverride ??
        CurriculumManifestCatalog.findManifest(
          subject.id,
          variantCode: variantCode,
          stream: stream ?? subject.stream,
        );

    final resolvedVariant = variantCode ??
        (subject.availableVariants.isNotEmpty
            ? subject.availableVariants.first.variantCode
            : (stream == 'social'
                ? ExamVariantCode.socialScience
                : (stream == 'natural'
                    ? ExamVariantCode.naturalScience
                    : ExamVariantCode.shared)));

    final subjectQuestions = questions.where((q) {
      if (variantCode != null &&
          q.examVariant != null &&
          q.examVariant != ExamVariantCode.shared &&
          q.examVariant != variantCode) {
        return false;
      }
      if (stream != null && stream != 'common' && stream != 'general') {
        if (q.stream != 'common' &&
            q.stream != 'general' &&
            q.stream != stream) {
          return false;
        }
        if (stream == 'natural' &&
            (q.examVariant == ExamVariantCode.socialScience ||
                q.subjectId.toLowerCase().contains('soc'))) {
          return false;
        }
        if (stream == 'social' &&
            (q.examVariant == ExamVariantCode.naturalScience ||
                q.subjectId.toLowerCase().contains('nat'))) {
          return false;
        }
      }
      return q.subjectId == subject.id ||
          LocalContentRepository.matchesSubjectId(q.subjectId, subject.id) ||
          LocalContentRepository.matchesSubjectDiscipline(
              q.subjectId, subject.id);
    }).toList();

    final totalQs = subjectQuestions.length;
    final published = subjectQuestions
        .where((q) =>
            q.verificationStatus == VerificationStatus.published ||
            q.verificationStatus == VerificationStatus.verified)
        .length;
    final reviewReq = subjectQuestions
        .where((q) => q.verificationStatus == VerificationStatus.reviewRequired)
        .length;
    final drafts = subjectQuestions
        .where((q) => q.verificationStatus == VerificationStatus.draft)
        .length;

    // Unit coverage
    final activeUnitIds = subjectQuestions.map((q) => q.unitId).toSet();
    final subjectUnits = units
        .where((u) =>
            LocalContentRepository.matchesSubjectId(u.subjectId, subject.id))
        .toList();

    final int manifestUnitsTotal = manifest?.totalExpectedCount ??
        (subjectUnits.isNotEmpty ? subjectUnits.length : 1);
    final int totalUnits =
        subjectUnits.isNotEmpty ? subjectUnits.length : manifestUnitsTotal;

    final coveredUnits = subjectUnits.isNotEmpty
        ? subjectUnits.where((u) => activeUnitIds.contains(u.id)).length
        : activeUnitIds.length;

    // Decoupled metric 1: Curriculum Breadth %
    final double breadthPct = manifestUnitsTotal > 0
        ? (coveredUnits / manifestUnitsTotal) * 100.0
        : 0.0;

    // Decoupled metric 2: Past-Paper Depth
    final targetYears = manifest?.targetPastExamYears ??
        CurriculumManifestCatalog.defaultTargetYears;
    final Map<int, int> byYear = {};
    for (final q in subjectQuestions) {
      if (q.examYear != null) {
        byYear[q.examYear!] = (byYear[q.examYear!] ?? 0) + 1;
      }
    }
    final availableExamYears = byYear.keys.toList()..sort();
    final verifiedExamYears = byYear.entries
        .where((e) => e.value > 0)
        .map((e) => e.key)
        .toList()
      ..sort();
    final verifiedTargetYears =
        targetYears.where((y) => (byYear[y] ?? 0) > 0).toList();
    final missingTargetExamYears =
        targetYears.where((y) => !verifiedTargetYears.contains(y)).toList();
    final double pastPaperDepthPct = targetYears.isNotEmpty
        ? (verifiedTargetYears.length / targetYears.length) * 100.0
        : 0.0;

    // Archive completeness status (separated from launch readiness)
    final HistoricalCoverageStatus historicalCoverageStatus;
    if (targetYears.isNotEmpty &&
        verifiedTargetYears.length >= targetYears.length) {
      historicalCoverageStatus = HistoricalCoverageStatus.complete;
    } else if (verifiedTargetYears.isNotEmpty) {
      historicalCoverageStatus = HistoricalCoverageStatus.partial;
    } else {
      historicalCoverageStatus = HistoricalCoverageStatus.minimal;
    }

    // Manifest verification status & authority level
    final manifestStatus = manifest?.verificationStatus ??
        ManifestVerificationStatus.needsVerification;
    final CoverageAuthorityLevel authorityLevel;
    switch (manifestStatus) {
      case ManifestVerificationStatus.confirmed:
        authorityLevel = CoverageAuthorityLevel.authoritative;
        break;
      case ManifestVerificationStatus.partiallyConfirmed:
        authorityLevel = CoverageAuthorityLevel.provisional;
        break;
      case ManifestVerificationStatus.needsVerification:
        authorityLevel = CoverageAuthorityLevel.unverified;
        break;
    }

    // Decoupled metric 4: Explanation Quality
    int withRationale = 0;
    int withKeyConcept = 0;
    int withPitfall = 0;
    int withAmharic = 0;

    for (final q in subjectQuestions) {
      if (q.explanation.solutionTextEn.trim().isNotEmpty &&
          q.explanation.solutionTextEn != 'No explanation available.') {
        withRationale++;
      }
      if (q.explanation.keyConcept != null &&
          q.explanation.keyConcept!.trim().isNotEmpty) {
        withKeyConcept++;
      }
      if (q.explanation.commonPitfall != null &&
          q.explanation.commonPitfall!.trim().isNotEmpty) {
        withPitfall++;
      }
      if ((q.questionTextAm != null && q.questionTextAm!.trim().isNotEmpty) ||
          (q.explanation.solutionTextAm != null &&
              q.explanation.solutionTextAm!.trim().isNotEmpty)) {
        withAmharic++;
      }
    }

    final double rationalePct =
        totalQs > 0 ? (withRationale / totalQs) * 100.0 : 0.0;
    final double keyConceptPct =
        totalQs > 0 ? (withKeyConcept / totalQs) * 100.0 : 0.0;
    final double pitfallPct =
        totalQs > 0 ? (withPitfall / totalQs) * 100.0 : 0.0;
    final double amharicPct =
        totalQs > 0 ? (withAmharic / totalQs) * 100.0 : 0.0;

    // Determine deterministic readiness & blocking gaps
    final List<String> gaps = [];
    SubjectLaunchReadiness readiness;

    if (totalQs == 0) {
      readiness = SubjectLaunchReadiness.notStarted;
      gaps.add('No questions found for subject ${subject.nameEn}.');
    } else if (totalQs < 5) {
      readiness = SubjectLaunchReadiness.inProgress;
      gaps.add(
          'Question bank has only $totalQs questions (need at least 5 for launch testing).');
    } else if (coveredUnits == 0 && subjectUnits.isNotEmpty) {
      readiness = SubjectLaunchReadiness.inProgress;
      gaps.add('Zero units have mapped questions.');
    } else if (drafts > 0 || reviewReq > 0) {
      readiness = SubjectLaunchReadiness.contentReview;
      gaps.add(
          '$reviewReq questions require verification; $drafts in draft state.');
    } else if (manifestStatus == ManifestVerificationStatus.needsVerification) {
      readiness = SubjectLaunchReadiness.qa;
      gaps.add(
          'Curriculum manifest verification incomplete (Status: NEEDS_VERIFICATION). Official curriculum completeness cannot be certified.');
    } else if (enforceAuthoritativeBreadth && breadthPct < 100.0) {
      readiness = SubjectLaunchReadiness.qa;
      gaps.add(
          'Curriculum breadth is ${breadthPct.toStringAsFixed(1)}% ($coveredUnits of $manifestUnitsTotal units). Undergoing pedagogical expansion.');
    } else if (rationalePct < 85.0) {
      readiness = SubjectLaunchReadiness.qa;
      gaps.add(
          'Rationale explanation coverage (${rationalePct.toStringAsFixed(1)}%) is below 85% requirement.');
    } else if (historicalDepthPolicy ==
            HistoricalDepthLaunchPolicy.allTargetYears &&
        missingTargetExamYears.isNotEmpty) {
      readiness = SubjectLaunchReadiness.qa;
      gaps.add(
          'Historical depth policy requires all target years; missing: ${missingTargetExamYears.join(', ')} E.C.');
    } else if (historicalDepthPolicy ==
            HistoricalDepthLaunchPolicy.minimumYearCount &&
        verifiedTargetYears.length < minimumVerifiedYears) {
      readiness = SubjectLaunchReadiness.qa;
      gaps.add(
          'Historical depth policy requires at least $minimumVerifiedYears verified years (found ${verifiedTargetYears.length}).');
    } else if (historicalDepthPolicy ==
            HistoricalDepthLaunchPolicy.requiredSpecificYears &&
        requiredExamYears.any((y) => !verifiedTargetYears.contains(y))) {
      final missing = requiredExamYears
          .where((y) => !verifiedTargetYears.contains(y))
          .toList();
      readiness = SubjectLaunchReadiness.qa;
      gaps.add(
          'Historical depth policy requires specific years; missing: ${missing.join(', ')} E.C.');
    } else {
      readiness = SubjectLaunchReadiness.readyForLaunch;
    }

    return SubjectCoverageMetrics(
      subjectId: subject.id,
      subjectNameEn: subject.nameEn,
      subjectNameAm: subject.nameAm,
      totalUnits: totalUnits,
      unitsWithQuestions: coveredUnits,
      totalQuestions: totalQs,
      publishedQuestions: published,
      reviewRequiredQuestions: reviewReq,
      draftQuestions: drafts,
      questionsPerExamYear: byYear,
      rationaleCoveragePercent: rationalePct,
      keyConceptCoveragePercent: keyConceptPct,
      commonPitfallCoveragePercent: pitfallPct,
      amharicTranslationPercent: amharicPct,
      readiness: readiness,
      blockingGaps: gaps,
      scope: subject.scope,
      variantCode: resolvedVariant,
      assessmentStructure:
          manifest?.assessmentStructure ?? subject.assessmentStructure,
      manifestTotalUnits: manifestUnitsTotal,
      targetExamYears: targetYears,
      availableExamYears: availableExamYears,
      verifiedExamYears: verifiedExamYears,
      missingTargetExamYears: missingTargetExamYears,
      curriculumBreadthPercent: breadthPct,
      pastPaperDepthPercent: pastPaperDepthPct,
      questionBankDepth: totalQs,
      explanationCoveragePercent: rationalePct,
      historicalCoverageStatus: historicalCoverageStatus,
      coverageAuthorityLevel: authorityLevel,
      manifestVerificationStatus: manifestStatus,
      sourceAuthority: manifest?.sourceAuthority,
      sourceDocumentTitle: manifest?.sourceDocumentTitle,
      curriculumVersion: manifest?.curriculumVersion,
      manifestVerifiedAt: manifest?.verifiedAt,
      manifestVerifiedBy: manifest?.verifiedBy,
    );
  }

  /// Generates a structured audit summary of official curriculum manifest evidence.
  static List<Map<String, dynamic>> generateManifestSourceAuditSummary() {
    return CurriculumManifestCatalog.allManifests.map((m) {
      return {
        'manifestId': m.manifestId,
        'canonicalSubjectId': m.canonicalSubjectId,
        'variantCode': m.variantCode.name,
        'title': m.title,
        'curriculumVersion': m.curriculumVersion,
        'sourceAuthority': m.sourceAuthority,
        'sourceDocumentTitle': m.sourceDocumentTitle,
        'sourceDocumentId': m.sourceDocumentId ?? 'N/A',
        'sourceReference': m.sourceReference,
        'sourceUrlOrReference': m.sourceUrlOrReference ?? 'N/A',
        'verificationStatus': m.verificationStatus.name,
        'verifiedAt': m.verifiedAt ?? 'Pending',
        'verifiedBy': m.verifiedBy ?? 'Pending',
        'totalUnitsOrDomains': m.totalExpectedCount,
        'scope': m.scope.name,
        'structure': m.assessmentStructure.name,
      };
    }).toList();
  }

  /// Evaluates entire curriculum report across multiple subjects.
  CurriculumCoverageReport generateReport({
    required List<Subject> subjects,
    required List<Unit> units,
    required List<Question> questions,
    bool enforceAuthoritativeBreadth = false,
    HistoricalDepthLaunchPolicy historicalDepthPolicy =
        HistoricalDepthLaunchPolicy.informationalOnly,
  }) {
    final metrics = subjects.map((s) {
      return evaluateSubject(
        subject: s,
        units: units,
        questions: questions,
        enforceAuthoritativeBreadth: enforceAuthoritativeBreadth,
        historicalDepthPolicy: historicalDepthPolicy,
      );
    }).toList();

    return CurriculumCoverageReport(
      evaluatedAt: DateTime.now(),
      subjectMetrics: metrics,
    );
  }
}
