// Basic Flutter widget test for Tomotomo app.
// Full app test with AuthGate requires Supabase (run as integration test with real .env).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aichat/core/di/injection.dart';
import 'package:aichat/core/theme/app_theme.dart';
import 'package:aichat/presentation/auth/auth_state.dart';
import 'package:aichat/presentation/auth/login_screen.dart';
import 'package:aichat/presentation/locale/locale_notifier.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Login screen shows title and login button', (WidgetTester tester) async {
    setupInjection(geminiApiKey: 'test-key-not-used');

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => LocaleNotifier(profileRepository)),
            ChangeNotifierProvider<AppAuthState>(
              create: (_) => AppAuthState(),
            ),
          ],
          child: const LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('トモトモ'), findsOneWidget);
    expect(find.text('로그인'), findsOneWidget);
  });
}
