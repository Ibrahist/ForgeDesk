import 'package:flutter_test/flutter_test.dart';
import 'package:forgedesk_ui/main.dart';
import 'package:forgedesk_ui/services/forgedesk_bridge.dart';

void main() {
  testWidgets('ForgeDesk App Smoke Test', (WidgetTester tester) async {
    final bridge = ForgeDeskBridgeService();
    await tester.pumpWidget(ForgeDeskApp(bridge: bridge));

    // Verify ForgeDesk app title renders
    expect(find.text('ForgeDesk'), findsOneWidget);
    expect(find.text('This Device'), findsOneWidget);
    expect(find.text('Control Remote Desk'), findsOneWidget);
  });
}
