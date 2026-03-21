import '../../../core/language/dm_utterance_script.dart';

/// One-shot analysis: **Japanese(-heavy) peer message** → explanation in Korean, Japanese vocabulary with Korean glosses.
String buildDmJapaneseUtteranceAnalysisPrompt(String utterance) {
  return '''
You are a language coach for Korean learners of Japanese. The user is reading a **real human chat line** (not roleplay).

Task: Analyze this Japanese(-heavy) message and output **one JSON object only** (no markdown fences).

【JSON language rules】
1) "content" → copy the input utterance verbatim (trimmed). If mixed scripts, keep as-is.
2) "explanation" → **Korean (Hangul) only**. No Japanese kana/kanji in explanation. Use numbered sections like:
   【1 요약】 【2 맥락】 【3 뉘앙스】 【4 비슷한 말】 【5 학습 포인트】
3) "vocabulary" → array of 2–5 items. Each item:
   - "word" → Japanese surface (kanji/kana) from the message
   - "reading" → hiragana only
   - "meaning_ko" → Korean gloss only (no Japanese in meaning_ko)

Keys required at root: "content", "explanation", "vocabulary".

Utterance:
$utterance
''';
}

/// One-shot analysis: **Korean(-heavy) peer message** → explanation in Japanese, Korean vocabulary with Japanese glosses.
String buildDmKoreanUtteranceAnalysisPrompt(String utterance) {
  return '''
You are a language coach for Japanese learners of Korean. The user is reading a **real human chat line** (not roleplay).

Task: Analyze this Korean(-heavy) message and output **one JSON object only** (no markdown fences).

【JSON language rules】
1) "content" → copy the input utterance verbatim (trimmed).
2) "explanation" → **Japanese only**. No Hangul in explanation. Use numbered sections like:
   【1 ねらい】 【2 文脈】 【3 ニュアンス】 【4 かわりの言い方】 【5 学習メモ】
3) "vocabulary" → array of 2–5 items. Each item:
   - "word" → Korean (Hangul) phrase from the message
   - "reading" → optional katakana pronunciation for Japanese learners, or omit
   - "meaning_ja" → Japanese gloss only (no Hangul in meaning_ja)

Keys required at root: "content", "explanation", "vocabulary".

Utterance:
$utterance
''';
}

String buildDmExpressionAnalysisPrompt(String utterance, DmUtteranceScript script) {
  switch (script) {
    case DmUtteranceScript.japaneseHeavy:
      return buildDmJapaneseUtteranceAnalysisPrompt(utterance);
    case DmUtteranceScript.koreanHeavy:
      return buildDmKoreanUtteranceAnalysisPrompt(utterance);
    case DmUtteranceScript.ambiguous:
      return buildDmJapaneseUtteranceAnalysisPrompt(utterance);
  }
}
