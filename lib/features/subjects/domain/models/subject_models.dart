import 'package:equatable/equatable.dart';

class Subject extends Equatable {
  final String id;
  final String code;
  final String nameEn;
  final String nameAm;
  final int grade;
  final String stream;
  final String? iconAsset;
  final int sortOrder;

  const Subject({
    required this.id,
    required this.code,
    required this.nameEn,
    required this.nameAm,
    required this.grade,
    required this.stream,
    this.iconAsset,
    required this.sortOrder,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      nameEn: json['name_en']?.toString() ?? '',
      nameAm: json['name_am']?.toString() ?? '',
      grade: (json['grade'] as num?)?.toInt() ?? 12,
      stream: json['stream']?.toString() ?? 'common',
      iconAsset: json['icon_asset']?.toString(),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
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
      packageId: json['package_id']?.toString() ??
          (json['id']?.toString() ?? ''),
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
