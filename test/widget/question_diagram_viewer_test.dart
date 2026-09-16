import 'package:fidel_learn/features/question_bank/domain/models/question_models.dart';
import 'package:fidel_learn/features/question_bank/presentation/widgets/question_diagram_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'QuestionDiagramViewer renders Image.asset when diagramAsset is present',
      (WidgetTester tester) async {
    const questionWithImage = Question(
      id: 'q_test_diagram',
      grade: 12,
      stream: 'natural',
      subjectId: 'biology_g12',
      unitId: 'bio_u4',
      topicId: 'bio_t4_1',
      questionTextEn: 'Identify the shapes of bacteria below:',
      diagramAsset: 'assets/images/exams/bio_2013/q07_bacteria_shapes.png',
      difficulty: 'medium',
      verificationStatus: VerificationStatus.published,
      sourceName: 'ESSLCE Biology 2013',
      contentVersion: 1,
      choices: [],
      explanation: Explanation(solutionTextEn: 'Explanation'),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: QuestionDiagramViewer(question: questionWithImage),
        ),
      ),
    );

    expect(find.text('OFFICIAL EXAM FIGURE'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Zoom'), findsOneWidget);

    // Tap zoom to test opening the fullscreen lightbox dialog
    await tester.tap(find.text('Zoom'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    // Close dialog
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets(
      'QuestionDiagramViewer renders SizedBox.shrink when no diagram is present',
      (WidgetTester tester) async {
    const questionWithoutDiagram = Question(
      id: 'q_test_no_diagram',
      grade: 12,
      stream: 'natural',
      subjectId: 'biology_g12',
      unitId: 'bio_u1',
      topicId: 'bio_t1_1',
      questionTextEn: 'No diagram question',
      difficulty: 'easy',
      verificationStatus: VerificationStatus.published,
      sourceName: 'ESSLCE Biology 2013',
      contentVersion: 1,
      choices: [],
      explanation: Explanation(solutionTextEn: 'Explanation'),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: QuestionDiagramViewer(question: questionWithoutDiagram),
        ),
      ),
    );

    expect(find.text('OFFICIAL EXAM FIGURE'), findsNothing);
    expect(find.byType(Image), findsNothing);
  });
}
