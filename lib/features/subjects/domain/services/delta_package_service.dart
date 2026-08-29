import 'package:equatable/equatable.dart';

import '../../../question_bank/domain/models/question_models.dart';

class PackageDelta extends Equatable {
  final String packageId;
  final String fromVersion;
  final String toVersion;
  final List<Question> addedQuestions;
  final List<Question> updatedQuestions;
  final List<String> deprecatedQuestionIds;
  final DateTime releaseDate;

  const PackageDelta({
    required this.packageId,
    required this.fromVersion,
    required this.toVersion,
    required this.addedQuestions,
    required this.updatedQuestions,
    required this.deprecatedQuestionIds,
    required this.releaseDate,
  });

  int get totalChanges =>
      addedQuestions.length +
      updatedQuestions.length +
      deprecatedQuestionIds.length;

  @override
  List<Object?> get props => [
        packageId,
        fromVersion,
        toVersion,
        addedQuestions,
        updatedQuestions,
        deprecatedQuestionIds,
        releaseDate,
      ];
}

class DeltaPackageService {
  List<Question> applyDeltaPatch({
    required List<Question> existingQuestions,
    required PackageDelta delta,
  }) {
    final Map<String, Question> questionMap = {
      for (final q in existingQuestions) q.id: q,
    };

    // Remove deprecated questions
    for (final depId in delta.deprecatedQuestionIds) {
      questionMap.remove(depId);
    }

    // Update existing questions
    for (final updated in delta.updatedQuestions) {
      questionMap[updated.id] = updated;
    }

    // Add new questions
    for (final added in delta.addedQuestions) {
      questionMap[added.id] = added;
    }

    return questionMap.values.toList();
  }

  bool isDeltaCompatible({
    required String currentVersion,
    required PackageDelta delta,
  }) {
    return currentVersion.trim() == delta.fromVersion.trim();
  }
}
