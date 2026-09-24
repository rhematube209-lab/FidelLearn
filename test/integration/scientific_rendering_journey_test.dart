import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/core/theme/app_theme.dart';
import 'package:fidel_learn/core/widgets/fidel_option_card.dart';
import 'package:fidel_learn/features/question_bank/domain/models/diagram_models.dart';
import 'package:fidel_learn/features/question_bank/domain/models/question_models.dart';
import 'package:fidel_learn/features/question_bank/presentation/widgets/question_diagram_viewer.dart';
import 'package:fidel_learn/features/question_bank/presentation/widgets/scientific_table_viewer.dart';
import 'package:fidel_learn/features/question_bank/presentation/widgets/scientific_text.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  group('Scientific Rendering End-to-End Journeys (Offline)', () {
    // 1. Mathematics: Grade 12 Calculus Journey
    testWidgets(
        'Mathematics Journey: renders limits, definite integrals, and formula options',
        (tester) async {
      String? selectedOption;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      // Question prompt with calculus integral
                      const ScientificText(
                        text:
                            'Evaluate the definite integral:\n\\[ \\int_{0}^{1} (3x^2 - 2x + 1)\\,dx \\]\nand determine the value of \\( \\lim_{x \\to 0} \\frac{\\sin x}{x} \\).',
                      ),
                      const SizedBox(height: 16),
                      // Options with mathematical formulas
                      FidelOptionCard(
                        label: 'A',
                        textEn: '\\( \\frac{1}{2} \\)',
                        state: selectedOption == 'A'
                            ? FidelOptionState.selected
                            : FidelOptionState.unselected,
                        onTap: () => setState(() => selectedOption = 'A'),
                      ),
                      FidelOptionCard(
                        label: 'B',
                        textEn: '\\( 1 \\)',
                        state: selectedOption == 'B'
                            ? FidelOptionState.selected
                            : FidelOptionState.unselected,
                        onTap: () => setState(() => selectedOption = 'B'),
                      ),
                      FidelOptionCard(
                        label: 'C',
                        textEn: '\\( 2 \\)',
                        state: selectedOption == 'C'
                            ? FidelOptionState.selected
                            : FidelOptionState.unselected,
                        onTap: () => setState(() => selectedOption = 'C'),
                      ),
                      FidelOptionCard(
                        label: 'D',
                        textEn: '\\( \\pi \\)',
                        state: selectedOption == 'D'
                            ? FidelOptionState.selected
                            : FidelOptionState.unselected,
                        onTap: () => setState(() => selectedOption = 'D'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Verify question and formulas rendered
      expect(find.byType(Math), findsWidgets);
      expect(find.byType(ScientificText), findsWidgets);

      // Tap option B
      await tester.tap(find.text('B'));
      await tester.pumpAndSettle();
      expect(selectedOption, equals('B'));
    });

    // 2. Physics: Circuit Diagram & Vector Formula Journey
    testWidgets(
        'Physics Journey: renders SVG circuit diagram and vector mechanics equations',
        (tester) async {
      const circuitSvg = '''
<svg viewBox="0 0 200 120" xmlns="http://www.w3.org/2000/svg">
  <rect x="10" y="10" width="180" height="100" fill="none" stroke="#6366F1" stroke-width="2" />
  <circle cx="100" cy="60" r="20" fill="#10B981" />
</svg>
''';

      const physicsQuestion = Question(
        id: 'q_phys_circuit',
        grade: 12,
        stream: 'natural',
        subjectId: 'physics_g12',
        unitId: 'unit_4',
        topicId: 'circuits',
        difficulty: 'hard',
        questionTextEn:
            'In the circuit diagram below, calculate the current using Ohm\'s law \\( I = \\frac{V}{R} \\) and Newton\'s law \\( \\vec{F} = m\\vec{a} \\):',
        verificationStatus: VerificationStatus.published,
        sourceName: 'ESSLCE National Archive',
        contentVersion: 1,
        vectorDiagram: VectorDiagram(
          id: 'v_circ_1',
          titleEn: 'Circuit Diagram with Resistor & Source',
          rawSvgContent: circuitSvg,
          viewBoxWidth: 200,
          viewBoxHeight: 120,
          caption: 'Figure 4.2: Closed DC circuit loop',
        ),
        choices: [
          AnswerChoice(id: 'c1', label: 'A', textEn: '2.5 A', isCorrect: true),
        ],
        explanation: Explanation(
          solutionTextEn:
              'Using Kirchhoff\'s loop rule: \\[ \\sum V = 0 \\implies I = \\frac{V_{total}}{R_{eq}} = 2.5\\,\\text{A} \\]',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  ScientificText(text: physicsQuestion.questionTextEn),
                  const QuestionDiagramViewer(question: physicsQuestion),
                  ScientificText(
                      text: physicsQuestion.explanation.solutionTextEn),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify SVG and KaTeX Math rendered (KaTeX also uses SVG for vector arrows)
      expect(find.byType(QuestionDiagramViewer), findsOneWidget);
      expect(find.byType(SvgPicture), findsWidgets);
      expect(
          find.text('Circuit Diagram with Resistor & Source'), findsOneWidget);
      expect(find.byType(Math), findsWidgets);
    });

    // 3. Chemistry: Ionic Notation & Reaction Equations Journey
    testWidgets(
        'Chemistry Journey: renders chemical equations, ionic notation, and state markers',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  ScientificText(
                    text:
                        'Consider the equilibrium reaction for the Haber process:\n\\[ N_2(g) + 3H_2(g) \\rightleftharpoons 2NH_3(g) \\]\nWhat is the charge on the calcium ion \\( Ca^{2+} \\) and sulfate ion \\( SO_4^{2-} \\)?',
                  ),
                  SizedBox(height: 12),
                  ScientificText(
                    text:
                        'Precipitation reaction:\n\\ce{AgNO3(aq) + NaCl(aq) -> AgCl(s) + NaNO3(aq)}',
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify KaTeX math rendered for reactions and ions
      expect(find.byType(Math), findsWidgets);
    });

    // 4. Biology & Social Science: Tables and Multidisciplinary Data Journey
    testWidgets(
        'Social Science & Biology: renders experimental tables and bilingual content',
        (tester) async {
      const bioTableMarkdown = '''
| Blood Group | Antigens on RBCs | Antibodies in Plasma | Can Receive From |
| --- | --- | --- | --- |
| A | A antigen | Anti-B | A, O |
| B | B antigen | Anti-A | B, O |
| AB | Both A and B | None | Universal Recipient |
| O | Neither | Both Anti-A and Anti-B | O only |
''';

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  ScientificText(
                    text:
                        'ABO Blood Group System Compatibility (የደም አይነት ተኳሃኝነት):\n$bioTableMarkdown',
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Table viewer successfully rendered
      expect(find.byType(ScientificTableViewer), findsOneWidget);
      expect(find.text('Blood Group'), findsOneWidget);
      expect(find.text('Universal Recipient'), findsOneWidget);
    });
  });
}
