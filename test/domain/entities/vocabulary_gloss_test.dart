import 'package:aichat/domain/entities/chat_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preferEnglishGloss picks meaning_en', () {
    final v = Vocabulary.tryParseLoose({
      'word': '天気', 'reading': 'てんき',
      'meaning_en': 'weather', 'meaning_ko': '날씨', 'meaning_ja': '天気',
    }, meaningMode: VocabularyMeaningPickMode.preferEnglishGloss);
    expect(v!.meaning, 'weather');
  });

  test('preferChineseGloss picks meaning_zh', () {
    final v = Vocabulary.tryParseLoose({
      'word': '天気', 'reading': 'てんき',
      'meaning_zh': '天气', 'meaning_ko': '날씨',
    }, meaningMode: VocabularyMeaningPickMode.preferChineseGloss);
    expect(v!.meaning, '天气');
  });

  test('preferEnglishGloss falls back to generic meaning', () {
    final v = Vocabulary.tryParseLoose({
      'word': 'w', 'reading': 'r', 'meaning': 'fallback',
    }, meaningMode: VocabularyMeaningPickMode.preferEnglishGloss);
    expect(v!.meaning, 'fallback');
  });
}
