import 'package:aichat/core/di/injection.dart';
import 'package:aichat/core/locale/languages.dart';
import 'package:aichat/core/ui/paper/paper_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pretendard carries every Hangul syllable and both kana but no Han at all —
/// measured: 0 of 20,992 CJK ideographs. Japanese runs 30–50% kanji, so every
/// Japanese sentence was drawn in two typefaces at once: kana from Pretendard,
/// kanji from whatever the platform substituted. The primary language, on every
/// screen.
void main() {
  final original = appLanguageCode;
  tearDown(() => appLanguageCode = original);

  test('Japanese body text uses one font, not Pretendard plus a substitute', () {
    appLanguageCode = 'ja';
    expect(bodyFontFamily(), isNull,
        reason: 'kanji would still come from somewhere else');
  });

  test('the languages Pretendard actually covers keep it', () {
    for (final lang in const ['ko', 'en']) {
      appLanguageCode = lang;
      expect(bodyFontFamily(), 'Pretendard', reason: lang);
    }
  });

  test('Chinese is unaffected: it was already one font', () {
    // All Han and Pretendard has none, so it already resolved entirely to the
    // platform font — consistent, with the correct Simplified shapes.
    appLanguageCode = 'zh';
    expect(bodyFontFamily(), 'Pretendard');
  });

  test('an explicit language wins over the UI language', () {
    appLanguageCode = 'ko';
    expect(bodyFontFamily('ja'), isNull);
    appLanguageCode = 'ja';
    expect(bodyFontFamily('ko'), 'Pretendard');
  });

  test('every supported language resolves without throwing', () {
    for (final lang in kSupportedLanguageList) {
      appLanguageCode = lang;
      expect(() => bodyFontFamily(), returnsNormally, reason: lang);
    }
  });

  group('the theme carries it through', () {
    TextStyle? bodyOf(ThemeData t) => t.textTheme.bodyMedium;

    test('Japanese body slots carry no partly-covering font', () {
      // ThemeData stamps its own default family onto a slot that names none, so
      // the slot is never literally null. That default is a Latin face with no
      // kana and no kanji, which is exactly why it is safe: the whole Japanese
      // run misses it and resolves to one CJK face. Pretendard was the problem
      // precisely because it covers kana but not Han, so it split the run.
      appLanguageCode = 'ja';
      expect(bodyOf(PaperTheme.light)?.fontFamily, isNot('Pretendard'));
      expect(bodyOf(PaperTheme.dark)?.fontFamily, isNot('Pretendard'));
      expect(
        bodyOf(PaperTheme.light)?.fontFamilyFallback ?? const <String>[],
        isNot(contains('Pretendard')),
        reason: 'Pretendard came back through the fallback stack',
      );
    });

    test('Korean still gets Pretendard', () {
      appLanguageCode = 'ko';
      expect(bodyOf(PaperTheme.light)?.fontFamily, 'Pretendard');
    });

    test('the display font keeps the brand voice in Japanese', () {
      // The point of the change is the body text only: titles and the wordmark
      // must still be the rounded face, or Japanese loses its personality.
      appLanguageCode = 'ja';
      expect(cuteDisplay().fontFamily, 'CuteKo');
      expect(cuteDisplay().fontFamilyFallback, contains('CuteJp'));
      expect(PaperTheme.light.textTheme.headlineMedium?.fontFamilyFallback,
          contains('CuteJp'));
    });
  });
}
