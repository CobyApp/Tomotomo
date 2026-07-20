import 'package:aichat/core/locale/languages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('supported set is exactly ko/ja/en/zh', () {
    expect(kSupportedLanguages, {'ko', 'ja', 'en', 'zh'});
  });

  test('normalizeLang keeps supported, falls back to ko', () {
    expect(normalizeLang('en'), 'en');
    expect(normalizeLang('zh'), 'zh');
    expect(normalizeLang('zh-Hans'), 'zh');
    expect(normalizeLang('fr'), 'ko');
    expect(normalizeLang(null), 'ko');
  });

  test('readingSystemFor per friend language', () {
    expect(readingSystemFor('ja'), ReadingSystem.hiragana);
    expect(readingSystemFor('ko'), ReadingSystem.romaja);
    expect(readingSystemFor('zh'), ReadingSystem.pinyin);
    expect(readingSystemFor('en'), ReadingSystem.ipa);
  });
}
