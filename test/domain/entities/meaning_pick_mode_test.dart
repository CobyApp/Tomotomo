import 'package:aichat/domain/entities/chat_message.dart';
import 'package:flutter_test/flutter_test.dart';

/// This mapping used to exist three times: once as this helper (never called)
/// and twice inline as a nested ternary in the repository. The parser also had a
/// character-derived fallback that could only answer "Korean or Japanese gloss",
/// so a caller that forgot to pass a mode gave English and Chinese learners
/// Korean glosses. One helper now, and the parser requires the mode.
void main() {
  test('each app language picks its own gloss', () {
    expect(meaningPickModeForApp('ko'), VocabularyMeaningPickMode.preferKoreanGloss);
    expect(meaningPickModeForApp('ja'), VocabularyMeaningPickMode.preferJapaneseGloss);
    expect(meaningPickModeForApp('en'), VocabularyMeaningPickMode.preferEnglishGloss);
    expect(meaningPickModeForApp('zh'), VocabularyMeaningPickMode.preferChineseGloss);
  });

  test('region tags and casing resolve, they do not fall through to Korean', () {
    expect(meaningPickModeForApp('en-US'), VocabularyMeaningPickMode.preferEnglishGloss);
    expect(meaningPickModeForApp('zh-Hans'), VocabularyMeaningPickMode.preferChineseGloss);
    expect(meaningPickModeForApp('JA'), VocabularyMeaningPickMode.preferJapaneseGloss);
    expect(meaningPickModeForApp('ja_JP'), VocabularyMeaningPickMode.preferJapaneseGloss);
  });

  test('an unknown language degrades to Korean rather than throwing', () {
    expect(meaningPickModeForApp('fr'), VocabularyMeaningPickMode.preferKoreanGloss);
    expect(meaningPickModeForApp(''), VocabularyMeaningPickMode.preferKoreanGloss);
  });
}
