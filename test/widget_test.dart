import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fe_asrp_app/app/app.dart';

void main() {
  testWidgets('App smoke test - verifies home page and branding load', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: App(),
      ),
    );

    // Verify that the home page loads and contains the brand text.
    expect(find.text('BMC Phở Express'), findsWidgets);
  });
}
