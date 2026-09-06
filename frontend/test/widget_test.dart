import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('HealthSyncApp initialization smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HealthSyncApp());
    await tester.pump();

    // Verify that the app builds without crashing and renders HealthSync AI splash / loading elements.
    expect(find.byType(HealthSyncApp), findsOneWidget);
  });
}
