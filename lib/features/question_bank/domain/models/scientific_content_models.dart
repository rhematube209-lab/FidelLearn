import 'package:equatable/equatable.dart';

/// Semantic type of a structured scientific content block.
enum ScientificBlockType {
  plainText,
  inlineMath,
  blockMath,
  chemicalEquation,
  table,
  svgDiagram,
  imageDiagram,
  graph,
}

/// A structured content block representing scientific notation, formulas,
/// diagrams, tables, or standard text.
class ScientificContentBlock extends Equatable {
  final ScientificBlockType type;
  final String content;
  final String? altText;
  final String? assetReference;
  final String? caption;
  final String? accessibilityLabel;
  final Map<String, dynamic> metadata;

  const ScientificContentBlock({
    required this.type,
    required this.content,
    this.altText,
    this.assetReference,
    this.caption,
    this.accessibilityLabel,
    this.metadata = const {},
  });

  /// Factory constructors for convenient block construction
  factory ScientificContentBlock.text(String text) => ScientificContentBlock(
        type: ScientificBlockType.plainText,
        content: text,
      );

  factory ScientificContentBlock.inlineMath(String tex, {String? altText}) =>
      ScientificContentBlock(
        type: ScientificBlockType.inlineMath,
        content: tex,
        altText: altText,
        accessibilityLabel: altText ?? 'Mathematical expression: $tex',
      );

  factory ScientificContentBlock.blockMath(String tex,
          {String? caption, String? altText}) =>
      ScientificContentBlock(
        type: ScientificBlockType.blockMath,
        content: tex,
        caption: caption,
        altText: altText,
        accessibilityLabel: altText ?? 'Formula: $tex',
      );

  factory ScientificContentBlock.chemistry(String equation,
          {String? caption, String? altText}) =>
      ScientificContentBlock(
        type: ScientificBlockType.chemicalEquation,
        content: equation,
        caption: caption,
        altText: altText,
        accessibilityLabel: altText ?? 'Chemical reaction: $equation',
      );

  factory ScientificContentBlock.table(
    String rawTable, {
    String? caption,
    List<String>? headers,
    List<List<String>>? rows,
  }) =>
      ScientificContentBlock(
        type: ScientificBlockType.table,
        content: rawTable,
        caption: caption,
        metadata: {
          if (headers != null) 'headers': headers,
          if (rows != null) 'rows': rows,
        },
      );

  factory ScientificContentBlock.svgDiagram({
    required String rawSvg,
    String? caption,
    String? altText,
    double viewBoxWidth = 400.0,
    double viewBoxHeight = 300.0,
  }) =>
      ScientificContentBlock(
        type: ScientificBlockType.svgDiagram,
        content: rawSvg,
        caption: caption,
        altText: altText,
        metadata: {
          'viewBoxWidth': viewBoxWidth,
          'viewBoxHeight': viewBoxHeight,
        },
      );

  factory ScientificContentBlock.imageDiagram({
    required String assetPath,
    String? caption,
    String? altText,
  }) =>
      ScientificContentBlock(
        type: ScientificBlockType.imageDiagram,
        content: assetPath,
        assetReference: assetPath,
        caption: caption,
        altText: altText,
      );

  factory ScientificContentBlock.graph({
    required String graphData,
    String? caption,
    String? altText,
    String graphType = 'line',
  }) =>
      ScientificContentBlock(
        type: ScientificBlockType.graph,
        content: graphData,
        caption: caption,
        altText: altText,
        metadata: {'graphType': graphType},
      );

  factory ScientificContentBlock.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type']?.toString() ?? 'plainText';
    final type = ScientificBlockType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => ScientificBlockType.plainText,
    );

    return ScientificContentBlock(
      type: type,
      content: json['content']?.toString() ?? '',
      altText: json['alt_text']?.toString(),
      assetReference: json['asset_reference']?.toString(),
      caption: json['caption']?.toString(),
      accessibilityLabel: json['accessibility_label']?.toString(),
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'content': content,
      if (altText != null) 'alt_text': altText,
      if (assetReference != null) 'asset_reference': assetReference,
      if (caption != null) 'caption': caption,
      if (accessibilityLabel != null) 'accessibility_label': accessibilityLabel,
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
        type,
        content,
        altText,
        assetReference,
        caption,
        accessibilityLabel,
        metadata,
      ];
}

/// Structured representation of parsed exam data tables.
class ScientificTableData extends Equatable {
  final List<String> headers;
  final List<List<String>> rows;
  final String? caption;

  const ScientificTableData({
    required this.headers,
    required this.rows,
    this.caption,
  });

  @override
  List<Object?> get props => [headers, rows, caption];
}
