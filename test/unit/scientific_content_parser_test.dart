import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/features/question_bank/domain/models/scientific_content_models.dart';
import 'package:fidel_learn/features/question_bank/domain/services/scientific_content_parser.dart';

void main() {
  group('ScientificContentParser Unit Tests', () {
    late ScientificContentParser parser;

    setUp(() {
      parser = ScientificContentParser.instance;
      parser.clearCache();
    });

    test('1. Parses pure plain text into a single text block', () {
      const input = 'What is the SI unit of electric resistance?';
      final blocks = parser.parse(input);

      expect(blocks.length, equals(1));
      expect(blocks.first.type, equals(ScientificBlockType.plainText));
      expect(blocks.first.content, equals(input));
    });

    test('2. Parses inline math with \\( ... \\) and \$ ... \$ delimiters', () {
      const input =
          r'Using \( F = ma \), calculate the force when mass is $m = 5\text{ kg}$.';
      final blocks = parser.parse(input);

      expect(blocks.length, equals(5));
      expect(blocks[0].type, equals(ScientificBlockType.plainText));
      expect(blocks[0].content, equals('Using '));

      expect(blocks[1].type, equals(ScientificBlockType.inlineMath));
      expect(blocks[1].content, equals(r'F = ma'));

      expect(blocks[2].type, equals(ScientificBlockType.plainText));
      expect(blocks[2].content, equals(', calculate the force when mass is '));

      expect(blocks[3].type, equals(ScientificBlockType.inlineMath));
      expect(blocks[3].content, equals(r'm = 5\text{ kg}'));

      expect(blocks[4].type, equals(ScientificBlockType.plainText));
      expect(blocks[4].content, equals('.'));
    });

    test('3. Parses block math with \\[ ... \\] and \$\$ ... \$\$ delimiters',
        () {
      const input = r'''Consider the fundamental theorem of calculus:
\[
\int_a^b f(x)\,dx = F(b) - F(a)
\]
and the limit:
$$
\lim_{x \to 0} \frac{\sin x}{x} = 1
$$''';
      final blocks = parser.parse(input);

      final blockMaths =
          blocks.where((b) => b.type == ScientificBlockType.blockMath).toList();

      expect(blockMaths.length, equals(2));
      expect(blockMaths[0].content, equals(r'\int_a^b f(x)\,dx = F(b) - F(a)'));
      expect(blockMaths[1].content,
          equals(r'\lim_{x \to 0} \frac{\sin x}{x} = 1'));
    });

    test(
        '4. Parses advanced calculus, matrices, vectors, and piecewise functions',
        () {
      const input = r'''Given the 2x2 matrix:
\[
\begin{bmatrix}
a & b \\
c & d
\end{bmatrix}
\]
and vector acceleration \( \vec{F} = m\vec{a} \), evaluate piecewise:
\[
f(x) = \begin{cases} x^2, & x \ge 0 \\ -x, & x < 0 \end{cases}
\]''';
      final blocks = parser.parse(input);

      expect(blocks.any((b) => b.content.contains('begin{bmatrix}')), isTrue);
      expect(blocks.any((b) => b.content.contains(r'\vec{F}')), isTrue);
      expect(blocks.any((b) => b.content.contains('begin{cases}')), isTrue);
    });

    test('5. Parses chemistry reactions with \\ce{...} notation', () {
      const input =
          r'Identify the spectator ions in: \ce{AgNO3(aq) + NaCl(aq) -> AgCl(s) + NaNO3(aq)}';
      final blocks = parser.parse(input);

      final chemBlocks = blocks
          .where((b) => b.type == ScientificBlockType.chemicalEquation)
          .toList();

      expect(chemBlocks.length, equals(1));
      expect(chemBlocks.first.content, contains(r'\rightarrow'));
      expect(chemBlocks.first.content, contains(r'\text{(aq)}'));
      expect(chemBlocks.first.content, contains(r'\text{(s)}'));
    });

    test('6. Converts chemistry ionic charges and subscripts cleanly', () {
      const chemInput = 'Ca²⁺ + SO₄²⁻ → CaSO₄(s)';
      final tex = ScientificContentParser.chemistryToTex(chemInput);

      expect(tex, contains('^{2+}'));
      expect(tex, contains('_{4}'));
      expect(tex, contains(r'\rightarrow'));
      expect(tex, contains(r'\text{(s)}'));
    });

    test(
        '7. Parses markdown tables into structured TableBlock with headers and rows',
        () {
      const input = '''
Below are the experimental results:
| Element | Atomic Number | Mass (u) |
| :--- | :---: | ---: |
| Hydrogen | 1 | 1.008 |
| Helium | 2 | 4.0026 |
| Lithium | 3 | 6.94 |
Which element has the lowest mass?
''';
      final blocks = parser.parse(input);

      final tableBlocks =
          blocks.where((b) => b.type == ScientificBlockType.table).toList();

      expect(tableBlocks.length, equals(1));
      final table = tableBlocks.first;
      final headers = table.metadata['headers'] as List<String>;
      final rows = table.metadata['rows'] as List<List<String>>;

      expect(headers, equals(['Element', 'Atomic Number', 'Mass (u)']));
      expect(rows.length, equals(3));
      expect(rows[0], equals(['Hydrogen', '1', '1.008']));
      expect(rows[1], equals(['Helium', '2', '4.0026']));
      expect(rows[2], equals(['Lithium', '3', '6.94']));
    });

    test(
        '8. Formula validation detects balanced and malformed LaTeX expressions',
        () {
      // Valid expressions
      expect(
        ScientificContentParser.validateFormula(
                r'\int_a^b \frac{f(x)}{g(x)} dx')
            .isValid,
        isTrue,
      );
      expect(
        ScientificContentParser.validateFormula(
                r'\begin{bmatrix} 1 & 0 \\ 0 & 1 \end{bmatrix}')
            .isValid,
        isTrue,
      );

      // Malformed: unclosed brace
      final unclosedBrace =
          ScientificContentParser.validateFormula(r'\frac{a}{b');
      expect(unclosedBrace.isValid, isFalse);
      expect(unclosedBrace.error, contains('Unclosed opening brace'));

      // Malformed: unmatched closing brace
      final unmatchedBrace =
          ScientificContentParser.validateFormula(r'\frac{a}{b}}');
      expect(unmatchedBrace.isValid, isFalse);
      expect(unmatchedBrace.error, contains('Unmatched closing brace'));

      // Malformed: unclosed bracket
      final unclosedBracket =
          ScientificContentParser.validateFormula(r'\sqrt[3{x}');
      expect(unclosedBracket.isValid, isFalse);
      expect(unclosedBracket.error, contains('Unclosed opening bracket'));
    });

    test('9. Memoization cache prevents redundant parsing on identical strings',
        () {
      const text = r'Calculate \( E = mc^2 \).';

      final result1 = parser.parse(text);
      final result2 = parser.parse(text);

      expect(identical(result1, result2), isTrue);
    });
  });
}
