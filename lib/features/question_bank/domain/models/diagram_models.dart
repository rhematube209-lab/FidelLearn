import 'package:equatable/equatable.dart';

class DiagramHotspot extends Equatable {
  final String id;
  final double xRatio; // 0.0 to 1.0 relative to viewBoxWidth
  final double yRatio; // 0.0 to 1.0 relative to viewBoxHeight
  final String label;
  final String descriptionEn;
  final String? descriptionAm;

  const DiagramHotspot({
    required this.id,
    required this.xRatio,
    required this.yRatio,
    required this.label,
    required this.descriptionEn,
    this.descriptionAm,
  });

  factory DiagramHotspot.fromJson(Map<String, dynamic> json) {
    return DiagramHotspot(
      id: json['id'] as String? ?? '',
      xRatio: (json['x_ratio'] as num?)?.toDouble() ?? 0.5,
      yRatio: (json['y_ratio'] as num?)?.toDouble() ?? 0.5,
      label: json['label'] as String? ?? '',
      descriptionEn: json['description_en'] as String? ?? '',
      descriptionAm: json['description_am'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'x_ratio': xRatio,
      'y_ratio': yRatio,
      'label': label,
      'description_en': descriptionEn,
      'description_am': descriptionAm,
    };
  }

  @override
  List<Object?> get props => [
        id,
        xRatio,
        yRatio,
        label,
        descriptionEn,
        descriptionAm,
      ];
}

class VectorDiagram extends Equatable {
  final String id;
  final String titleEn;
  final String? titleAm;
  final String rawSvgContent;
  final double viewBoxWidth;
  final double viewBoxHeight;
  final String? caption;
  final List<DiagramHotspot> hotspots;

  const VectorDiagram({
    required this.id,
    required this.titleEn,
    this.titleAm,
    required this.rawSvgContent,
    this.viewBoxWidth = 400.0,
    this.viewBoxHeight = 300.0,
    this.caption,
    this.hotspots = const [],
  });

  factory VectorDiagram.fromJson(Map<String, dynamic> json) {
    return VectorDiagram(
      id: json['id'] as String? ?? '',
      titleEn: json['title_en'] as String? ?? '',
      titleAm: json['title_am'] as String?,
      rawSvgContent: json['raw_svg_content'] as String? ?? '',
      viewBoxWidth: (json['view_box_width'] as num?)?.toDouble() ?? 400.0,
      viewBoxHeight: (json['view_box_height'] as num?)?.toDouble() ?? 300.0,
      caption: json['caption'] as String?,
      hotspots: (json['hotspots'] as List<dynamic>?)
              ?.map((h) => DiagramHotspot.fromJson(h as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title_en': titleEn,
      'title_am': titleAm,
      'raw_svg_content': rawSvgContent,
      'view_box_width': viewBoxWidth,
      'view_box_height': viewBoxHeight,
      'caption': caption,
      'hotspots': hotspots.map((h) => h.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        titleEn,
        titleAm,
        rawSvgContent,
        viewBoxWidth,
        viewBoxHeight,
        caption,
        hotspots,
      ];
}
