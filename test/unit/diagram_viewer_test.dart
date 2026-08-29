import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/features/question_bank/domain/models/diagram_models.dart';
import 'package:fidel_learn/features/question_bank/presentation/widgets/svg_diagram_viewer.dart';

void main() {
  group('VectorDiagram & Hotspot Domain Model Tests', () {
    const testDiagram = VectorDiagram(
      id: 'diag_test_1',
      titleEn: 'Right-Angled Triangle ABC',
      titleAm: 'ቀጤ-ነክ ባለሶስት ጎን ABC',
      rawSvgContent: '<svg viewBox="0 0 400 300"><polygon points="80,240 320,240 200,60"/></svg>',
      viewBoxWidth: 400.0,
      viewBoxHeight: 300.0,
      caption: 'Geometry: Pythagorean right triangle',
      hotspots: [
        DiagramHotspot(
          id: 'h_a',
          xRatio: 0.2,
          yRatio: 0.8,
          label: 'A',
          descriptionEn: 'Vertex A: Base adjacent leg (AB = 6 cm)',
          descriptionAm: 'ነጥብ A: መነሻ ጎን (6 ሳ.ሜ)',
        ),
        DiagramHotspot(
          id: 'h_b',
          xRatio: 0.8,
          yRatio: 0.8,
          label: 'B',
          descriptionEn: 'Vertex B: Right angle 90° vertex',
          descriptionAm: 'ነጥብ B: የ90 ዲግሪ ቀጤ አንግል',
        ),
      ],
    );

    test('serializes and deserializes VectorDiagram and DiagramHotspots to/from JSON', () {
      final json = testDiagram.toJson();
      expect(json['id'], 'diag_test_1');
      expect(json['title_en'], 'Right-Angled Triangle ABC');
      expect(json['view_box_width'], 400.0);
      expect((json['hotspots'] as List).length, 2);

      final reconstructed = VectorDiagram.fromJson(json);
      expect(reconstructed, equals(testDiagram));
      expect(reconstructed.hotspots.first.label, 'A');
      expect(reconstructed.hotspots.first.xRatio, 0.2);
    });

    testWidgets('renders SvgDiagramViewer with interactive title, hotspots, and zoom controls', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SvgDiagramViewer(
              diagram: testDiagram,
              height: 300,
              showControls: true,
            ),
          ),
        ),
      );

      // Verify Title overlay is rendered
      expect(find.text('Right-Angled Triangle ABC'), findsOneWidget);

      // Verify Hotspots (A and B) are displayed
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);

      // Verify Zoom & pan toolbar buttons
      expect(find.byIcon(Icons.zoom_in), findsOneWidget);
      expect(find.byIcon(Icons.zoom_out), findsOneWidget);
      expect(find.byIcon(Icons.center_focus_strong), findsOneWidget);
      expect(find.byIcon(Icons.fullscreen), findsOneWidget);

      // Tap hotspot A to trigger modal bottom sheet
      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();

      expect(find.text('Point of Interest: A'), findsOneWidget);
      expect(find.text('Vertex A: Base adjacent leg (AB = 6 cm)'), findsOneWidget);
    });
  });
}
