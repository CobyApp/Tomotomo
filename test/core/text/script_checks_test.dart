import 'package:aichat/core/text/script_checks.dart';
import 'package:flutter_test/flutter_test.dart';

/// Failing either check costs a second on-device generation — the slowest thing
/// the app does — so a false alarm is expensive, and the old rules raised one on
/// every gloss that quoted the word it was explaining.
void main() {
  group('dominantScriptIs — a gloss may quote the word it explains', () {
    test('English gloss quoting a Japanese word is still English', () {
      expect(dominantScriptIs('The question word "what" (なに).', 'en'), isTrue);
      expect(dominantScriptIs('Means "today"; common when asking 오늘.', 'en'), isTrue);
    });

    test('Chinese gloss quoting a Japanese word is still Chinese', () {
      expect(dominantScriptIs('意为“今天”，日语写作「今日」', 'zh'), isTrue);
    });

    test('Korean gloss quoting a Japanese word is still Korean', () {
      expect(dominantScriptIs("'오늘'을 뜻하며, 일본어로는 今日(きょう)", 'ko'), isTrue);
    });

    test('Japanese gloss quoting a Korean word is still Japanese', () {
      expect(dominantScriptIs('「今日」の意味で、韓国語では오늘', 'ja'), isTrue);
    });
  });

  group('dominantScriptIs — a gloss in the WRONG language is still caught', () {
    test('a Japanese gloss does not pass as Chinese', () {
      // Han alone cannot decide this: kana is what breaks the tie.
      expect(dominantScriptIs('「その日」を指し、一日の予定を尋ねるときによく使う。', 'zh'), isFalse);
    });

    test('a Chinese gloss does not pass as Japanese', () {
      expect(dominantScriptIs('意为“今天”，常用于询问当天的安排。', 'ja'), isFalse);
    });

    test('a Korean gloss does not pass as Japanese or Chinese', () {
      expect(dominantScriptIs("'오늘'을 뜻하며 일정 이야기에 자주 쓴다.", 'ja'), isFalse);
      expect(dominantScriptIs("'오늘'을 뜻하며 일정 이야기에 자주 쓴다.", 'zh'), isFalse);
    });

    test('a CJK gloss does not pass as English on one stray letter', () {
      expect(dominantScriptIs('意为“今天”，常用于 K-pop 圈', 'en'), isFalse);
      expect(dominantScriptIs('「今日」の意味で SNS でよく使う', 'en'), isFalse);
    });

    test('an English gloss does not pass as any CJK language', () {
      for (final lang in const ['ko', 'ja', 'zh']) {
        expect(dominantScriptIs('Means "today"; used when asking.', lang), isFalse,
            reason: lang);
      }
    });

    test('empty text passes for nothing', () {
      for (final lang in const ['ko', 'ja', 'en', 'zh']) {
        expect(dominantScriptIs('', lang), isFalse, reason: lang);
      }
    });
  });

  group('readingLooksWrong', () {
    test('tone-marked single-syllable pinyin is accepted', () {
      // These are Latin-1/Extended, not [A-Za-z]: 啊 à, 饿 è, 鹅 é, 哦 ò, 嗯 ń.
      for (final reading in const ['à', 'è', 'é', 'ò', 'ń', 'jīntiān', 'dǎsuàn']) {
        expect(readingLooksWrong(reading, 'zh'), isFalse, reason: reading);
      }
    });

    test('a Chinese reading written in Han is rejected', () {
      expect(readingLooksWrong('今天', 'zh'), isTrue);
      expect(readingLooksWrong('', 'zh'), isTrue);
    });

    test('romaja must be Latin, never Hangul', () {
      expect(readingLooksWrong('oneul', 'ko'), isFalse);
      expect(readingLooksWrong('오늘', 'ko'), isTrue);
    });

    test('a hiragana reading must actually contain kana', () {
      expect(readingLooksWrong('きょう', 'ja'), isFalse);
      expect(readingLooksWrong('今日', 'ja'), isTrue, reason: 'kanji, not a reading');
      expect(readingLooksWrong('kyou', 'ja'), isTrue, reason: 'romaji, not kana');
      expect(readingLooksWrong('오늘', 'ja'), isTrue, reason: 'no kana at all');
    });

    test('English readings are optional, so anything passes', () {
      for (final reading in const ['təˈdeɪ', '', 'today']) {
        expect(readingLooksWrong(reading, 'en'), isFalse, reason: '"$reading"');
      }
    });
  });
}
