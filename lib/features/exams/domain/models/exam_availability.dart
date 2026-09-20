import 'package:equatable/equatable.dart';

/// Represents dynamically indexed metadata for a verified national exam year
/// under a specific subject.
class ExamAvailability extends Equatable {
  final String subjectId;
  final int year;
  final int totalQuestions;
  final Map<String, int> unitCounts; // unitId / curriculumUnitId -> question count
  final bool verified;
  final String? sourceName;

  const ExamAvailability({
    required this.subjectId,
    required this.year,
    required this.totalQuestions,
    this.unitCounts = const {},
    this.verified = true,
    this.sourceName,
  });

  @override
  List<Object?> get props => [
        subjectId,
        year,
        totalQuestions,
        unitCounts,
        verified,
        sourceName,
      ];
}
