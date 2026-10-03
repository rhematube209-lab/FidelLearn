import 'package:equatable/equatable.dart';
export '../../../school/domain/models/tenant_models.dart' show Classroom;

class ClassAssignment extends Equatable {
  final String id;
  final String classroomId;
  final String classroomName;
  final String title;
  final String subjectId;
  final String subjectName;
  final List<String> questionIds;
  final int timeLimitMinutes;
  final DateTime dueAt;
  final DateTime createdAt;
  final int totalSubmissions;
  final double averageScorePercentage;

  const ClassAssignment({
    required this.id,
    required this.classroomId,
    required this.classroomName,
    required this.title,
    required this.subjectId,
    required this.subjectName,
    required this.questionIds,
    this.timeLimitMinutes = 15,
    required this.dueAt,
    required this.createdAt,
    this.totalSubmissions = 0,
    this.averageScorePercentage = 0.0,
  });

  ClassAssignment copyWith({
    int? totalSubmissions,
    double? averageScorePercentage,
  }) {
    return ClassAssignment(
      id: id,
      classroomId: classroomId,
      classroomName: classroomName,
      title: title,
      subjectId: subjectId,
      subjectName: subjectName,
      questionIds: questionIds,
      timeLimitMinutes: timeLimitMinutes,
      dueAt: dueAt,
      createdAt: createdAt,
      totalSubmissions: totalSubmissions ?? this.totalSubmissions,
      averageScorePercentage:
          averageScorePercentage ?? this.averageScorePercentage,
    );
  }

  @override
  List<Object?> get props => [
        id,
        classroomId,
        classroomName,
        title,
        subjectId,
        subjectName,
        questionIds,
        timeLimitMinutes,
        dueAt,
        createdAt,
        totalSubmissions,
        averageScorePercentage,
      ];
}

class ClassroomTopicStats extends Equatable {
  final String topicId;
  final String topicName;
  final double averageAccuracyPercentage;
  final int totalQuestionsAttempted;
  final bool isWeakArea;

  const ClassroomTopicStats({
    required this.topicId,
    required this.topicName,
    required this.averageAccuracyPercentage,
    required this.totalQuestionsAttempted,
    required this.isWeakArea,
  });

  @override
  List<Object?> get props => [
        topicId,
        topicName,
        averageAccuracyPercentage,
        totalQuestionsAttempted,
        isWeakArea,
      ];
}
