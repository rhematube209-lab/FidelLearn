import 'package:equatable/equatable.dart';

enum SubjectScope {
  commonExam, // Required for both streams (English, Aptitude, Mathematics)
  streamExam, // Stream specific (Sciences or Social Sciences)
  curriculumOnly, // Supplementary / revision (Civics)
}

enum ExamVariantCode {
  shared, // Taken identically across streams (English, Aptitude)
  naturalScience, // Natural Science specific examination (Math Nat, Physics, Chem, Bio)
  socialScience, // Social Science specific examination (Math Soc, History, Geo, Econ)
}

enum AssessmentStructure {
  curriculum, // Standard units & topics (Sciences, Social Studies, Math)
  skillBased, // Cognitive domains & skills (Scholastic Aptitude)
  mixed, // Stimulus reading passages + discrete language skills (English)
}

class SubjectExamVariant extends Equatable {
  final String variantId; // e.g. 'math_g12_natural', 'math_g12_social'
  final String subjectId; // 'math_g12'
  final ExamVariantCode variantCode;
  final String nameEn;
  final String nameAm;
  final String streamEligibility; // 'natural', 'social', 'common'
  final AssessmentStructure assessmentStructure;
  final String packageId;
  final String manifestId;

  const SubjectExamVariant({
    required this.variantId,
    required this.subjectId,
    required this.variantCode,
    required this.nameEn,
    required this.nameAm,
    this.streamEligibility = 'common',
    this.assessmentStructure = AssessmentStructure.curriculum,
    this.packageId = '',
    this.manifestId = '',
  });

  factory SubjectExamVariant.fromJson(Map<String, dynamic> json) {
    return SubjectExamVariant(
      variantId: json['variant_id']?.toString() ?? '',
      subjectId: json['subject_id']?.toString() ?? '',
      variantCode: ExamVariantCode.values.firstWhere(
        (e) => e.name == json['variant_code'],
        orElse: () => ExamVariantCode.shared,
      ),
      nameEn: json['name_en']?.toString() ?? '',
      nameAm: json['name_am']?.toString() ?? '',
      streamEligibility: json['stream_eligibility']?.toString() ?? 'common',
      assessmentStructure: AssessmentStructure.values.firstWhere(
        (e) => e.name == json['assessment_structure'],
        orElse: () => AssessmentStructure.curriculum,
      ),
      packageId: json['package_id']?.toString() ?? '',
      manifestId: json['manifest_id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'variant_id': variantId,
      'subject_id': subjectId,
      'variant_code': variantCode.name,
      'name_en': nameEn,
      'name_am': nameAm,
      'stream_eligibility': streamEligibility,
      'assessment_structure': assessmentStructure.name,
      'package_id': packageId,
      'manifest_id': manifestId,
    };
  }

  @override
  List<Object?> get props => [
        variantId,
        subjectId,
        variantCode,
        nameEn,
        nameAm,
        streamEligibility,
        assessmentStructure,
        packageId,
        manifestId,
      ];
}

class Subject extends Equatable {
  final String id;
  final String code;
  final String nameEn;
  final String nameAm;
  final int grade;
  final String stream;
  final String? iconAsset;
  final int sortOrder;
  final SubjectScope scope;
  final AssessmentStructure assessmentStructure;
  final List<SubjectExamVariant> availableVariants;

  const Subject({
    required this.id,
    required this.code,
    required this.nameEn,
    required this.nameAm,
    required this.grade,
    required this.stream,
    this.iconAsset,
    required this.sortOrder,
    this.scope = SubjectScope.streamExam,
    this.assessmentStructure = AssessmentStructure.curriculum,
    this.availableVariants = const [],
  });

  /// Resolves the student stream to the appropriate exam variant track.
  SubjectExamVariant? resolveVariant(String studentStream) {
    if (availableVariants.isEmpty) return null;
    if (availableVariants.length == 1) return availableVariants.first;
    for (final v in availableVariants) {
      if (v.streamEligibility == studentStream) return v;
    }
    return availableVariants.first;
  }

  Subject copyWith({
    String? id,
    String? code,
    String? nameEn,
    String? nameAm,
    int? grade,
    String? stream,
    String? iconAsset,
    int? sortOrder,
    SubjectScope? scope,
    AssessmentStructure? assessmentStructure,
    List<SubjectExamVariant>? availableVariants,
  }) {
    return Subject(
      id: id ?? this.id,
      code: code ?? this.code,
      nameEn: nameEn ?? this.nameEn,
      nameAm: nameAm ?? this.nameAm,
      grade: grade ?? this.grade,
      stream: stream ?? this.stream,
      iconAsset: iconAsset ?? this.iconAsset,
      sortOrder: sortOrder ?? this.sortOrder,
      scope: scope ?? this.scope,
      assessmentStructure: assessmentStructure ?? this.assessmentStructure,
      availableVariants: availableVariants ?? this.availableVariants,
    );
  }

  factory Subject.fromJson(Map<String, dynamic> json) {
    final rawId = json['id']?.toString() ?? '';
    final rawScope = json['scope']?.toString();
    final SubjectScope resolvedScope;
    if (rawScope != null) {
      resolvedScope = SubjectScope.values.firstWhere(
        (s) => s.name == rawScope,
        orElse: () => SubjectScope.streamExam,
      );
    } else if (rawId.contains('civics')) {
      resolvedScope = SubjectScope.curriculumOnly;
    } else if (rawId.contains('english') ||
        rawId.contains('aptitude') ||
        rawId.contains('math')) {
      resolvedScope = SubjectScope.commonExam;
    } else {
      resolvedScope = SubjectScope.streamExam;
    }

    final rawStructure = json['assessment_structure']?.toString();
    final AssessmentStructure resolvedStructure;
    if (rawStructure != null) {
      resolvedStructure = AssessmentStructure.values.firstWhere(
        (a) => a.name == rawStructure,
        orElse: () => AssessmentStructure.curriculum,
      );
    } else if (rawId.contains('aptitude')) {
      resolvedStructure = AssessmentStructure.skillBased;
    } else if (rawId.contains('english')) {
      resolvedStructure = AssessmentStructure.mixed;
    } else {
      resolvedStructure = AssessmentStructure.curriculum;
    }

    final variantsList = (json['available_variants'] as List<dynamic>?)
            ?.map((v) => SubjectExamVariant.fromJson(v as Map<String, dynamic>))
            .toList() ??
        const [];

    return Subject(
      id: rawId,
      code: json['code']?.toString() ?? '',
      nameEn: json['name_en']?.toString() ?? '',
      nameAm: json['name_am']?.toString() ?? '',
      grade: (json['grade'] as num?)?.toInt() ?? 12,
      stream: json['stream']?.toString() ?? 'common',
      iconAsset: json['icon_asset']?.toString(),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      scope: resolvedScope,
      assessmentStructure: resolvedStructure,
      availableVariants: variantsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name_en': nameEn,
      'name_am': nameAm,
      'grade': grade,
      'stream': stream,
      'icon_asset': iconAsset,
      'sort_order': sortOrder,
      'scope': scope.name,
      'assessment_structure': assessmentStructure.name,
      'available_variants': availableVariants.map((v) => v.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        code,
        nameEn,
        nameAm,
        grade,
        stream,
        iconAsset,
        sortOrder,
        scope,
        assessmentStructure,
        availableVariants,
      ];
}

class Unit extends Equatable {
  final String id;
  final String subjectId;
  final int unitNumber;
  final String titleEn;
  final String titleAm;

  const Unit({
    required this.id,
    required this.subjectId,
    required this.unitNumber,
    required this.titleEn,
    required this.titleAm,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['id']?.toString() ?? '',
      subjectId: json['subject_id']?.toString() ?? '',
      unitNumber: (json['unit_number'] as num?)?.toInt() ?? 1,
      titleEn: json['title_en']?.toString() ?? '',
      titleAm: json['title_am']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject_id': subjectId,
      'unit_number': unitNumber,
      'title_en': titleEn,
      'title_am': titleAm,
    };
  }

  @override
  List<Object?> get props => [id, subjectId, unitNumber, titleEn, titleAm];
}

class Topic extends Equatable {
  final String id;
  final String unitId;
  final int topicNumber;
  final String titleEn;
  final String titleAm;

  const Topic({
    required this.id,
    required this.unitId,
    required this.topicNumber,
    required this.titleEn,
    required this.titleAm,
  });

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      id: json['id']?.toString() ?? '',
      unitId: json['unit_id']?.toString() ?? '',
      topicNumber: (json['topic_number'] as num?)?.toInt() ?? 1,
      titleEn: json['title_en']?.toString() ?? '',
      titleAm: json['title_am']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'unit_id': unitId,
      'topic_number': topicNumber,
      'title_en': titleEn,
      'title_am': titleAm,
    };
  }

  @override
  List<Object?> get props => [id, unitId, topicNumber, titleEn, titleAm];
}

class ContentPackage extends Equatable {
  final String packageId;
  final String subjectId;
  final String nameEn;
  final String nameAm;
  final int grade;
  final String stream;
  final int version;
  final int sizeBytes;
  final String publisher;
  final String license;
  final String attribution;
  final bool isDownloaded;
  final bool hasUpdate;
  final int? availableVersion;
  final int? updateSizeBytes;

  const ContentPackage({
    required this.packageId,
    required this.subjectId,
    required this.nameEn,
    required this.nameAm,
    required this.grade,
    required this.stream,
    required this.version,
    required this.sizeBytes,
    required this.publisher,
    required this.license,
    required this.attribution,
    required this.isDownloaded,
    this.hasUpdate = false,
    this.availableVersion,
    this.updateSizeBytes,
  });

  factory ContentPackage.fromJson(Map<String, dynamic> json) {
    return ContentPackage(
      packageId:
          json['package_id']?.toString() ?? (json['id']?.toString() ?? ''),
      subjectId: json['subject_id']?.toString() ?? '',
      nameEn: json['name_en']?.toString() ?? '',
      nameAm: json['name_am']?.toString() ?? '',
      grade: (json['grade'] as num?)?.toInt() ?? 12,
      stream: json['stream']?.toString() ?? 'common',
      version: (json['version'] as num?)?.toInt() ?? 1,
      sizeBytes: (json['size_bytes'] as num?)?.toInt() ?? 0,
      publisher:
          json['publisher']?.toString() ?? 'FidelLearn Original Demonstration',
      license: json['license']?.toString() ?? 'demo_evaluation',
      attribution: json['attribution']?.toString() ??
          'FidelLearn original demonstration content',
      isDownloaded: json['is_downloaded'] as bool? ?? false,
      hasUpdate: json['has_update'] as bool? ?? false,
      availableVersion: (json['available_version'] as num?)?.toInt(),
      updateSizeBytes: (json['update_size_bytes'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'package_id': packageId,
      'subject_id': subjectId,
      'name_en': nameEn,
      'name_am': nameAm,
      'grade': grade,
      'stream': stream,
      'version': version,
      'size_bytes': sizeBytes,
      'publisher': publisher,
      'license': license,
      'attribution': attribution,
      'is_downloaded': isDownloaded,
      'has_update': hasUpdate,
      'available_version': availableVersion,
      'update_size_bytes': updateSizeBytes,
    };
  }

  ContentPackage copyWith({
    bool? isDownloaded,
    int? version,
    bool? hasUpdate,
    int? availableVersion,
    int? updateSizeBytes,
  }) {
    return ContentPackage(
      packageId: packageId,
      subjectId: subjectId,
      nameEn: nameEn,
      nameAm: nameAm,
      grade: grade,
      stream: stream,
      version: version ?? this.version,
      sizeBytes: sizeBytes,
      publisher: publisher,
      license: license,
      attribution: attribution,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      hasUpdate: hasUpdate ?? this.hasUpdate,
      availableVersion: availableVersion ?? this.availableVersion,
      updateSizeBytes: updateSizeBytes ?? this.updateSizeBytes,
    );
  }

  @override
  List<Object?> get props => [
        packageId,
        subjectId,
        nameEn,
        nameAm,
        grade,
        stream,
        version,
        sizeBytes,
        publisher,
        license,
        attribution,
        isDownloaded,
        hasUpdate,
        availableVersion,
        updateSizeBytes,
      ];
}
