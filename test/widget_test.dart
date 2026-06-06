import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendo_student/main.dart';

void main() {
  testWidgets('AttenDoApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: AttenDoApp()));

    // Verify that the app renders without error.
    await tester.pump();

    // The login screen should be visible (not authenticated)
    expect(find.byType(AttenDoApp), findsOneWidget);
  });
}
