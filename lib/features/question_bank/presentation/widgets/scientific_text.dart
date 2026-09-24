import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/scientific_content_models.dart';
import '../../domain/services/scientific_content_parser.dart';
import 'scientific_table_viewer.dart';

/// Universal high-performance scientific text widget that seamlessly renders
/// mixed English/Amharic text, inline LaTeX mathematics, block formulas,
/// chemical equations, and markdown tables.
class ScientificText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final double mathScale;
  final Color? mathColor;
  final bool enableHorizontalScroll;
  final int? maxLines;
  final TextOverflow? overflow;

  const ScientificText({
    super.key,
    required this.text,
    this.style,
    this.textAlign = TextAlign.start,
    this.mathScale = 1.0,
    this.mathColor,
    this.enableHorizontalScroll = true,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultTextColor =
        isDark ? AppTheme.darkText : const Color(0xFF0F172A);
    final effectiveStyle = (style ?? const TextStyle()).copyWith(
      color: style?.color ?? defaultTextColor,
    );
    final effectiveMathColor = mathColor ?? style?.color ?? defaultTextColor;

    final blocks = ScientificContentParser.instance.parse(text);

    // If pure text without formulas, render standard Text widget for optimal performance
    if (blocks.length == 1 &&
        blocks.first.type == ScientificBlockType.plainText) {
      return Text(
        blocks.first.content,
        style: effectiveStyle,
        textAlign: textAlign,
      );
    }

    // Check if there are any block-level elements (blockMath, table)
    final hasBlockElements = blocks.any(
      (b) =>
          b.type == ScientificBlockType.blockMath ||
          b.type == ScientificBlockType.table ||
          b.type == ScientificBlockType.chemicalEquation,
    );

    if (!hasBlockElements) {
      // Inline-only stream: render as a unified RichText with WidgetSpans
      return _buildInlineRichText(blocks, effectiveStyle, effectiveMathColor);
    }

    // Mixed block-level & inline content: render as a Column
    final List<Widget> children = [];
    final List<ScientificContentBlock> inlineBuffer = [];

    for (final block in blocks) {
      if (block.type == ScientificBlockType.blockMath ||
          block.type == ScientificBlockType.chemicalEquation ||
          block.type == ScientificBlockType.table) {
        // Flush inline buffer
        if (inlineBuffer.isNotEmpty) {
          children.add(
            _buildInlineRichText(
                List.from(inlineBuffer), effectiveStyle, effectiveMathColor),
          );
          inlineBuffer.clear();
        }

        // Render block element
        if (block.type == ScientificBlockType.blockMath) {
          children
              .add(_buildBlockMath(block.content, effectiveMathColor, isDark));
        } else if (block.type == ScientificBlockType.chemicalEquation) {
          children.add(_buildChemicalEquation(
              block.content, effectiveMathColor, isDark));
        } else if (block.type == ScientificBlockType.table) {
          children.add(_buildTable(block, isDark));
        }
      } else {
        inlineBuffer.add(block);
      }
    }

    if (inlineBuffer.isNotEmpty) {
      children.add(
        _buildInlineRichText(inlineBuffer, effectiveStyle, effectiveMathColor),
      );
    }

    return Column(
      crossAxisAlignment: textAlign == TextAlign.center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  /// Builds an inline rich text span combining text and inline math.
  Widget _buildInlineRichText(
    List<ScientificContentBlock> blocks,
    TextStyle effectiveStyle,
    Color mathColor,
  ) {
    final spans = <InlineSpan>[];

    for (final block in blocks) {
      if (block.type == ScientificBlockType.plainText) {
        spans.add(TextSpan(text: block.content, style: effectiveStyle));
      } else if (block.type == ScientificBlockType.inlineMath) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            baseline: TextBaseline.alphabetic,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5),
              child: _buildMathTex(
                block.content,
                MathStyle.text,
                mathColor,
                effectiveStyle.fontSize ?? 15.0,
              ),
            ),
          ),
        );
      }
    }

    return Text.rich(
      TextSpan(children: spans),
      textAlign: textAlign,
    );
  }

  /// Builds a prominent, centered block math formula with horizontal scroll safety.
  Widget _buildBlockMath(String tex, Color color, bool isDark) {
    Widget mathContent = _buildMathTex(
      tex,
      MathStyle.display,
      color,
      (style?.fontSize ?? 16.0) * 1.15,
    );

    if (enableHorizontalScroll) {
      mathContent = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: mathContent,
      );
    }

    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0x1A4F46E5) : const Color(0x0A4F46E5),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isDark ? const Color(0x334F46E5) : const Color(0x1F4F46E5),
          width: 1,
        ),
      ),
      child: Center(child: mathContent),
    );
  }

  /// Builds a dedicated chemical reaction equation block.
  Widget _buildChemicalEquation(String tex, Color color, bool isDark) {
    Widget chemContent = _buildMathTex(
      tex,
      MathStyle.display,
      color,
      (style?.fontSize ?? 15.0) * 1.1,
    );

    if (enableHorizontalScroll) {
      chemContent = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: chemContent,
      );
    }

    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0x1A10B981) : const Color(0x0C10B981),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isDark ? const Color(0x3310B981) : const Color(0x2410B981),
          width: 1,
        ),
      ),
      child: Center(child: chemContent),
    );
  }

  /// Builds a rendered markdown data table.
  Widget _buildTable(ScientificContentBlock block, bool isDark) {
    final headers = (block.metadata['headers'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];
    final rows = (block.metadata['rows'] as List<dynamic>?)
            ?.map((r) => (r as List<dynamic>).map((e) => e.toString()).toList())
            .toList() ??
        const [];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: ScientificTableViewer(
        headers: headers,
        rows: rows,
        caption: block.caption,
      ),
    );
  }

  /// Native KaTeX math rendering with fallback guard for malformed syntax.
  Widget _buildMathTex(
    String tex,
    MathStyle mathStyle,
    Color color,
    double baseFontSize,
  ) {
    return Math.tex(
      tex,
      mathStyle: mathStyle,
      textStyle: TextStyle(
        fontSize: baseFontSize * mathScale,
        color: color,
        fontWeight: FontWeight.w500,
      ),
      onErrorFallback: (FlutterMathException err) {
        // Safe runtime error fallback preventing crashes
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0x1FEF4444),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0x4DEF4444)),
          ),
          child: Text(
            tex,
            style: TextStyle(
              fontSize: baseFontSize * 0.9,
              color: const Color(0xFFEF4444),
              fontFamily: 'monospace',
            ),
          ),
        );
      },
    );
  }
}
