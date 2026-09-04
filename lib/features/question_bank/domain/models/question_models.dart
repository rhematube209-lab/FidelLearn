import 'package:equatable/equatable.dart';

import 'diagram_models.dart';

enum VerificationStatus {
  draft,
  reviewRequired,
  approved,
  published,
  corrected,
  archived;

  static VerificationStatus fromString(String val) {
    switch (val.toLowerCase()) {
      case 'review_required':
        return VerificationStatus.reviewRequired;
      case 'approved':
        return VerificationStatus.approved;
      case 'published':
        return VerificationStatus.published;
      case 'corrected':
        return VerificationStatus.corrected;
      case 'archived':
        return VerificationStatus.archived;
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
      id: json['id'] as String,
      label: json['label'] as String,
      textEn: json['text_en'] as String,
      textAm: json['text_am'] as String?,
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
      solutionTextEn: json['solution_text_en'] as String,
      solutionTextAm: json['solution_text_am'] as String?,
      simplerExplanationEn: json['simpler_explanation_en'] as String?,
      keyConcept: json['key_concept'] as String?,
      commonPitfall: json['common_pitfall'] as String?,
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
  final String difficulty; // 'easy' | 'medium' | 'hard'
  final VerificationStatus verificationStatus;
  final String sourceName;
  final int? sourcePage;
  final int contentVersion;
  final List<AnswerChoice> choices;
  final Explanation explanation;

  const Question({
    required this.id,
    required this.grade,
    required this.stream,
    required this.subjectId,
    required this.unitId,
    required this.topicId,
    this.examYear,
    required this.questionTextEn,
    this.questionTextAm,
    this.diagramAsset,
    this.vectorDiagram,
    required this.difficulty,
    required this.verificationStatus,
    required this.sourceName,
    this.sourcePage,
    required this.contentVersion,
    required this.choices,
    required this.explanation,
  });

  Question copyWith({
    int? grade,
    String? stream,
    String? subjectId,
    String? unitId,
    String? topicId,
    int? examYear,
    String? questionTextEn,
    String? questionTextAm,
    String? diagramAsset,
    VectorDiagram? vectorDiagram,
    String? difficulty,
    VerificationStatus? verificationStatus,
    String? sourceName,
    int? sourcePage,
    int? contentVersion,
    List<AnswerChoice>? choices,
    Explanation? explanation,
  }) {
    return Question(
      id: id,
      grade: grade ?? this.grade,
      stream: stream ?? this.stream,
      subjectId: subjectId ?? this.subjectId,
      unitId: unitId ?? this.unitId,
      topicId: topicId ?? this.topicId,
      examYear: examYear ?? this.examYear,
      questionTextEn: questionTextEn ?? this.questionTextEn,
      questionTextAm: questionTextAm ?? this.questionTextAm,
      diagramAsset: diagramAsset ?? this.diagramAsset,
      vectorDiagram: vectorDiagram ?? this.vectorDiagram,
      difficulty: difficulty ?? this.difficulty,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      sourceName: sourceName ?? this.sourceName,
      sourcePage: sourcePage ?? this.sourcePage,
      contentVersion: contentVersion ?? this.contentVersion,
      choices: choices ?? this.choices,
      explanation: explanation ?? this.explanation,
    );
  }

  AnswerChoice get correctChoice =>
      choices.firstWhere((c) => c.isCorrect, orElse: () => choices.first);

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      grade: json['grade'] as int? ?? 12,
      stream: json['stream'] as String? ?? 'common',
      subjectId: json['subject_id'] as String,
      unitId: json['unit_id'] as String,
      topicId: json['topic_id'] as String,
      examYear: json['exam_year'] as int?,
      questionTextEn: json['question_text_en'] as String,
      questionTextAm: json['question_text_am'] as String?,
      diagramAsset: json['diagram_asset'] as String?,
      vectorDiagram: json['vector_diagram'] != null
          ? VectorDiagram.fromJson(
              json['vector_diagram'] as Map<String, dynamic>,
            )
          : null,
      difficulty: json['difficulty'] as String? ?? 'medium',
      verificationStatus: VerificationStatus.fromString(
        json['verification_status'] as String? ?? 'published',
      ),
      sourceName: json['source_name'] as String? ??
          'FidelLearn original demonstration content',
      sourcePage: json['source_page'] as int?,
      contentVersion: json['content_version'] as int? ?? 1,
      choices: (json['choices'] as List<dynamic>?)
              ?.map((c) => AnswerChoice.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      explanation: json['explanation'] != null
          ? Explanation.fromJson(json['explanation'] as Map<String, dynamic>)
          : const Explanation(solutionTextEn: 'No explanation available.'),
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
      'question_text_en': questionTextEn,
      'question_text_am': questionTextAm,
      'diagram_asset': diagramAsset,
      if (vectorDiagram != null) 'vector_diagram': vectorDiagram!.toJson(),
      'difficulty': difficulty,
      'verification_status': verificationStatus.toDbString(),
      'source_name': sourceName,
      'source_page': sourcePage,
      'content_version': contentVersion,
      'choices': choices.map((c) => c.toJson()).toList(),
      'explanation': explanation.toJson(),
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
        questionTextEn,
        questionTextAm,
        diagramAsset,
        vectorDiagram,
        difficulty,
        verificationStatus,
        sourceName,
        sourcePage,
        contentVersion,
        choices,
        explanation,
      ];
}
