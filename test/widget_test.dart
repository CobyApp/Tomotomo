// Basic Flutter widget test for Tomotomo app.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aichat/core/di/injection.dart';
import 'package:aichat/app.dart';

void main() {
  testWidgets('App shows character list title', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    setupInjection(prefs, geminiApiKey: 'test-key');

    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    expect(find.text('トモトモ'), findsOneWidget);
  });
}
