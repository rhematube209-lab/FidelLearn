import 'package:equatable/equatable.dart';

class SchoolProfile extends Equatable {
  final String id;
  final String name;
  final String region;
  final int totalStudents;
  final int totalTeachers;
  final int naturalStreamStudents;
  final int socialStreamStudents;

  const SchoolProfile({
    required this.id,
    required this.name,
    required this.region,
    required this.totalStudents,
    required this.totalTeachers,
    required this.naturalStreamStudents,
    required this.socialStreamStudents,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        region,
        totalStudents,
        totalTeachers,
        naturalStreamStudents,
        socialStreamStudents,
      ];
}

class RosterTeacher extends Equatable {
  final String id;
  final String name;
  final String subject;
  final int classroomCount;
  final int studentCount;
  final double averageClassAccuracy;

  const RosterTeacher({
    required this.id,
    required this.name,
    required this.subject,
    required this.classroomCount,
    required this.studentCount,
    required this.averageClassAccuracy,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        subject,
        classroomCount,
        studentCount,
        averageClassAccuracy,
      ];
}

class SchoolAnalyticsSummary extends Equatable {
  final double overallReadinessScore;
  final double naturalStreamReadiness;
  final double socialStreamReadiness;
  final String topPerformingSubject;
  final String priorityWeakSubject;
  final int totalMockExamsCompleted;

  const SchoolAnalyticsSummary({
    required this.overallReadinessScore,
    required this.naturalStreamReadiness,
    required this.socialStreamReadiness,
    required this.topPerformingSubject,
    required this.priorityWeakSubject,
    required this.totalMockExamsCompleted,
  });

  @override
  List<Object?> get props => [
        overallReadinessScore,
        naturalStreamReadiness,
        socialStreamReadiness,
        topPerformingSubject,
        priorityWeakSubject,
        totalMockExamsCompleted,
      ];
}
