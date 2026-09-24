/// Canonical Exam Preparation Phases based on proximity to the Ethiopian National Examination (ESSLCE).
enum ExamPreparationPhase {
  /// More than 60 days until the national exam.
  /// Focus: broad curriculum coverage, baseline diagnostics, weak-topic remediation, and initial mistake review.
  foundation,

  /// 31 to 60 days until the national exam.
  /// Focus: completing curriculum coverage, focused weak-topic remediation, mistake review, and balanced practice.
  consolidation,

  /// 15 to 30 days until the national exam.
  /// Focus: intensive weak-topic mastery, unmastered mistake remediation, and timed sectional practice.
  intensive,

  /// 0 to 14 days until the national exam.
  /// Focus: high-urgency timed national mock exam drills (+85 boost), final mistake review, and recall maintenance.
  finalReview;

  static ExamPreparationPhase fromDays(int? daysUntilExam) {
    if (daysUntilExam == null || daysUntilExam < 0) {
      return ExamPreparationPhase.foundation;
    }
    if (daysUntilExam <= 14) {
      return ExamPreparationPhase.finalReview;
    } else if (daysUntilExam <= 30) {
      return ExamPreparationPhase.intensive;
    } else if (daysUntilExam <= 60) {
      return ExamPreparationPhase.consolidation;
    } else {
      return ExamPreparationPhase.foundation;
    }
  }

  String get displayNameEn {
    switch (this) {
      case ExamPreparationPhase.foundation:
        return 'Foundation & Coverage Phase';
      case ExamPreparationPhase.consolidation:
        return 'Consolidation Phase';
      case ExamPreparationPhase.intensive:
        return 'Intensive Remediation Phase';
      case ExamPreparationPhase.finalReview:
        return 'Final Mock & Review Phase';
    }
  }

  String get displayNameAm {
    switch (this) {
      case ExamPreparationPhase.foundation:
        return 'የመሰረት እና ይዘት ሽፋን ምዕራፍ';
      case ExamPreparationPhase.consolidation:
        return 'የማጠናከሪያ ምዕራፍ';
      case ExamPreparationPhase.intensive:
        return 'ከፍተኛ የክለሳ ምዕራፍ';
      case ExamPreparationPhase.finalReview:
        return 'የመጨረሻ የሙከራ ፈተናዎች ምዕራፍ';
    }
  }
}

/// Single canonical authority governing exam proximity weights and policy for FidelLearn.
class ExamPreparationPolicy {
  final ExamPreparationPhase phase;
  final int? daysUntilExam;

  const ExamPreparationPolicy({
    required this.phase,
    this.daysUntilExam,
  });

  /// Resolves the canonical policy from the student's target exam date and current date.
  /// Truncates timestamps to calendar day boundaries to prevent timezone and time-of-day jitter.
  factory ExamPreparationPolicy.fromDates({
    DateTime? targetExamDate,
    required DateTime currentDate,
  }) {
    if (targetExamDate == null) {
      return const ExamPreparationPolicy(
        phase: ExamPreparationPhase.foundation,
        daysUntilExam: null,
      );
    }

    final curDay =
        DateTime(currentDate.year, currentDate.month, currentDate.day);
    final examDay =
        DateTime(targetExamDate.year, targetExamDate.month, targetExamDate.day);
    final days = examDay.difference(curDay).inDays;

    if (days < 0) {
      // Past exam date: student is continuing post-exam study or practice; treat as foundation
      return const ExamPreparationPolicy(
        phase: ExamPreparationPhase.foundation,
        daysUntilExam: null,
      );
    } else if (days <= 14) {
      return ExamPreparationPolicy(
        phase: ExamPreparationPhase.finalReview,
        daysUntilExam: days,
      );
    } else if (days <= 30) {
      return ExamPreparationPolicy(
        phase: ExamPreparationPhase.intensive,
        daysUntilExam: days,
      );
    } else if (days <= 60) {
      return ExamPreparationPolicy(
        phase: ExamPreparationPhase.consolidation,
        daysUntilExam: days,
      );
    } else {
      return ExamPreparationPolicy(
        phase: ExamPreparationPhase.foundation,
        daysUntilExam: days,
      );
    }
  }

  /// Whether the high-priority timed full mock drill boost (+85.0) should be activated.
  /// Strictly active ONLY in the final review phase (0 to 14 days before national exam).
  bool get isMockBoostActive => phase == ExamPreparationPhase.finalReview;

  /// Proximity weight bonus for weak topic practice sessions.
  double get weakTopicProximityWeight {
    switch (phase) {
      case ExamPreparationPhase.finalReview:
        return 20.0;
      case ExamPreparationPhase.intensive:
        return 15.0;
      case ExamPreparationPhase.consolidation:
        return 10.0;
      case ExamPreparationPhase.foundation:
        return 5.0;
    }
  }

  /// Proximity weight bonus for unattempted curriculum coverage sessions.
  double get coverageProximityWeight {
    switch (phase) {
      case ExamPreparationPhase.foundation:
        return 10.0;
      case ExamPreparationPhase.consolidation:
        return 8.0;
      case ExamPreparationPhase.intensive:
        return 4.0;
      case ExamPreparationPhase.finalReview:
        return 2.0;
    }
  }

  /// Generates explainable reason detail for approaching exam recommendations.
  String formatExamApproachingDetailEn() {
    if (daysUntilExam != null) {
      return 'The national exam is only $daysUntilExam days away. Timed mock sessions build pacing confidence.';
    }
    return 'Regular practice builds exam pacing and accuracy confidence.';
  }

  /// Generates explainable Amharic reason detail for approaching exam recommendations.
  String formatExamApproachingDetailAm() {
    if (daysUntilExam != null) {
      return 'ሀገር አቀፍ ፈተናው ሊደርስ $daysUntilExam ቀናት ብቻ ቀርተዋል። የጊዜ ገደብ ልምምድ ፍጥነትዎን ያሳድጋል።';
    }
    return 'የተከታታይ ልምምድ የፈተና ፍጥነትና ትክክለኛነትን ያሳድጋል።';
  }
}
