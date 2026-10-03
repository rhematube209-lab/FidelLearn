import 'package:equatable/equatable.dart';
import '../../../subjects/domain/models/subject_models.dart';

/// Distinct first-class modes of examination operation
enum ExamMode {
  practice,
  custom,
  nationalSimulation,
  historicalPaper;

  static ExamMode fromString(String? val) {
    if (val == null) return ExamMode.practice;
    switch (val.toLowerCase().trim()) {
      case 'nationalsimulation':
      case 'national_simulation':
      case 'esslce_simulation':
        return ExamMode.nationalSimulation;
      case 'historicalpaper':
      case 'historical_paper':
      case 'official_paper':
        return ExamMode.historicalPaper;
      case 'custom':
      case 'custom_builder':
        return ExamMode.custom;
      case 'practice':
      default:
        return ExamMode.practice;
    }
  }

  String toDbString() {
    switch (this) {
      case ExamMode.nationalSimulation:
        return 'national_simulation';
      case ExamMode.historicalPaper:
        return 'historical_paper';
      case ExamMode.custom:
        return 'custom';
      case ExamMode.practice:
        return 'practice';
    }
  }

  bool get isStrictExam =>
      this == ExamMode.nationalSimulation || this == ExamMode.historicalPaper;
}

/// Provenance categorization for examination papers
enum ExamSourceType {
  officialHistoricalPaper,
  verifiedModelPaper,
  generatedSimulation;

  static ExamSourceType fromString(String? val) {
    if (val == null) return ExamSourceType.generatedSimulation;
    switch (val.toLowerCase().trim()) {
      case 'officialhistoricalpaper':
      case 'official_historical_paper':
      case 'official_past_paper':
        return ExamSourceType.officialHistoricalPaper;
      case 'verifiedmodelpaper':
      case 'verified_model_paper':
        return ExamSourceType.verifiedModelPaper;
      case 'generatedsimulation':
      case 'generated_simulation':
      default:
        return ExamSourceType.generatedSimulation;
    }
  }

  String toDbString() {
    switch (this) {
      case ExamSourceType.officialHistoricalPaper:
        return 'official_historical_paper';
      case ExamSourceType.verifiedModelPaper:
        return 'verified_model_paper';
      case ExamSourceType.generatedSimulation:
        return 'generated_simulation';
    }
  }
}

/// Authoritative helper for normalizing P5 provenance labels across P7, P8, and P9.
class ExamProvenanceHelper {
  static String resolveProvenanceLabel({
    required String sourceType,
    required String examMode,
    required String examType,
  }) {
    final normalizedSource = sourceType.toLowerCase().replaceAll('_', '');
    final normalizedMode = examMode.toLowerCase().replaceAll('_', '');

    if (normalizedSource == 'officialhistoricalpaper' ||
        normalizedSource == 'officialpastexam' ||
        normalizedSource == 'officialpastpaper' ||
        normalizedMode == 'historicalpaper') {
      return 'Official Historical Paper';
    }
    if (normalizedSource == 'verifiedmodelpaper' ||
        normalizedSource == 'verifiedmodel' ||
        normalizedSource == 'modelexam') {
      return 'Verified Model Exam';
    }
    if (normalizedMode == 'nationalsimulation' ||
        (normalizedSource == 'generatedsimulation' &&
            examType == 'mock_full')) {
      return 'FidelLearn ESSLCE Simulation';
    }
    if (normalizedMode == 'custom' || examType == 'custom_builder') {
      return 'Custom Exam';
    }
    if (examType == 'unit_test') {
      return 'Unit Test';
    }
    if (examType == 'teacher_assigned' ||
        normalizedSource == 'teachercustom' ||
        normalizedSource == 'teacherassignment') {
      return 'Teacher Assignment';
    }
    return 'Practice';
  }
}

/// Verified completeness status for historical national papers
enum HistoricalCompletenessStatus {
  verifiedComplete,
  verifiedPartial,
  unavailable;

  static HistoricalCompletenessStatus fromString(String? val) {
    if (val == null) return HistoricalCompletenessStatus.unavailable;
    switch (val.toLowerCase().trim()) {
      case 'verifiedcomplete':
      case 'verified_complete':
      case 'complete':
        return HistoricalCompletenessStatus.verifiedComplete;
      case 'verifiedpartial':
      case 'verified_partial':
      case 'partial':
        return HistoricalCompletenessStatus.verifiedPartial;
      case 'unavailable':
      default:
        return HistoricalCompletenessStatus.unavailable;
    }
  }
}

/// Centralized behavioral policy governing an examination session
class NationalExamPolicy extends Equatable {
  final ExamMode mode;
  final bool allowPause;
  final bool hideInstantFeedback;
  final bool autoSubmitOnExpiry;
  final bool strictWallClock;
  final bool allowFlagForReview;
  final List<int> warningThresholdMinutes;

  const NationalExamPolicy({
    required this.mode,
    this.allowPause = false,
    this.hideInstantFeedback = true,
    this.autoSubmitOnExpiry = true,
    this.strictWallClock = true,
    this.allowFlagForReview = true,
    this.warningThresholdMinutes = const [30, 10, 5, 1],
  });

  /// National Exam Simulation policy (non-pausable, strict wall clock, auto-submit)
  static const NationalExamPolicy nationalSimulation = NationalExamPolicy(
    mode: ExamMode.nationalSimulation,
    allowPause: false,
    hideInstantFeedback: true,
    autoSubmitOnExpiry: true,
    strictWallClock: true,
    allowFlagForReview: true,
    warningThresholdMinutes: [30, 10, 5, 1],
  );

  /// Historical past paper policy (non-pausable, strict wall clock, auto-submit)
  static const NationalExamPolicy historicalPaper = NationalExamPolicy(
    mode: ExamMode.historicalPaper,
    allowPause: false,
    hideInstantFeedback: true,
    autoSubmitOnExpiry: true,
    strictWallClock: true,
    allowFlagForReview: true,
    warningThresholdMinutes: [30, 10, 5, 1],
  );

  /// Custom exam builder policy (pausable, non-strict feedback based on user config)
  static const NationalExamPolicy customExam = NationalExamPolicy(
    mode: ExamMode.custom,
    allowPause: true,
    hideInstantFeedback: true,
    autoSubmitOnExpiry: true,
    strictWallClock: false,
    allowFlagForReview: true,
    warningThresholdMinutes: [10, 5, 1],
  );

  /// Relaxed practice policy (pausable, instant feedback available, no strict timer)
  static const NationalExamPolicy practice = NationalExamPolicy(
    mode: ExamMode.practice,
    allowPause: true,
    hideInstantFeedback: false,
    autoSubmitOnExpiry: false,
    strictWallClock: false,
    allowFlagForReview: true,
    warningThresholdMinutes: [],
  );

  factory NationalExamPolicy.fromMode(ExamMode mode) {
    switch (mode) {
      case ExamMode.nationalSimulation:
        return nationalSimulation;
      case ExamMode.historicalPaper:
        return historicalPaper;
      case ExamMode.custom:
        return customExam;
      case ExamMode.practice:
        return practice;
    }
  }

  bool get isStrictExam =>
      mode == ExamMode.nationalSimulation || mode == ExamMode.historicalPaper;

  @override
  List<Object?> get props => [
        mode,
        allowPause,
        hideInstantFeedback,
        autoSubmitOnExpiry,
        strictWallClock,
        allowFlagForReview,
        warningThresholdMinutes,
      ];
}

/// Logical section of an examination (e.g., Section A: Mechanics, Section B: Electromagnetism)
class ExamSection extends Equatable {
  final String id;
  final String titleEn;
  final String titleAm;
  final int startIndex;
  final int questionCount;
  final String? stimulusText;
  final String? stimulusTitle;

  const ExamSection({
    required this.id,
    required this.titleEn,
    required this.titleAm,
    required this.startIndex,
    required this.questionCount,
    this.stimulusText,
    this.stimulusTitle,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title_en': titleEn,
        'title_am': titleAm,
        'start_index': startIndex,
        'question_count': questionCount,
        if (stimulusText != null) 'stimulus_text': stimulusText,
        if (stimulusTitle != null) 'stimulus_title': stimulusTitle,
      };

  factory ExamSection.fromJson(Map<String, dynamic> json) => ExamSection(
        id: json['id'] as String,
        titleEn: json['title_en'] as String,
        titleAm: json['title_am'] as String,
        startIndex: json['start_index'] as int,
        questionCount: json['question_count'] as int,
        stimulusText: json['stimulus_text'] as String?,
        stimulusTitle: json['stimulus_title'] as String?,
      );

  @override
  List<Object?> get props => [
        id,
        titleEn,
        titleAm,
        startIndex,
        questionCount,
        stimulusText,
        stimulusTitle,
      ];
}

/// Blueprint partition defining question quota for a domain, unit, or skill
class BlueprintPartition extends Equatable {
  final String nameEn;
  final String nameAm;
  final int requiredCount;
  final List<String>? unitIds;
  final List<String>? topicIds;
  final String? contentDomain;
  final String? skill;
  final Map<String, int>?
      difficultyQuotas; // e.g. {'easy': 3, 'medium': 5, 'hard': 2}

  const BlueprintPartition({
    required this.nameEn,
    required this.nameAm,
    required this.requiredCount,
    this.unitIds,
    this.topicIds,
    this.contentDomain,
    this.skill,
    this.difficultyQuotas,
  });

  Map<String, dynamic> toJson() => {
        'name_en': nameEn,
        'name_am': nameAm,
        'required_count': requiredCount,
        if (unitIds != null) 'unit_ids': unitIds,
        if (topicIds != null) 'topic_ids': topicIds,
        if (contentDomain != null) 'content_domain': contentDomain,
        if (skill != null) 'skill': skill,
        if (difficultyQuotas != null) 'difficulty_quotas': difficultyQuotas,
      };

  factory BlueprintPartition.fromJson(Map<String, dynamic> json) =>
      BlueprintPartition(
        nameEn: json['name_en'] as String,
        nameAm: json['name_am'] as String,
        requiredCount: json['required_count'] as int,
        unitIds: (json['unit_ids'] as List<dynamic>?)?.cast<String>(),
        topicIds: (json['topic_ids'] as List<dynamic>?)?.cast<String>(),
        contentDomain: json['content_domain'] as String?,
        skill: json['skill'] as String?,
        difficultyQuotas: (json['difficulty_quotas'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(k, v as int)),
      );

  @override
  List<Object?> get props => [
        nameEn,
        nameAm,
        requiredCount,
        unitIds,
        topicIds,
        contentDomain,
        skill,
        difficultyQuotas,
      ];
}

/// Explicit verification and provenance status for examination blueprints
enum BlueprintVerificationStatus {
  officialVerified,
  institutionallyVerified,
  fidelLearnSimulation,
  needsVerification;

  static BlueprintVerificationStatus fromString(String? val) {
    if (val == null) return BlueprintVerificationStatus.needsVerification;
    switch (val.toLowerCase().replaceAll('_', '')) {
      case 'officialverified':
      case 'official':
        return BlueprintVerificationStatus.officialVerified;
      case 'institutionallyverified':
      case 'institutional':
        return BlueprintVerificationStatus.institutionallyVerified;
      case 'fidellearnsimulation':
      case 'simulation':
        return BlueprintVerificationStatus.fidelLearnSimulation;
      case 'needsverification':
      default:
        return BlueprintVerificationStatus.needsVerification;
    }
  }

  bool get isOfficial => this == BlueprintVerificationStatus.officialVerified;
  bool get allowsOfficialWording =>
      this == BlueprintVerificationStatus.officialVerified;
}

/// Blueprint defining the exact composition, distribution, and provenance of a simulated national exam
class NationalExamBlueprint extends Equatable {
  final String blueprintVersion; // e.g. 'esslce_sim_math_nat_v1'
  final String subjectId;
  final ExamVariantCode examVariant;
  final int totalQuestions;
  final int timeLimitMinutes;
  final List<BlueprintPartition> partitions;
  final List<ExamSection>? sections;
  final String sourceAuthority;
  final String? sourceReference;
  final BlueprintVerificationStatus verificationStatus;

  const NationalExamBlueprint({
    required this.blueprintVersion,
    required this.subjectId,
    required this.examVariant,
    required this.totalQuestions,
    required this.timeLimitMinutes,
    required this.partitions,
    this.sections,
    this.sourceAuthority = 'FidelLearn Academic Panel (Curriculum-Aligned)',
    this.sourceReference =
        'Ethiopian National Curriculum Framework & EAES Spec Guidelines',
    this.verificationStatus = BlueprintVerificationStatus.fidelLearnSimulation,
  });

  /// Whether UI chrome is permitted to describe this blueprint using official examination titles
  bool get allowsOfficialWording => verificationStatus.allowsOfficialWording;

  /// User-facing descriptive title for the blueprint's provenance category
  String get provenanceLabel {
    if (allowsOfficialWording) {
      return 'Official ESSLCE Specification ($sourceAuthority)';
    }
    return 'FidelLearn Simulation Blueprint ($sourceAuthority)';
  }

  /// User-facing mode label
  String get displayTitle {
    if (allowsOfficialWording) {
      return 'Official ESSLCE Paper';
    }
    return 'FidelLearn ESSLCE Simulation';
  }

  Map<String, dynamic> toJson() => {
        'blueprint_version': blueprintVersion,
        'subject_id': subjectId,
        'exam_variant': examVariant.name,
        'total_questions': totalQuestions,
        'time_limit_minutes': timeLimitMinutes,
        'partitions': partitions.map((p) => p.toJson()).toList(),
        if (sections != null)
          'sections': sections!.map((s) => s.toJson()).toList(),
        'source_authority': sourceAuthority,
        if (sourceReference != null) 'source_reference': sourceReference,
        'verification_status': verificationStatus.name,
      };

  factory NationalExamBlueprint.fromJson(Map<String, dynamic> json) =>
      NationalExamBlueprint(
        blueprintVersion: json['blueprint_version'] as String,
        subjectId: json['subject_id'] as String,
        examVariant: ExamVariantCode.fromString(json['exam_variant'] as String),
        totalQuestions: json['total_questions'] as int,
        timeLimitMinutes: json['time_limit_minutes'] as int,
        partitions: (json['partitions'] as List<dynamic>)
            .map((p) => BlueprintPartition.fromJson(p as Map<String, dynamic>))
            .toList(),
        sections: (json['sections'] as List<dynamic>?)
            ?.map((s) => ExamSection.fromJson(s as Map<String, dynamic>))
            .toList(),
        sourceAuthority: json['source_authority'] as String? ??
            'FidelLearn Academic Panel (Curriculum-Aligned)',
        sourceReference: json['source_reference'] as String?,
        verificationStatus: BlueprintVerificationStatus.fromString(
            json['verification_status'] as String?),
      );

  @override
  List<Object?> get props => [
        blueprintVersion,
        subjectId,
        examVariant,
        totalQuestions,
        timeLimitMinutes,
        partitions,
        sections,
        sourceAuthority,
        sourceReference,
        verificationStatus,
      ];
}
