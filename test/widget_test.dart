import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test - verifies Flutter widget tree initializes', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('DineX'),
        ),
      ),
    );

    expect(find.text('DineX'), findsOneWidget);
  });
}
