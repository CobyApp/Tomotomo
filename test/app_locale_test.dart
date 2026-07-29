import 'package:aichat/core/locale/languages.dart';
import 'package:aichat/core/locale/supported_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Flutter resolves an unlisted [MaterialApp.locale] to `supportedLocales.first`.
/// So a language the user can pick in Settings but that is missing from
/// `supportedLocales` silently shows every OS-supplied string — the text
/// selection toolbar (Cut / Copy / Paste), default dialog buttons, semantic
/// labels — in the FIRST listed language instead.
void main() {
  test('every selectable app language is declared in supportedLocales', () {
    final declared = kAppSupportedLocales.map((l) => l.languageCode).toSet();
    expect(
      declared,
      containsAll(kSupportedLanguages),
      reason:
          'languages selectable in Settings but absent from supportedLocales '
          'fall back to ${kAppSupportedLocales.first.languageCode}',
    );
  });

  for (final entry in const {
    'ko': '붙여넣기',
    'ja': '貼り付け',
    'en': 'Paste',
    'zh': '粘贴',
  }.entries) {
    testWidgets('OS widget text is localized for ${entry.key}', (tester) async {
      late BuildContext captured;
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(entry.key),
          supportedLocales: kAppSupportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) {
              captured = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(Localizations.localeOf(captured).languageCode, entry.key);
      expect(
        MaterialLocalizations.of(captured).pasteButtonLabel,
        entry.value,
        reason: 'the paste button a ${entry.key} user sees on long-press',
      );
    });
  }
}
