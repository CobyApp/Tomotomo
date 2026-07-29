import 'package:aichat/domain/entities/chat_message.dart';
import 'package:flutter_test/flutter_test.dart';

/// The alias lists were written when the app taught only Japanese and Korean, so
/// they knew `単語` / `読み` / `뜻` and nothing else. A model prompted about
/// Chinese emits `单词` and `拼音`; one prompted about English emits `ipa`. Those
/// keys were absent, so the word, reading or meaning was silently dropped and the
/// study sheet came back missing rows.
void main() {
  Vocabulary? parse(Map<String, dynamic> json, VocabularyMeaningPickMode mode) =>
      Vocabulary.tryParseLoose(json, meaningMode: mode);

  group('headword key', () {
    test('Chinese key names are understood', () {
      for (final key in const ['单词', '词', '词语', '汉字']) {
        final v = parse({
          key: '学习',
          'meaning': 'to study',
        }, VocabularyMeaningPickMode.preferChineseGloss);
        expect(v?.word, '学习', reason: 'key "$key" was dropped');
      }
    });

    test('Korean and Japanese key names still work', () {
      expect(
        parse({'단어': '공부', 'meaning': 'study'},
            VocabularyMeaningPickMode.preferKoreanGloss)?.word,
        '공부',
      );
      expect(
        parse({'単語': '勉強', 'meaning': 'study'},
            VocabularyMeaningPickMode.preferJapaneseGloss)?.word,
        '勉強',
      );
    });
  });

  group('reading key — one per pronunciation system', () {
    test('pinyin, romaja and IPA are all recognised', () {
      final cases = {
        'pinyin': 'xuéxí',
        '拼音': 'xuéxí',
        'romaja': 'gongbu',
        'romanization': 'gongbu',
        'ipa': 'ˈstʌdi',
        'phonetic': 'ˈstʌdi',
        'hiragana': 'べんきょう',
      };
      for (final entry in cases.entries) {
        final v = parse({
          'word': 'w',
          'meaning': 'm',
          entry.key: entry.value,
        }, VocabularyMeaningPickMode.neutral);
        expect(v?.reading, entry.value, reason: 'key "${entry.key}" was dropped');
      }
    });
  });

  group('meaning key', () {
    test('Chinese and Japanese meaning key names are understood', () {
      for (final key in const ['意思', '释义', '含义']) {
        expect(
          parse({'word': 'w', key: '学习的意思'},
              VocabularyMeaningPickMode.preferChineseGloss)?.meaning,
          '学习的意思',
          reason: 'key "$key" was dropped',
        );
      }
      expect(
        parse({'word': 'w', '意味': 'べんきょう'},
            VocabularyMeaningPickMode.preferJapaneseGloss)?.meaning,
        'べんきょう',
      );
    });

    test('an explicit per-language gloss still beats a generic one', () {
      final json = {
        'word': 'w',
        'meaning': 'generic',
        'meaning_zh': '中文释义',
        'meaning_en': 'english gloss',
      };
      expect(parse(json, VocabularyMeaningPickMode.preferChineseGloss)?.meaning,
          '中文释义');
      expect(parse(json, VocabularyMeaningPickMode.preferEnglishGloss)?.meaning,
          'english gloss');
    });
  });

  test('a row with no usable word or meaning is still rejected', () {
    expect(parse({'reading': 'x'}, VocabularyMeaningPickMode.neutral), isNull);
    expect(parse({'word': 'w'}, VocabularyMeaningPickMode.neutral), isNull);
  });

  group('headword language is independent of gloss language', () {
    test('a Korean friend gets the Hangul headword whatever the UI language is', () {
      // The model often sends both a romanization and the Hangul. Preferring
      // Hangul used to be gated on the gloss mode being Japanese — which, in the
      // two-language app, was the same thing as "the friend speaks Korean". A
      // Chinese- or English-UI learner of Korean stored the romanization instead.
      final json = {'word': 'oneul', 'korean_word': '오늘', 'meaning': 'today'};
      for (final mode in VocabularyMeaningPickMode.values) {
        expect(
          Vocabulary.tryParseLoose(json, meaningMode: mode, friendLanguage: 'ko')?.word,
          '오늘',
          reason: 'gloss mode $mode changed the headword',
        );
      }
    });

    test('a non-Korean friend is unaffected by the Hangul preference', () {
      final json = {'word': 'today', 'korean_word': '오늘', 'meaning': '今天'};
      expect(
        Vocabulary.tryParseLoose(json,
            meaningMode: VocabularyMeaningPickMode.preferChineseGloss,
            friendLanguage: 'en')?.word,
        'today',
      );
    });

    test('a Korean gloss wins over an English one in Korean mode', () {
      // The "does this look Korean" filter returned true for ANY Latin-only
      // string, so the English gloss under the generic `meaning` key was taken as
      // Korean and the actual Korean gloss beside it was never reached.
      final v = Vocabulary.tryParseLoose(
        {'word': '今日', 'meaning': 'Means "today".', '뜻': '오늘'},
        meaningMode: VocabularyMeaningPickMode.preferKoreanGloss,
        friendLanguage: 'ja',
      );
      expect(v?.meaning, '오늘', reason: 'the English gloss passed as Korean');
    });
  });
}
