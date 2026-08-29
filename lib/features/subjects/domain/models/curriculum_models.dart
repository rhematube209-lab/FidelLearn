import 'package:equatable/equatable.dart';

enum GradeLevel {
  grade6,
  grade8,
  grade12;

  int get numericValue {
    switch (this) {
      case GradeLevel.grade6:
        return 6;
      case GradeLevel.grade8:
        return 8;
      case GradeLevel.grade12:
        return 12;
    }
  }

  String get displayNameEn {
    switch (this) {
      case GradeLevel.grade6:
        return 'Grade 6 (Primary School Leaving Exam)';
      case GradeLevel.grade8:
        return 'Grade 8 (Middle School Ministry Exam)';
      case GradeLevel.grade12:
        return 'Grade 12 (National University Entrance / ESSLCE)';
    }
  }

  String get displayNameAm {
    switch (this) {
      case GradeLevel.grade6:
        return '6ኛ ክፍል (የአንደኛ ደረጃ ማጠቃለያ ፈተና)';
      case GradeLevel.grade8:
        return '8ኛ ክፍል (የክልል ሚኒስትሪ ፈተና)';
      case GradeLevel.grade12:
        return '12ኛ ክፍል (የዩኒቨርሲቲ መግቢያ ብሄራዊ ፈተና)';
    }
  }

  List<String> get supportedStreams {
    switch (this) {
      case GradeLevel.grade6:
      case GradeLevel.grade8:
        return const ['general'];
      case GradeLevel.grade12:
        return const ['natural', 'social'];
    }
  }

  static GradeLevel fromInt(int grade) {
    switch (grade) {
      case 6:
        return GradeLevel.grade6;
      case 8:
        return GradeLevel.grade8;
      case 12:
      default:
        return GradeLevel.grade12;
    }
  }
}

class NationalCurriculumConfig extends Equatable {
  final GradeLevel gradeLevel;
  final String stream;
  final String examStandardCode;
  final List<String> mandatorySubjectIds;

  const NationalCurriculumConfig({
    required this.gradeLevel,
    required this.stream,
    required this.examStandardCode,
    required this.mandatorySubjectIds,
  });

  @override
  List<Object?> get props => [
        gradeLevel,
        stream,
        examStandardCode,
        mandatorySubjectIds,
      ];
}
