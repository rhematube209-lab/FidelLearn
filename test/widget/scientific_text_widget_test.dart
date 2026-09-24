import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/core/theme/app_theme.dart';
import 'package:fidel_learn/features/question_bank/presentation/widgets/scientific_text.dart';
import 'package:fidel_learn/features/question_bank/presentation/widgets/scientific_table_viewer.dart';
import 'package:flutter_math_fork/flutter_math.dart';

void main() {
  group('ScientificText Widget Tests', () {
    testWidgets('renders plain text cleanly without math widgets',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScientificText(
              text: 'This is a standard text explanation with no formulas.',
            ),
          ),
        ),
      );

      expect(find.text('This is a standard text explanation with no formulas.'),
          findsOneWidget);
      expect(find.byType(Math), findsNothing);
    });

    testWidgets('renders inline math expressions with Flutter Math KaTeX',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScientificText(
              text:
                  'According to Einstein, \\( E = mc^2 \\) relates mass to energy.',
            ),
          ),
        ),
      );

      expect(find.byType(Math), findsOneWidget);
      expect(find.byType(ScientificText), findsOneWidget);
    });

    testWidgets(
        'renders block math expressions inside horizontal scroll container',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScientificText(
              text:
                  'Calculate the definite integral:\n\\[ \\int_{0}^{\\pi} \\sin(x)\\,dx \\]',
            ),
          ),
        ),
      );

      expect(find.byType(Math), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('renders chemical equation with state markers and arrows',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScientificText(
              text:
                  'Precipitation reaction:\n\\ce{AgNO3(aq) + NaCl(aq) -> AgCl(s) + NaNO3(aq)}',
            ),
          ),
        ),
      );

      // Chemistry block converts to TeX and renders via Math KaTeX
      expect(find.byType(Math), findsOneWidget);
    });

    testWidgets('renders Markdown data tables via ScientificTableViewer',
        (tester) async {
      const tableMarkdown = '''
| Element | Symbol | Atomic Number |
| --- | --- | --- |
| Hydrogen | H | 1 |
| Helium | He | 2 |
''';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScientificText(
              text: tableMarkdown,
            ),
          ),
        ),
      );

      expect(find.byType(ScientificTableViewer), findsOneWidget);
      expect(find.text('Element'), findsOneWidget);
      expect(find.text('Hydrogen'), findsOneWidget);
      expect(find.text('Helium'), findsOneWidget);
    });

    testWidgets('adapts styling in Cosmic Dark vs Lavender Light themes',
        (tester) async {
      // Dark Theme test
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: ScientificText(
              text: 'Energy is given by \\( E = hf \\).',
            ),
          ),
        ),
      );
      expect(find.byType(Math), findsOneWidget);

      // Light Theme test
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: ScientificText(
              text: 'Energy is given by \\( E = hf \\).',
            ),
          ),
        ),
      );
      expect(find.byType(Math), findsOneWidget);
    });

    testWidgets('falls back safely without crashing on malformed formulas',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScientificText(
              text: 'Malformed formula: \\( \\frac{1}{ \\) should not crash.',
            ),
          ),
        ),
      );

      // Does not throw and displays content gracefully
      expect(find.byType(ScientificText), findsOneWidget);
    });
  });
}
