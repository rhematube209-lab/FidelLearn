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
      id: json['id'] as String,
      code: json['code'] as String,
      nameEn: json['name_en'] as String,
      nameAm: json['name_am'] as String,
      grade: json['grade'] as int,
      stream: json['stream'] as String? ?? 'common',
      iconAsset: json['icon_asset'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
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
      id: json['id'] as String,
      subjectId: json['subject_id'] as String,
      unitNumber: json['unit_number'] as int,
      titleEn: json['title_en'] as String,
      titleAm: json['title_am'] as String,
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
      id: json['id'] as String,
      unitId: json['unit_id'] as String,
      topicNumber: json['topic_number'] as int,
      titleEn: json['title_en'] as String,
      titleAm: json['title_am'] as String,
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
  });

  factory ContentPackage.fromJson(Map<String, dynamic> json) {
    return ContentPackage(
      packageId: json['package_id'] as String,
      subjectId: json['subject_id'] as String,
      nameEn: json['name_en'] as String,
      nameAm: json['name_am'] as String,
      grade: json['grade'] as int,
      stream: json['stream'] as String,
      version: json['version'] as int? ?? 1,
      sizeBytes: json['size_bytes'] as int? ?? 0,
      publisher:
          json['publisher'] as String? ?? 'FidelLearn Original Demonstration',
      license: json['license'] as String? ?? 'demo_evaluation',
      attribution: json['attribution'] as String? ??
          'FidelLearn original demonstration content',
      isDownloaded: json['is_downloaded'] as bool? ?? false,
    );
  }

  ContentPackage copyWith({bool? isDownloaded, int? version}) {
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
      ];
}
