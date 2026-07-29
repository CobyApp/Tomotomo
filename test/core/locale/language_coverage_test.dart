import 'dart:io';

import 'package:aichat/core/l10n/app_strings.dart';
import 'package:aichat/core/locale/languages.dart';
import 'package:aichat/core/locale/supported_locales.dart';
import 'package:aichat/data/character/characters_data.dart';
import 'package:flutter_test/flutter_test.dart';

/// The app shipped supporting only Korean and Japanese. Everything that had to
/// grow to four languages grew by hand, in its own copy of the list — which is
/// how MaterialApp.supportedLocales stayed at [ko, ja] long after Settings
/// offered four, showing English and Chinese users Korean in every OS string.
///
/// These assertions are the thing that has to fail when a fifth language is
/// added and something is left behind.
void main() {
  test('the ordered list and the canonical set hold the same languages', () {
    expect(kSupportedLanguageList.toSet(), kSupportedLanguages);
    expect(
      kSupportedLanguageList.length,
      kSupportedLanguages.length,
      reason: 'the ordered list has a duplicate',
    );
  });

  test('every language reaches MaterialApp.supportedLocales', () {
    expect(
      kAppSupportedLocales.map((l) => l.languageCode).toList(),
      kSupportedLanguageList,
    );
  });

  test('every language has UI strings, and the same keys as Korean', () {
    final korean = AppStrings.all('ko');
    for (final lang in kSupportedLanguageList) {
      final map = AppStrings.all(lang);
      expect(map.keys.toSet(), korean.keys.toSet(), reason: '$lang key set');
      for (final entry in map.entries) {
        expect(entry.value.trim(), isNotEmpty, reason: '$lang: ${entry.key}');
      }
    }
  });

  test('every language has an endonym distinct from the others', () {
    final endonyms = kSupportedLanguageList.map(languageEndonym).toList();
    expect(endonyms.toSet().length, endonyms.length, reason: 'duplicate endonym');
    for (final name in endonyms) {
      expect(name.trim(), isNotEmpty);
    }
  });

  test('every language has a reading system and a built-in friend', () {
    for (final lang in kSupportedLanguageList) {
      expect(() => readingSystemFor(lang), returnsNormally);
      expect(
        characters.where((c) => c.friendLanguage == lang),
        isNotEmpty,
        reason: 'no packaged friend speaks $lang, so onboarding cannot prefill',
      );
    }
  });

  test('every built-in friend has an avatar file that actually exists', () {
    // The asset path being non-empty is not enough: a friend added for a new
    // language with a typo'd path renders a broken image with no error.
    for (final c in characters) {
      expect(
        File(c.imagePath).existsSync(),
        isTrue,
        reason: '${c.id}: missing asset ${c.imagePath}',
      );
    }
  });

  test('every language has a prefill template for onboarding', () {
    for (final lang in kSupportedLanguageList) {
      for (final prefix in const ['tplTagline_', 'tplPersona_']) {
        final value = AppStrings.of('ko', '$prefix$lang');
        expect(value.trim(), isNotEmpty, reason: 'missing $prefix$lang');
      }
    }
  });
}
