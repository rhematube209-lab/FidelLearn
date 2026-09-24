import 'package:equatable/equatable.dart';

/// Supported types of scientific visual assets packaged in .flpkg archives.
enum ScientificAssetType {
  svgDiagram,
  rasterImage,
  chemicalStructure,
  circuitDiagram,
  biologicalDiagram,
  geographicMap,
  economicGraph,
  generic;

  static ScientificAssetType fromString(String val) {
    switch (val.toLowerCase().replaceAll('-', '_')) {
      case 'svg':
      case 'svg_diagram':
        return ScientificAssetType.svgDiagram;
      case 'raster':
      case 'image':
      case 'raster_image':
        return ScientificAssetType.rasterImage;
      case 'chemical':
      case 'chemical_structure':
        return ScientificAssetType.chemicalStructure;
      case 'circuit':
      case 'circuit_diagram':
        return ScientificAssetType.circuitDiagram;
      case 'biology':
      case 'biological_diagram':
        return ScientificAssetType.biologicalDiagram;
      case 'map':
      case 'geographic_map':
        return ScientificAssetType.geographicMap;
      case 'graph':
      case 'economic_graph':
        return ScientificAssetType.economicGraph;
      default:
        return ScientificAssetType.generic;
    }
  }
}

/// Metadata record for a single scientific asset bundled inside a .flpkg package.
class ScientificAssetEntry extends Equatable {
  final String assetId;
  final ScientificAssetType assetType;
  final String assetPath;
  final String? checksum;
  final String? requiredByQuestion;
  final int contentVersion;
  final double? width;
  final double? height;
  final String? altText;
  final String? caption;
  final String? sourceReference;
  final bool isRequired;

  const ScientificAssetEntry({
    required this.assetId,
    required this.assetType,
    required this.assetPath,
    this.checksum,
    this.requiredByQuestion,
    this.contentVersion = 1,
    this.width,
    this.height,
    this.altText,
    this.caption,
    this.sourceReference,
    this.isRequired = true,
  });

  factory ScientificAssetEntry.fromJson(Map<String, dynamic> json) {
    return ScientificAssetEntry(
      assetId: json['asset_id']?.toString() ?? '',
      assetType: ScientificAssetType.fromString(
          json['asset_type']?.toString() ?? 'generic'),
      assetPath: json['asset_path']?.toString() ?? '',
      checksum: json['checksum']?.toString(),
      requiredByQuestion: json['required_by_question']?.toString(),
      contentVersion: (json['content_version'] as num?)?.toInt() ?? 1,
      width: (json['width'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      altText: json['alt_text']?.toString(),
      caption: json['caption']?.toString(),
      sourceReference: json['source_reference']?.toString(),
      isRequired: json['is_required'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'asset_id': assetId,
      'asset_type': assetType.name,
      'asset_path': assetPath,
      if (checksum != null) 'checksum': checksum,
      if (requiredByQuestion != null)
        'required_by_question': requiredByQuestion,
      'content_version': contentVersion,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (altText != null) 'alt_text': altText,
      if (caption != null) 'caption': caption,
      if (sourceReference != null) 'source_reference': sourceReference,
      'is_required': isRequired,
    };
  }

  @override
  List<Object?> get props => [
        assetId,
        assetType,
        assetPath,
        checksum,
        requiredByQuestion,
        contentVersion,
        width,
        height,
        altText,
        caption,
        sourceReference,
        isRequired,
      ];
}

/// Package-level manifest declaring all required scientific assets.
class ScientificAssetManifest extends Equatable {
  final String packageId;
  final int version;
  final List<ScientificAssetEntry> assets;

  const ScientificAssetManifest({
    required this.packageId,
    required this.version,
    required this.assets,
  });

  factory ScientificAssetManifest.fromJson(Map<String, dynamic> json) {
    return ScientificAssetManifest(
      packageId: json['package_id']?.toString() ?? '',
      version: (json['version'] as num?)?.toInt() ?? 1,
      assets: (json['assets'] as List<dynamic>?)
              ?.map((a) =>
                  ScientificAssetEntry.fromJson(a as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'package_id': packageId,
      'version': version,
      'assets': assets.map((a) => a.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [packageId, version, assets];
}
