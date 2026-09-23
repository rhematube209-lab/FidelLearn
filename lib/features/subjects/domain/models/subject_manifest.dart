import 'package:equatable/equatable.dart';

import 'subject_models.dart';

/// Explicit status indicating whether an official curriculum manifest is verified against authoritative documents.
enum ManifestVerificationStatus {
  confirmed,
  partiallyConfirmed,
  needsVerification;

  String get displayName {
    switch (this) {
      case ManifestVerificationStatus.confirmed:
        return 'Confirmed';
      case ManifestVerificationStatus.partiallyConfirmed:
        return 'Partially Confirmed';
      case ManifestVerificationStatus.needsVerification:
        return 'Needs Verification';
    }
  }

  bool get isConfirmed => this == ManifestVerificationStatus.confirmed;
}

/// Verification status for curriculum guides and textbooks (granular source types).
enum CurriculumVerificationStatus {
  confirmedByCurriculumGuide,
  confirmedByStudentTextbook,
  confirmedByEaesSpecification,
  pendingVerification;

  String get displayName {
    switch (this) {
      case CurriculumVerificationStatus.confirmedByCurriculumGuide:
        return 'Confirmed by MoE Curriculum Guide';
      case CurriculumVerificationStatus.confirmedByStudentTextbook:
        return 'Confirmed by Student Textbook';
      case CurriculumVerificationStatus.confirmedByEaesSpecification:
        return 'Confirmed by EAES Specification';
      case CurriculumVerificationStatus.pendingVerification:
        return 'Pending Independent Verification';
    }
  }
}

/// Represents an authoritative expected unit or domain in an official curriculum manifest.
class ExpectedUnitOrDomain extends Equatable {
  final int index;
  final String id;
  final String titleEn;
  final String titleAm;
  final String? domainType; // 'unit', 'skill_domain', 'cognitive_domain'
  final List<String> primaryTopics;
  final String? sourceReference;
  final String? sourcePage;
  final ManifestVerificationStatus verificationStatus;

  const ExpectedUnitOrDomain({
    required this.index,
    required this.id,
    required this.titleEn,
    required this.titleAm,
    this.domainType = 'unit',
    this.primaryTopics = const [],
    this.sourceReference,
    this.sourcePage,
    this.verificationStatus = ManifestVerificationStatus.confirmed,
  });

  List<String> get expectedSkills => primaryTopics;

  @override
  List<Object?> get props => [
        index,
        id,
        titleEn,
        titleAm,
        domainType,
        primaryTopics,
        sourceReference,
        sourcePage,
        verificationStatus,
      ];
}

/// Represents the authoritative curriculum manifest defining the official denominator
/// for curriculum coverage and launch readiness.
class SubjectManifest extends Equatable {
  final String manifestId;
  final String canonicalSubjectId;
  final ExamVariantCode variantCode;
  final String title;
  final String sourceAuthority;
  final String sourceDocumentTitle;
  final String? sourceDocumentId;
  final String sourceReference;
  final String? sourceUrlOrReference;
  final String curriculumVersion;
  final String? verifiedAt;
  final String? verifiedBy;
  final ManifestVerificationStatus verificationStatus;
  final AssessmentStructure assessmentStructure;
  final SubjectScope scope;
  final bool isSupplementary;
  final List<ExpectedUnitOrDomain> expectedUnitsOrDomains;
  final List<int> targetPastExamYears;

  const SubjectManifest({
    required this.manifestId,
    required this.canonicalSubjectId,
    required this.variantCode,
    required this.title,
    this.sourceAuthority = 'FDRE Ministry of Education',
    required this.sourceDocumentTitle,
    this.sourceDocumentId,
    required this.sourceReference,
    this.sourceUrlOrReference,
    this.curriculumVersion = 'current_grade12',
    this.verifiedAt,
    this.verifiedBy,
    this.verificationStatus = ManifestVerificationStatus.confirmed,
    required this.assessmentStructure,
    required this.expectedUnitsOrDomains,
    this.scope = SubjectScope.streamExam,
    this.isSupplementary = false,
    this.targetPastExamYears = const [2013, 2014, 2015, 2016, 2017, 2018],
    String? authoritativeSource,
    String? curriculumFrameworkVersion,
  });

  DateTime? get verifiedAtDate =>
      verifiedAt != null ? DateTime.tryParse(verifiedAt!) : null;

  String get authoritativeSource => sourceReference.isNotEmpty
      ? sourceReference
      : '$sourceAuthority: $sourceDocumentTitle';

  String get curriculumFrameworkVersion => curriculumVersion;

  int get totalExpectedCount => expectedUnitsOrDomains.length;
  List<ExpectedUnitOrDomain> get unitsOrDomains => expectedUnitsOrDomains;

  @override
  List<Object?> get props => [
        manifestId,
        canonicalSubjectId,
        variantCode,
        title,
        sourceAuthority,
        sourceDocumentTitle,
        sourceDocumentId,
        sourceReference,
        sourceUrlOrReference,
        curriculumVersion,
        verifiedAt,
        verifiedBy,
        verificationStatus,
        assessmentStructure,
        scope,
        isSupplementary,
        expectedUnitsOrDomains,
        targetPastExamYears,
      ];
}
