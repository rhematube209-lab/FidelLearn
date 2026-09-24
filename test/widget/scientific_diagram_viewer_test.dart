import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/features/question_bank/domain/models/diagram_models.dart';
import 'package:fidel_learn/features/question_bank/domain/models/question_models.dart';
import 'package:fidel_learn/features/question_bank/presentation/widgets/fullscreen_diagram_modal.dart';
import 'package:fidel_learn/features/question_bank/presentation/widgets/question_diagram_viewer.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  group('Scientific Diagram & Fullscreen Viewer Tests', () {
    const sampleSvg = '''
<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <circle cx="50" cy="50" r="40" stroke="green" stroke-width="4" fill="yellow" />
</svg>
''';

    const testVectorDiagram = VectorDiagram(
      id: 'diag_1',
      titleEn: 'Figure 1.1: Circular magnetic flux boundary',
      rawSvgContent: sampleSvg,
      viewBoxWidth: 100,
      viewBoxHeight: 100,
      caption: 'Figure 1.1: Circular magnetic flux boundary',
    );

    const baseQuestion = Question(
      id: 'q_diag_test',
      grade: 12,
      stream: 'natural',
      subjectId: 'physics_g12',
      unitId: 'unit_1',
      topicId: 'topic_1',
      difficulty: 'medium',
      questionTextEn: 'Refer to the diagram below:',
      verificationStatus: VerificationStatus.published,
      sourceName: 'National Exam',
      contentVersion: 1,
      choices: [],
      explanation: Explanation(solutionTextEn: 'Explanation'),
    );

    testWidgets('QuestionDiagramViewer renders inline SVG diagram cleanly',
        (tester) async {
      final qWithSvg = baseQuestion.copyWith(
        vectorDiagram: testVectorDiagram,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuestionDiagramViewer(
              question: qWithSvg,
            ),
          ),
        ),
      );

      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.text('Figure 1.1: Circular magnetic flux boundary'),
          findsOneWidget);
    });

    testWidgets(
        'QuestionDiagramViewer handles missing raster asset with fallback UI',
        (tester) async {
      final qWithBadAsset = baseQuestion.copyWith(
        diagramAsset: 'assets/non_existent_diagram.png',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuestionDiagramViewer(
              question: qWithBadAsset,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Fallback banner appears with graceful reporting hint
      expect(find.textContaining('Diagram asset could not be loaded'),
          findsOneWidget);
    });

    testWidgets(
        'FullscreenDiagramModal opens with controls and supports double-tap zoom',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FullscreenDiagramModal(
              vectorDiagram: testVectorDiagram,
              caption: 'Electric circuit with resistor R1 and capacitor C1',
              altText: 'A schematic showing circuit loops',
            ),
          ),
        ),
      );

      // Verify controls
      expect(find.text('Electric circuit with resistor R1 and capacitor C1'),
          findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.byIcon(Icons.center_focus_strong), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);

      // Double tap to zoom in
      final center = tester.getCenter(find.byType(InteractiveViewer));
      await tester.tapAt(center);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(center);
      await tester.pumpAndSettle();

      // Zoom HUD updates above 100%
      expect(find.text('250%'), findsOneWidget);

      // Tap Reset button
      await tester.tap(find.byIcon(Icons.center_focus_strong));
      await tester.pumpAndSettle();

      // Restores back to 100%
      expect(find.text('100%'), findsOneWidget);
    });
  });
}
