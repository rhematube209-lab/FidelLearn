import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/app/app.dart';

void main() {
  testWidgets('FidelLearnApp root smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: FidelLearnApp(),
      ),
    );

    // Initial splash frame
    expect(find.text('FidelLearn'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
  });
}
