import 'package:aichat/core/l10n/app_strings.dart';
import 'package:aichat/core/locale/languages.dart';
import 'package:aichat/core/startup/startup_failure_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// main used to let an initialization failure propagate, so runApp was never
/// reached: a corrupted box or a full disk produced a blank screen that died
/// with nothing said, and the only recovery a user could think of is deleting
/// the app — which takes the 2.6 GB model and every conversation with it.
void main() {
  testWidgets('it explains the failure and offers a retry', (tester) async {
    var retries = 0;
    await tester.pumpWidget(StartupFailureApp(onRetry: () => retries++));

    expect(find.text(AppStrings.of('en', 'startupFailedTitle')), findsOneWidget);
    expect(find.text(AppStrings.of('en', 'startupFailedBody')), findsOneWidget);

    await tester.tap(find.text(AppStrings.of('en', 'startupRetry')));
    expect(retries, 1);
  });

  testWidgets('it speaks the device language, having no stored one to read',
      (tester) async {
    // The boxes are exactly what failed, so it cannot read the saved choice.
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    for (final lang in kSupportedLanguageList) {
      tester.platformDispatcher.localeTestValue = Locale(lang);
      await tester.pumpWidget(StartupFailureApp(onRetry: () {}));
      await tester.pump();

      expect(
        find.text(AppStrings.of(lang, 'startupFailedTitle')),
        findsOneWidget,
        reason: 'not localized for $lang',
      );
    }
  });

  testWidgets('an unsupported device locale still renders', (tester) async {
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    tester.platformDispatcher.localeTestValue = const Locale('fr');

    await tester.pumpWidget(StartupFailureApp(onRetry: () {}));
    expect(
      find.text(AppStrings.of(normalizeLang('fr'), 'startupFailedTitle')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
