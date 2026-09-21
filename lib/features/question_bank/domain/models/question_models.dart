import 'package:equatable/equatable.dart';

import 'diagram_models.dart';

enum VerificationStatus {
  draft,
  reviewRequired,
  approved,
  published,
  corrected,
  archived,
  verified,
  correctedSource,
  intendedAnswer,
  bestAnswer,
  multipleValidAnswers,
  noValidOption,
  underdetermined,
  imageDependent,
  incompleteSource;

  static VerificationStatus fromString(String val) {
    switch (val.toLowerCase().replaceAll('-', '_')) {
      case 'review_required':
      case 'reviewrequired':
        return VerificationStatus.reviewRequired;
      case 'approved':
        return VerificationStatus.approved;
      case 'published':
        return VerificationStatus.published;
      case 'corrected':
        return VerificationStatus.corrected;
      case 'archived':
        return VerificationStatus.archived;
      case 'verified':
        return VerificationStatus.verified;
      case 'corrected_source':
      case 'correctedsource':
        return VerificationStatus.correctedSource;
      case 'intended_answer':
      case 'intendedanswer':
        return VerificationStatus.intendedAnswer;
      case 'best_answer':
      case 'bestanswer':
        return VerificationStatus.bestAnswer;
      case 'multiple_valid_answers':
      case 'multiplevalidanswers':
        return VerificationStatus.multipleValidAnswers;
      case 'no_valid_option':
      case 'novalidoption':
        return VerificationStatus.noValidOption;
      case 'underdetermined':
        return VerificationStatus.underdetermined;
      case 'image_dependent':
      case 'imagedependent':
        return VerificationStatus.imageDependent;
      case 'incomplete_source':
      case 'incompletesource':
        return VerificationStatus.incompleteSource;
      case 'draft':
      default:
        return VerificationStatus.draft;
    }
  }

  String toDbString() {
    switch (this) {
      case VerificationStatus.reviewRequired:
        return 'review_required';
      case VerificationStatus.approved:
        return 'approved';
      case VerificationStatus.published:
        return 'published';
      case VerificationStatus.corrected:
        return 'corrected';
      case VerificationStatus.archived:
        return 'archived';
      case VerificationStatus.verified:
        return 'verified';
      case VerificationStatus.correctedSource:
        return 'corrected_source';
      case VerificationStatus.intendedAnswer:
        return 'intended_answer';
      case VerificationStatus.bestAnswer:
        return 'best_answer';
      case VerificationStatus.multipleValidAnswers:
        return 'multiple_valid_answers';
      case VerificationStatus.noValidOption:
        return 'no_valid_option';
      case VerificationStatus.underdetermined:
        return 'underdetermined';
      case VerificationStatus.imageDependent:
        return 'image_dependent';
      case VerificationStatus.incompleteSource:
        return 'incomplete_source';
      case VerificationStatus.draft:
        return 'draft';
    }
  }
}

class AnswerChoice extends Equatable {
  final String id;
  final String label; // 'A', 'B', 'C', 'D', 'E'
  final String textEn;
  final String? textAm;
  final bool isCorrect;

  const AnswerChoice({
    required this.id,
    required this.label,
    required this.textEn,
    this.textAm,
    required this.isCorrect,
  });

  factory AnswerChoice.fromJson(Map<String, dynamic> json) {
    return AnswerChoice(
      id: json['id']?.toString() ?? '',
      label:
          json['label']?.toString() ?? (json['choice_label']?.toString() ?? ''),
      textEn: json['text_en']?.toString() ??
          (json['choice_text_en']?.toString() ??
              (json['text']?.toString() ?? '')),
      textAm: json['text_am']?.toString() ?? json['choice_text_am']?.toString(),
      isCorrect: json['is_correct'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'text_en': textEn,
      'text_am': textAm,
      'is_correct': isCorrect,
    };
  }

  @override
  List<Object?> get props => [id, label, textEn, textAm, isCorrect];
}

class Explanation extends Equatable {
  final String solutionTextEn;
  final String? solutionTextAm;
  final String? simplerExplanationEn;
  final String? keyConcept;
  final String? commonPitfall;

  const Explanation({
    required this.solutionTextEn,
    this.solutionTextAm,
    this.simplerExplanationEn,
    this.keyConcept,
    this.commonPitfall,
  });

  factory Explanation.fromJson(Map<String, dynamic> json) {
    return Explanation(
      solutionTextEn: json['solution_text_en']?.toString() ??
          (json['text_en']?.toString() ?? 'No explanation available.'),
      solutionTextAm: json['solution_text_am']?.toString(),
      simplerExplanationEn: json['simpler_explanation_en']?.toString(),
      keyConcept: json['key_concept']?.toString() ??
          json['key_concept_or_formula']?.toString(),
      commonPitfall: json['common_pitfall']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'solution_text_en': solutionTextEn,
      'solution_text_am': solutionTextAm,
      'simpler_explanation_en': simplerExplanationEn,
      'key_concept': keyConcept,
      'common_pitfall': commonPitfall,
    };
  }

  @override
  List<Object?> get props => [
        solutionTextEn,
        solutionTextAm,
        simplerExplanationEn,
        keyConcept,
        commonPitfall,
      ];
}

class Question extends Equatable {
  final String id;
  final int grade;
  final String stream;
  final String subjectId;
  final String unitId;
  final String topicId;
  final int? examYear;
  final String questionTextEn;
  final String? questionTextAm;
  final String? diagramAsset;
  final VectorDiagram? vectorDiagram;
  final int? curriculumGrade; // Grade under New Curriculum (9, 10, 11, 12)
  final String? curriculumUnitId; // Unit under New Curriculum
  final String? curriculumTopicId; // Topic under New Curriculum
  final String? curriculumFramework; // 'new_curriculum_2023'
  final String difficulty; // 'easy' | 'medium' | 'hard'
  final VerificationStatus verificationStatus;
  final String sourceName;
  final int? sourcePage;
  final int contentVersion;
  final int? questionNumber;
  final String? reviewNote;
  final String
      difficultySource; // 'source_provided' | 'fidel_learn_assigned' | 'educator_verified'
  final bool isScorable;
  final bool isPracticeEligible;
  final List<AnswerChoice> choices;
  final Explanation explanation;
  final List<String>? secondaryCurriculumLinks;
  final String? answerKeySource;
  final bool? officialAnswerKeyAvailable;

  const Question({
    required this.id,
    required this.grade,
    required this.stream,
    required this.subjectId,
    required this.unitId,
    required this.topicId,
    this.examYear,
    this.questionNumber,
    required this.questionTextEn,
    this.questionTextAm,
    this.diagramAsset,
    this.vectorDiagram,
    this.curriculumGrade,
    this.curriculumUnitId,
    this.curriculumTopicId,
    this.curriculumFramework,
    required this.difficulty,
    this.difficultySource = 'fidel_learn_assigned',
    required this.verificationStatus,
    this.reviewNote,
    this.isScorable = true,
    this.isPracticeEligible = true,
    required this.sourceName,
    this.sourcePage,
    required this.contentVersion,
    required this.choices,
    required this.explanation,
    this.secondaryCurriculumLinks,
    this.answerKeySource,
    this.officialAnswerKeyAvailable,
  });

  Question copyWith({
    int? grade,
    String? stream,
    String? subjectId,
    String? unitId,
    String? topicId,
    int? examYear,
    int? questionNumber,
    String? questionTextEn,
    String? questionTextAm,
    String? diagramAsset,
    VectorDiagram? vectorDiagram,
    int? curriculumGrade,
    String? curriculumUnitId,
    String? curriculumTopicId,
    String? curriculumFramework,
    String? difficulty,
    String? difficultySource,
    VerificationStatus? verificationStatus,
    String? reviewNote,
    bool? isScorable,
    bool? isPracticeEligible,
    String? sourceName,
    int? sourcePage,
    int? contentVersion,
    List<AnswerChoice>? choices,
    Explanation? explanation,
    List<String>? secondaryCurriculumLinks,
    String? answerKeySource,
    bool? officialAnswerKeyAvailable,
  }) {
    return Question(
      id: id,
      grade: grade ?? this.grade,
      stream: stream ?? this.stream,
      subjectId: subjectId ?? this.subjectId,
      unitId: unitId ?? this.unitId,
      topicId: topicId ?? this.topicId,
      examYear: examYear ?? this.examYear,
      questionNumber: questionNumber ?? this.questionNumber,
      questionTextEn: questionTextEn ?? this.questionTextEn,
      questionTextAm: questionTextAm ?? this.questionTextAm,
      diagramAsset: diagramAsset ?? this.diagramAsset,
      vectorDiagram: vectorDiagram ?? this.vectorDiagram,
      curriculumGrade: curriculumGrade ?? this.curriculumGrade,
      curriculumUnitId: curriculumUnitId ?? this.curriculumUnitId,
      curriculumTopicId: curriculumTopicId ?? this.curriculumTopicId,
      curriculumFramework: curriculumFramework ?? this.curriculumFramework,
      difficulty: difficulty ?? this.difficulty,
      difficultySource: difficultySource ?? this.difficultySource,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      reviewNote: reviewNote ?? this.reviewNote,
      isScorable: isScorable ?? this.isScorable,
      isPracticeEligible: isPracticeEligible ?? this.isPracticeEligible,
      sourceName: sourceName ?? this.sourceName,
      sourcePage: sourcePage ?? this.sourcePage,
      contentVersion: contentVersion ?? this.contentVersion,
      choices: choices ?? this.choices,
      explanation: explanation ?? this.explanation,
      secondaryCurriculumLinks:
          secondaryCurriculumLinks ?? this.secondaryCurriculumLinks,
      answerKeySource: answerKeySource ?? this.answerKeySource,
      officialAnswerKeyAvailable:
          officialAnswerKeyAvailable ?? this.officialAnswerKeyAvailable,
    );
  }

  AnswerChoice get correctChoice =>
      choices.firstWhere((c) => c.isCorrect, orElse: () => choices.first);

  factory Question.fromJson(Map<String, dynamic> json) {
    Explanation explanationObj;
    if (json['explanation'] is Map<String, dynamic>) {
      explanationObj =
          Explanation.fromJson(json['explanation'] as Map<String, dynamic>);
    } else if (json['explanations'] is List &&
        (json['explanations'] as List).isNotEmpty &&
        (json['explanations'] as List).first is Map<String, dynamic>) {
      explanationObj = Explanation.fromJson(
          (json['explanations'] as List).first as Map<String, dynamic>);
    } else if (json['explanation'] is String &&
        (json['explanation'] as String).isNotEmpty) {
      explanationObj =
          Explanation(solutionTextEn: json['explanation'] as String);
    } else {
      explanationObj =
          const Explanation(solutionTextEn: 'No explanation available.');
    }

    return Question(
      id: json['id']?.toString() ?? '',
      grade: (json['grade'] as num?)?.toInt() ?? 12,
      stream: json['stream']?.toString() ?? 'common',
      subjectId: json['subject_id']?.toString() ?? '',
      unitId: json['unit_id']?.toString() ?? '',
      topicId: json['topic_id']?.toString() ?? '',
      examYear: (json['exam_year'] as num?)?.toInt(),
      questionNumber: (json['question_number'] as num?)?.toInt(),
      questionTextEn: json['question_text_en']?.toString() ?? '',
      questionTextAm: json['question_text_am']?.toString(),
      diagramAsset:
          json['diagram_asset']?.toString() ?? json['diagram_url']?.toString(),
      vectorDiagram: json['vector_diagram'] != null &&
              json['vector_diagram'] is Map<String, dynamic>
          ? VectorDiagram.fromJson(
              json['vector_diagram'] as Map<String, dynamic>,
            )
          : null,
      curriculumGrade: (json['curriculum_grade'] as num?)?.toInt(),
      curriculumUnitId: json['curriculum_unit_id']?.toString(),
      curriculumTopicId: json['curriculum_topic_id']?.toString(),
      curriculumFramework: json['curriculum_framework']?.toString(),
      difficulty: json['difficulty']?.toString() ?? 'medium',
      difficultySource:
          json['difficulty_source']?.toString() ?? 'fidel_learn_assigned',
      verificationStatus: VerificationStatus.fromString(
        json['verification_status']?.toString() ?? 'published',
      ),
      reviewNote: json['review_note']?.toString(),
      isScorable: json['is_scorable'] as bool? ?? true,
      isPracticeEligible: json['is_practice_eligible'] as bool? ?? true,
      sourceName: json['source_name']?.toString() ??
          'FidelLearn original demonstration content',
      sourcePage: (json['source_page'] as num?)?.toInt(),
      contentVersion: (json['content_version'] as num?)?.toInt() ?? 1,
      choices: (json['choices'] as List<dynamic>?)
              ?.map((c) => AnswerChoice.fromJson(c as Map<String, dynamic>))
              .toList() ??
          ((json['answer_choices'] as List<dynamic>?)
                  ?.map((c) => AnswerChoice.fromJson(c as Map<String, dynamic>))
                  .toList() ??
              []),
      explanation: explanationObj,
      secondaryCurriculumLinks:
          (json['secondary_curriculum_links'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList(),
      answerKeySource: json['answer_key_source']?.toString(),
      officialAnswerKeyAvailable:
          json['official_answer_key_available'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'grade': grade,
      'stream': stream,
      'subject_id': subjectId,
      'unit_id': unitId,
      'topic_id': topicId,
      'exam_year': examYear,
      if (questionNumber != null) 'question_number': questionNumber,
      'question_text_en': questionTextEn,
      'question_text_am': questionTextAm,
      'diagram_asset': diagramAsset,
      if (vectorDiagram != null) 'vector_diagram': vectorDiagram!.toJson(),
      if (curriculumGrade != null) 'curriculum_grade': curriculumGrade,
      if (curriculumUnitId != null) 'curriculum_unit_id': curriculumUnitId,
      if (curriculumTopicId != null) 'curriculum_topic_id': curriculumTopicId,
      if (curriculumFramework != null)
        'curriculum_framework': curriculumFramework,
      'difficulty': difficulty,
      'difficulty_source': difficultySource,
      'verification_status': verificationStatus.toDbString(),
      if (reviewNote != null) 'review_note': reviewNote,
      'is_scorable': isScorable,
      'is_practice_eligible': isPracticeEligible,
      'source_name': sourceName,
      'source_page': sourcePage,
      'content_version': contentVersion,
      'choices': choices.map((c) => c.toJson()).toList(),
      'explanation': explanation.toJson(),
      if (secondaryCurriculumLinks != null)
        'secondary_curriculum_links': secondaryCurriculumLinks,
      if (answerKeySource != null) 'answer_key_source': answerKeySource,
      if (officialAnswerKeyAvailable != null)
        'official_answer_key_available': officialAnswerKeyAvailable,
    };
  }

  @override
  List<Object?> get props => [
        id,
        grade,
        stream,
        subjectId,
        unitId,
        topicId,
        examYear,
        questionNumber,
        questionTextEn,
        questionTextAm,
        diagramAsset,
        vectorDiagram,
        curriculumGrade,
        curriculumUnitId,
        curriculumTopicId,
        curriculumFramework,
        difficulty,
        difficultySource,
        verificationStatus,
        reviewNote,
        isScorable,
        isPracticeEligible,
        sourceName,
        sourcePage,
        contentVersion,
        choices,
        explanation,
        secondaryCurriculumLinks,
        answerKeySource,
        officialAnswerKeyAvailable,
      ];
}

/// Official curriculum classification mapping for national examination items
class QuestionCurriculumMapping extends Equatable {
  final String id;
  final String questionId;
  final String subjectId;
  final int examYear;
  final String curriculumFramework;
  final int curriculumGrade; // 9, 10, 11, or 12
  final String curriculumUnitId;
  final String? curriculumTopicId;
  final int questionOrderInExam;
  final String? unitTitleEn;
  final String? unitTitleAm;
  final String? topicTitleEn;
  final String? topicTitleAm;
  final String? cognitiveLevel;
  final String? notes;

  const QuestionCurriculumMapping({
    required this.id,
    required this.questionId,
    required this.subjectId,
    required this.examYear,
    this.curriculumFramework = 'new_curriculum_2023',
    required this.curriculumGrade,
    required this.curriculumUnitId,
    this.curriculumTopicId,
    required this.questionOrderInExam,
    this.unitTitleEn,
    this.unitTitleAm,
    this.topicTitleEn,
    this.topicTitleAm,
    this.cognitiveLevel,
    this.notes,
  });

  factory QuestionCurriculumMapping.fromJson(Map<String, dynamic> json) {
    return QuestionCurriculumMapping(
      id: json['id']?.toString() ?? '',
      questionId: json['question_id']?.toString() ?? '',
      subjectId: json['subject_id']?.toString() ?? '',
      examYear: (json['exam_year'] as num?)?.toInt() ?? 2013,
      curriculumFramework:
          json['curriculum_framework']?.toString() ?? 'new_curriculum_2023',
      curriculumGrade: (json['curriculum_grade'] as num?)?.toInt() ?? 12,
      curriculumUnitId: json['curriculum_unit_id']?.toString() ?? '',
      curriculumTopicId: json['curriculum_topic_id']?.toString(),
      questionOrderInExam:
          (json['question_order_in_exam'] as num?)?.toInt() ?? 1,
      unitTitleEn: json['unit_title_en']?.toString(),
      unitTitleAm: json['unit_title_am']?.toString(),
      topicTitleEn: json['topic_title_en']?.toString(),
      topicTitleAm: json['topic_title_am']?.toString(),
      cognitiveLevel: json['cognitive_level']?.toString(),
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_id': questionId,
      'subject_id': subjectId,
      'exam_year': examYear,
      'curriculum_framework': curriculumFramework,
      'curriculum_grade': curriculumGrade,
      'curriculum_unit_id': curriculumUnitId,
      'curriculum_topic_id': curriculumTopicId,
      'question_order_in_exam': questionOrderInExam,
      'unit_title_en': unitTitleEn,
      'unit_title_am': unitTitleAm,
      'topic_title_en': topicTitleEn,
      'topic_title_am': topicTitleAm,
      'cognitive_level': cognitiveLevel,
      'notes': notes,
    };
  }

  @override
  List<Object?> get props => [
        id,
        questionId,
        subjectId,
        examYear,
        curriculumFramework,
        curriculumGrade,
        curriculumUnitId,
        curriculumTopicId,
        questionOrderInExam,
      ];
}
