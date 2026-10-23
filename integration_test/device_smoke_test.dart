import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:crypto_ai_trader/main.dart' as app;

/// Real-device smoke test; network is real. Unit fixtures never enter this path.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Native startup, database, Persian/English navigation and safety lock',
    (tester) async {
      await app.main();
      await tester.pump(const Duration(seconds: 3));
      expect(find.byType(NavigationBar), findsOneWidget);
      await tester.tap(find.byIcon(Icons.swap_vert_rounded));
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('معامله واقعی قفل'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('English'));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Preferences'), findsOneWidget);
    },
  );
}
