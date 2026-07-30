import 'package:aichat/core/l10n/app_strings.dart';
import 'package:aichat/core/locale/languages.dart';
import 'package:aichat/core/ui/paper/paper_status_views.dart';
import 'package:aichat/core/ui/paper/paper_theme.dart';
import 'package:aichat/core/ui/paper/paper_widgets.dart';
import 'package:aichat/presentation/onboarding/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Overflow is silent in release — the yellow-and-black stripe is debug-only — so
/// it ships as clipped or misaligned text. iOS lets a user scale text well past
/// 2x, and the longest string is rarely in the language a screen was designed
/// in. Flutter reports an overflow as a FlutterError during layout, which is what
/// these tests capture.
void main() {
  /// The smallest iPhone the app supports, portrait, in logical pixels.
  const smallPhone = Size(320, 568);

  /// Builds [build] for every supported language at [scale] and returns the
  /// overflow messages Flutter reported.
  ///
  /// Set up once per test rather than once per language: overriding the error
  /// handler and the view inside the loop chained handlers and wedged the run.
  Future<List<String>> overflowsAcrossLanguages(
    WidgetTester tester,
    Widget Function(String lang) build, {
    required double scale,
  }) async {
    final errors = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      final text = details.exceptionAsString();
      if (text.contains('overflowed')) {
        errors.add(text.split('\n').first);
      } else {
        previous?.call(details);
      }
    };
    tester.view.physicalSize = smallPhone;
    tester.view.devicePixelRatio = 1.0;
    // Set on the platform rather than in a MediaQuery above MaterialApp:
    // MaterialApp installs its own MediaQuery from the view, which replaced an
    // outer one and quietly made the whole check run at 1x.
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(() {
      FlutterError.onError = previous;
      tester.view.reset();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    for (final lang in kSupportedLanguageList) {
      await tester.pumpWidget(build(lang));
      // Fixed frames rather than pumpAndSettle: the paper widgets loop
      // animations that never settle.
      await tester.pump(const Duration(milliseconds: 300));
    }
    return errors;
  }

  Widget wrap(Widget body, String lang) => MaterialApp(
    theme: PaperTheme.light,
    locale: Locale(lang),
    home: Scaffold(body: body),
  );

  for (final scale in const [1.0, 1.3, 2.0]) {
    testWidgets('a level chip row fits at ${scale}x in every language', (
      tester,
    ) async {
      final found = await overflowsAcrossLanguages(
        tester,
        (lang) => wrap(
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final key in const [
                'levelBeginner',
                'levelIntermediate',
                'levelAdvanced',
              ])
                PaperChip(
                  label: AppStrings.of(lang, key),
                  selected: false,
                  onTap: () {},
                ),
            ],
          ),
          lang,
        ),
        scale: scale,
      );
      expect(found, isEmpty, reason: 'at ${scale}x: $found');
    });

    testWidgets('the friends empty state fits at ${scale}x in every language', (
      tester,
    ) async {
      final found = await overflowsAcrossLanguages(
        tester,
        (lang) => wrap(
          PaperEmptyState(
            icon: Icons.person_add_alt_1_rounded,
            title: AppStrings.of(lang, 'charactersEmptyTitle'),
            subtitle: AppStrings.of(lang, 'charactersEmptyHint'),
          ),
          lang,
        ),
        scale: scale,
      );
      expect(found, isEmpty, reason: 'at ${scale}x: $found');
    });

    testWidgets('the longest intro slide fits at ${scale}x in every language', (
      tester,
    ) async {
      // Slide 3 has the longest body in ko/ja and sits in a PageView, which
      // gives it a fixed height and no slack.
      final found = await overflowsAcrossLanguages(
        tester,
        (lang) => wrap(
          IntroSlide(
            icon: Icons.menu_book_rounded,
            title: AppStrings.of(lang, 'onboardingIntro3Title'),
            body: AppStrings.of(lang, 'onboardingIntro3Body'),
          ),
          lang,
        ),
        scale: scale,
      );
      expect(found, isEmpty, reason: 'at ${scale}x: $found');
    });
  }

  testWidgets('an intro slide still centres when it fits', (tester) async {
    // Making it scrollable is what fixed the overflow, and inside a plain scroll
    // view the height is unbounded, so MainAxisAlignment.center would quietly
    // have become top alignment at ordinary text sizes.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: PaperTheme.light,
        home: Scaffold(
          body: IntroSlide(
            icon: Icons.menu_book_rounded,
            title: AppStrings.of('ko', 'onboardingIntro3Title'),
            body: AppStrings.of('ko', 'onboardingIntro3Body'),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final titleTop = tester
        .getRect(find.text(AppStrings.of('ko', 'onboardingIntro3Title')))
        .top;
    expect(titleTop, greaterThan(200),
        reason: 'the slide is pinned to the top instead of centred');
  });

  testWidgets('the harness would actually notice an overflow', (tester) async {
    // A capture that silently sees nothing would make every test above pass no
    // matter how bad the layout got.
    final found = await overflowsAcrossLanguages(
      tester,
      (lang) => wrap(
        const Row(children: [SizedBox(width: 900, height: 10)]),
        lang,
      ),
      scale: 1.0,
    );
    expect(found, isNotEmpty, reason: 'overflow went undetected');
  });
}
