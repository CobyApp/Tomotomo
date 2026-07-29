import 'package:aichat/core/di/injection.dart';
import 'package:aichat/core/ui/paper/paper_theme.dart';
import 'package:flutter_test/flutter_test.dart';

/// The bundled cute fonts hold no Han at all except CuteJp (M PLUS Rounded 1c),
/// a JAPANESE font that covers only part of the Simplified set. Leaving it in
/// the stack split Chinese words across two typefaces — 这个 rendered 这 from
/// the system font and 个 from CuteJp. Dropping it sends every Han character to
/// the system font: one face, correct Simplified shapes.
void main() {
  tearDown(() => appLanguageCode = 'ko');

  test('Chinese drops the Japanese face so Han cannot come from two fonts', () {
    expect(cuteDisplayFallback('zh'), isNot(contains('CuteJp')));
    expect(cuteDisplay(language: 'zh').fontFamilyFallback, ['Pretendard']);
  });

  test('the other languages keep it — Japanese needs it for kana and kanji', () {
    for (final lang in const ['ko', 'ja', 'en']) {
      expect(
        cuteDisplayFallback(lang),
        contains('CuteJp'),
        reason: '$lang display text would lose its kana/kanji face',
      );
    }
  });

  test('Latin and digits still come from the cute face in Chinese', () {
    expect(cuteDisplay(language: 'zh').fontFamily, 'CuteKo');
  });

  test('no language given follows the app UI language', () {
    appLanguageCode = 'zh';
    expect(cuteDisplayFallback(null), isNot(contains('CuteJp')));
    appLanguageCode = 'ja';
    expect(cuteDisplayFallback(null), contains('CuteJp'));
  });

  test('an unsupported code degrades to the default stack, not a crash', () {
    expect(cuteDisplayFallback('fr'), contains('CuteJp'));
  });
}
