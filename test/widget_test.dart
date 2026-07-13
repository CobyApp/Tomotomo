// Basic Flutter widget smoke test for the local offline Tomotomo app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('smoke test pumps a trivial widget', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('トモトモ')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('トモトモ'), findsOneWidget);
  });
}
