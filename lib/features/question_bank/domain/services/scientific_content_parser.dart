import 'package:equatable/equatable.dart';
import '../models/scientific_content_models.dart';

/// High-performance deterministic parser that decomposes mixed scientific text
/// into structured [ScientificContentBlock] items (text, inline math, block math,
/// chemistry equations, and markdown tables).
class ScientificContentParser {
  ScientificContentParser._();

  static final ScientificContentParser instance = ScientificContentParser._();

  // Bounded LRU cache for parsed results (avoids re-parsing during list scroll)
  static const int _kMaxCacheSize = 500;
  final Map<String, List<ScientificContentBlock>> _cache = {};

  /// Parse an input string into a list of [ScientificContentBlock] elements.
  List<ScientificContentBlock> parse(String? input) {
    if (input == null || input.trim().isEmpty) {
      return const [];
    }

    final cached = _cache[input];
    if (cached != null) {
      return cached;
    }

    final blocks = _parseContent(input);

    if (_cache.length >= _kMaxCacheSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[input] = blocks;

    return blocks;
  }

  /// Clear the memoization cache.
  void clearCache() {
    _cache.clear();
  }

  List<ScientificContentBlock> _parseContent(String input) {
    final List<ScientificContentBlock> result = [];

    // 1. Check if input contains a Markdown Table
    final lines = input.split('\n');
    final List<String> currentParagraphLines = [];
    int i = 0;

    while (i < lines.length) {
      final line = lines[i];
      final trimmed = line.trim();

      // Detect table row: starts and ends with '|' or contains multiple '|'
      if (trimmed.startsWith('|') &&
          trimmed.endsWith('|') &&
          trimmed.length > 2) {
        // Flush previous paragraph
        if (currentParagraphLines.isNotEmpty) {
          final paragraphText = currentParagraphLines.join('\n');
          result.addAll(_parseParagraph(paragraphText));
          currentParagraphLines.clear();
        }

        // Collect full table block
        final List<String> tableLines = [];
        while (i < lines.length &&
            lines[i].trim().startsWith('|') &&
            lines[i].trim().endsWith('|')) {
          tableLines.add(lines[i].trim());
          i++;
        }

        final tableBlock = _parseMarkdownTable(tableLines);
        if (tableBlock != null) {
          result.add(tableBlock);
        }
        continue;
      }

      currentParagraphLines.add(line);
      i++;
    }

    if (currentParagraphLines.isNotEmpty) {
      final paragraphText = currentParagraphLines.join('\n');
      result.addAll(_parseParagraph(paragraphText));
    }

    return result;
  }

  /// Parses text containing inline/block math and chemistry equations.
  List<ScientificContentBlock> _parseParagraph(String text) {
    final List<ScientificContentBlock> blocks = [];

    // Regular expressions for block math, inline math, and chemical equations
    // 1. Block Math: $$...$$ or \[...\]
    // 2. Chemical Equation: \ce{...}
    // 3. Inline Math: \(...\) or $...$
    final combinedRegex = RegExp(
      r'(\$\$(.+?)\$\$|\\\[(.+?)\\\]|\\ce\{(.+?)\}|\\\((.+?)\\\)|\$([^\$\n]+?)\$)',
      dotAll: true,
    );

    int lastIndex = 0;
    for (final match in combinedRegex.allMatches(text)) {
      if (match.start > lastIndex) {
        final plain = text.substring(lastIndex, match.start);
        if (plain.isNotEmpty) {
          // Check if plain segment contains standalone chemistry notation
          blocks.addAll(_detectImplicitChemistryOrText(plain));
        }
      }

      final matchedStr = match.group(0)!;

      if (matchedStr.startsWith(r'$$') && matchedStr.endsWith(r'$$')) {
        // $$...$$ Block Math
        final tex = match.group(2) ?? '';
        blocks.add(ScientificContentBlock.blockMath(tex.trim()));
      } else if (matchedStr.startsWith(r'\[') && matchedStr.endsWith(r'\]')) {
        // \[...\] Block Math
        final tex = match.group(3) ?? '';
        blocks.add(ScientificContentBlock.blockMath(tex.trim()));
      } else if (matchedStr.startsWith(r'\ce{') && matchedStr.endsWith('}')) {
        // \ce{...} Chemical Equation
        final chemContent = match.group(4) ?? '';
        final convertedTex = chemistryToTex(chemContent.trim());
        blocks.add(ScientificContentBlock.chemistry(convertedTex));
      } else if (matchedStr.startsWith(r'\(') && matchedStr.endsWith(r'\)')) {
        // \(...\) Inline Math
        final tex = match.group(5) ?? '';
        blocks.add(ScientificContentBlock.inlineMath(tex.trim()));
      } else if (matchedStr.startsWith(r'$') && matchedStr.endsWith(r'$')) {
        // $...$ Inline Math
        final tex = match.group(6) ?? '';
        blocks.add(ScientificContentBlock.inlineMath(tex.trim()));
      }

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      final remaining = text.substring(lastIndex);
      if (remaining.isNotEmpty) {
        blocks.addAll(_detectImplicitChemistryOrText(remaining));
      }
    }

    return blocks;
  }

  /// Detects implicit chemistry reactions (e.g. containing → or ⇌ or -> with formulas)
  /// or returns plain text.
  List<ScientificContentBlock> _detectImplicitChemistryOrText(String text) {
    // If the line is an unadorned chemical reaction like:
    // "2H₂ + O₂ → 2H₂O" or "N₂ + 3H₂ ⇌ 2NH₃" or "AgNO₃(aq) + NaCl(aq) → AgCl(s) + NaNO₃(aq)"
    final trimmed = text.trim();
    final isExplicitReaction = (trimmed.contains('→') ||
            trimmed.contains('⇌') ||
            trimmed.contains('->') ||
            trimmed.contains('<=>')) &&
        RegExp(r'[A-Z][a-z]?[\d₀-₉]*').hasMatch(trimmed) &&
        !trimmed.contains('?') &&
        !trimmed.startsWith('Which') &&
        !trimmed.startsWith('What') &&
        !trimmed.contains('is called');

    if (isExplicitReaction && trimmed.length < 120 && !trimmed.contains('\n')) {
      final tex = chemistryToTex(trimmed);
      return [ScientificContentBlock.chemistry(tex)];
    }

    return [ScientificContentBlock.text(text)];
  }

  /// Parses a markdown table structure into [ScientificContentBlock.table].
  ScientificContentBlock? _parseMarkdownTable(List<String> lines) {
    if (lines.length < 2) return null;

    List<String>? headers;
    final List<List<String>> rows = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      // Split by '|' and trim cells
      final rawCells = line.split('|');
      // Remove leading and trailing empty items from surrounding '|'
      if (rawCells.length > 2) {
        final cells = rawCells
            .sublist(1, rawCells.length - 1)
            .map((c) => c.trim())
            .toList();

        // Check if this is the separator line (e.g. |---|---|)
        final isSeparator = cells.every((c) => RegExp(r'^:?-+:?$').hasMatch(c));
        if (isSeparator) {
          continue;
        }

        if (headers == null) {
          headers = cells;
        } else {
          rows.add(cells);
        }
      }
    }

    if (headers == null || headers.isEmpty) return null;

    final rawTable = lines.join('\n');
    return ScientificContentBlock.table(
      rawTable,
      headers: headers,
      rows: rows,
    );
  }

  /// Converts chemistry formulas and reactions into standard KaTeX-compatible LaTeX.
  /// Handles subscripts, superscripts, ions, reaction arrows, state of matter markers.
  static String chemistryToTex(String input) {
    var s = input.trim();

    // 1. Replace reaction arrows
    s = s.replaceAll('<=>', r' \rightleftharpoons ');
    s = s.replaceAll('⇌', r' \rightleftharpoons ');
    s = s.replaceAll('->', r' \rightarrow ');
    s = s.replaceAll('→', r' \rightarrow ');

    // 2. Handle state of matter indicators: (s), (l), (g), (aq)
    s = s.replaceAll(r'(aq)', r'\text{(aq)}');
    s = s.replaceAll(r'(s)', r'\text{(s)}');
    s = s.replaceAll(r'(l)', r'\text{(l)}');
    s = s.replaceAll(r'(g)', r'\text{(g)}');

    // 3. Convert contiguous Unicode subscripts to standard TeX subscripts
    const subMap = {
      '₀': '0',
      '₁': '1',
      '₂': '2',
      '₃': '3',
      '₄': '4',
      '₅': '5',
      '₆': '6',
      '₇': '7',
      '₈': '8',
      '₉': '9',
    };
    s = s.replaceAllMapped(RegExp(r'[₀₁₂₃₄₅₆₇₈₉]+'), (m) {
      final subChars = m.group(0)!.split('').map((c) => subMap[c] ?? c).join();
      return '_{$subChars}';
    });

    // 4. Convert contiguous Unicode superscripts & charge symbols to standard TeX superscripts
    // Note: ¹ (U+00B9), ² (U+00B2), and ³ (U+00B3) are in Latin-1, not contiguous with ⁴-⁹ (U+2074-U+2079)
    const supMap = {
      '⁰': '0',
      '¹': '1',
      '²': '2',
      '³': '3',
      '⁴': '4',
      '⁵': '5',
      '⁶': '6',
      '⁷': '7',
      '⁸': '8',
      '⁹': '9',
      '⁺': '+',
      '⁻': '-',
    };
    s = s.replaceAllMapped(RegExp(r'[⁰¹²³⁴⁵⁶⁷⁸⁹⁺⁻]+'), (m) {
      final supChars = m.group(0)!.split('').map((c) => supMap[c] ?? c).join();
      return '^{$supChars}';
    });

    // 5. Wrap chemical element symbols with \mathrm for upright chemical font
    // E.g. H2SO4 -> \mathrm{H}_2\mathrm{SO}_4
    // Replace standard ions like Ca^{2+} or SO_4^{2-}
    s = s.replaceAllMapped(
      RegExp(r'\^(\d+[\+\-]|\+|\-)'),
      (m) => '^{${m.group(1)}}',
    );

    // 6. Wrap numbers following chemical symbols with subscript braces
    s = s.replaceAllMapped(
      RegExp(r'_(\d+)'),
      (m) => '_{${m.group(1)}}',
    );

    // Format elements into \mathrm
    s = s.replaceAllMapped(
      RegExp(r'\b([A-Z][a-z]?)\b'),
      (m) => '\\mathrm{${m.group(1)!}}',
    );

    return s;
  }

  /// Converts a LaTeX matrix specification into standard TeX matrix environment.
  static String formatMatrix(List<List<dynamic>> rows, {String bracket = 'b'}) {
    final buffer = StringBuffer('\\begin{${bracket}matrix}\n');
    for (int i = 0; i < rows.length; i++) {
      buffer.write(rows[i].join(' & '));
      if (i < rows.length - 1) {
        buffer.write(' \\\\\n');
      } else {
        buffer.write('\n');
      }
    }
    buffer.write('\\end{${bracket}matrix}');
    return buffer.toString();
  }

  /// Validates if a formula string has balanced delimiters and syntax.
  static FormulaValidationResult validateFormula(String tex) {
    if (tex.trim().isEmpty) {
      return const FormulaValidationResult(
        isValid: false,
        error: 'Formula is empty.',
      );
    }

    // Check balanced curly braces
    int braceCount = 0;
    for (int i = 0; i < tex.length; i++) {
      if (tex[i] == '{') {
        if (i == 0 || tex[i - 1] != r'\') braceCount++;
      } else if (tex[i] == '}') {
        if (i == 0 || tex[i - 1] != r'\') braceCount--;
      }
      if (braceCount < 0) {
        return const FormulaValidationResult(
          isValid: false,
          error: 'Unmatched closing brace "}".',
        );
      }
    }

    if (braceCount != 0) {
      return const FormulaValidationResult(
        isValid: false,
        error: 'Unclosed opening brace "{".',
      );
    }

    // Check balanced brackets
    int bracketCount = 0;
    for (int i = 0; i < tex.length; i++) {
      if (tex[i] == '[') {
        if (i == 0 || tex[i - 1] != r'\') bracketCount++;
      } else if (tex[i] == ']') {
        if (i == 0 || tex[i - 1] != r'\') bracketCount--;
      }
      if (bracketCount < 0) {
        return const FormulaValidationResult(
          isValid: false,
          error: 'Unmatched closing bracket "]".',
        );
      }
    }

    if (bracketCount != 0) {
      return const FormulaValidationResult(
        isValid: false,
        error: 'Unclosed opening bracket "[".',
      );
    }

    return const FormulaValidationResult(isValid: true);
  }
}

/// Result of formula syntax validation.
class FormulaValidationResult extends Equatable {
  final bool isValid;
  final String? error;

  const FormulaValidationResult({
    required this.isValid,
    this.error,
  });

  @override
  List<Object?> get props => [isValid, error];
}
