import '../../../core/language/dm_utterance_script.dart';

/// One-shot analysis: **Japanese(-heavy) peer message** → Japanese vocabulary with Korean glosses.
String buildDmJapaneseUtteranceAnalysisPrompt(String utterance) {
  return '''
You are a language coach for Korean learners of Japanese. The user is reading a **real human chat line** (not roleplay).

Task: Extract study vocabulary from this Japanese(-heavy) message and output **one JSON object only** (no markdown fences).

【JSON language rules】
1) "content" → copy the input utterance verbatim (trimmed). If mixed scripts, keep as-is.
2) "vocabulary" → array of 2–5 items. Each item:
   - "word" → Japanese surface (kanji/kana) from the message
   - "reading" → hiragana only
   - "meaning_ko" → Korean gloss only (no Japanese in meaning_ko). **Depth**: ~14–40 Hangul characters per item; include a short note on usage, nuance, or typical situation—**not** a bare synonym list.

Keys required at root: "content", "vocabulary" only. Do not include "explanation".

【JSON syntax — invalid JSON hides the whole reply】
- Root keys must be only "content" and "vocabulary". Never put "word", "reading", or "meaning_*" at the root.
- Escape double quotes inside strings as \\". Do not append unquoted prose after a closing quote.
- Output must be a single JSON object from { to } with no extra text.

【Exact shape the app parses】
{"content":"<same as utterance>","vocabulary":[{"word":"…","reading":"…","meaning_ko":"…"},…]}

Utterance:
$utterance
''';
}

/// One-shot analysis: **Korean(-heavy) peer message** → Korean vocabulary with Japanese glosses.
String buildDmKoreanUtteranceAnalysisPrompt(String utterance) {
  return '''
You are a language coach for Japanese learners of Korean. The user is reading a **real human chat line** (not roleplay).

Task: Extract study vocabulary from this Korean(-heavy) message and output **one JSON object only** (no markdown fences).

【JSON language rules】
1) "content" → copy the input utterance verbatim (trimmed).
2) "vocabulary" → array of 2–5 items. Each item:
   - "word" → Korean (Hangul) phrase from the message
   - "reading" → optional katakana pronunciation for Japanese learners, or omit
   - "meaning_ja" → Japanese gloss only (no Hangul in meaning_ja). **Depth**: ~22–45 full-width Japanese characters per item; add usage, nuance, or situation in one short phrase—**not** a long paragraph or a single-word gloss.

Keys required at root: "content", "vocabulary" only. Do not include "explanation".

【JSON syntax — invalid JSON hides the whole reply】
- Root keys must be only "content" and "vocabulary". Never put "word", "reading", or "meaning_*" at the root.
- Escape double quotes inside strings as \\". Do not append unquoted prose after a closing quote.
- Output must be a single JSON object from { to } with no extra text.

【Exact shape the app parses】
{"content":"<same as utterance>","vocabulary":[{"word":"…","reading":"…","meaning_ja":"…"},…]}

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
