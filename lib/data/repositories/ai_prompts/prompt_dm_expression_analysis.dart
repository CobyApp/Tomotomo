import '../../../core/language/dm_utterance_script.dart';

String _learningNoteLanguageRule(String appUiLanguageCode) {
  final lang = appUiLanguageCode.toLowerCase();
  if (lang.startsWith('ja')) {
    return 'Write "learning_note" entirely in natural Japanese (no Korean).';
  }
  return 'Write "learning_note" entirely in natural Korean (no Japanese).';
}

/// One-shot analysis: **Japanese(-heavy) peer message** → Japanese vocabulary with Korean glosses.
String buildDmJapaneseUtteranceAnalysisPrompt(String utterance, String appUiLanguageCode) {
  final noteRule = _learningNoteLanguageRule(appUiLanguageCode);
  return '''
You are a language coach for Korean learners of Japanese. The user is reading a **real chat line** (human DM or AI tutor).

Task: Output **one JSON object only** (no markdown fences): full-line Korean translation, a short learning note, and study vocabulary.

【JSON language rules】
1) "content" → copy the input utterance verbatim (trimmed). If mixed scripts, keep as-is.
2) "full_translation" → natural Korean translation of the **entire** utterance (one string). Match tone (casual/formal) when possible.
3) "learning_note" → 1–3 short sentences: grammar, nuance, politeness, or when natives use this wording. $noteRule
4) "vocabulary" → array of 2–5 items. Each item:
   - "word" → Japanese surface (kanji/kana) from the message
   - "reading" → hiragana only
   - "meaning_ko" → Korean gloss only (no Japanese in meaning_ko). **Depth**: ~14–40 Hangul characters per item; include a short note on usage, nuance, or typical situation—**not** a bare synonym list.

Root keys must be exactly: "content", "full_translation", "learning_note", "vocabulary".

【JSON syntax — invalid JSON hides the whole reply】
- Never put "word", "reading", or "meaning_*" at the root.
- Escape double quotes inside strings as \\". Do not append unquoted prose after a closing quote.
- Output must be a single JSON object from { to } with no extra text.

【Exact shape the app parses】
{"content":"…","full_translation":"…","learning_note":"…","vocabulary":[{"word":"…","reading":"…","meaning_ko":"…"},…]}

Utterance:
$utterance
''';
}

/// One-shot analysis: **Korean(-heavy) peer message** → Korean vocabulary with Japanese glosses.
String buildDmKoreanUtteranceAnalysisPrompt(String utterance, String appUiLanguageCode) {
  final noteRule = _learningNoteLanguageRule(appUiLanguageCode);
  return '''
You are a language coach for Japanese learners of Korean. The user is reading a **real chat line** (human DM or AI tutor).

Task: Output **one JSON object only** (no markdown fences): full-line Japanese translation, a short learning note, and study vocabulary.

【JSON language rules】
1) "content" → copy the input utterance verbatim (trimmed).
2) "full_translation" → natural Japanese translation of the **entire** utterance (one string). Use polite/casual level appropriate to the original.
3) "learning_note" → 1–3 short sentences: grammar, nuance, or usage for Japanese learners. $noteRule
4) "vocabulary" → array of 2–5 items. Each item:
   - "word" → Korean (Hangul) phrase from the message
   - "reading" → optional katakana pronunciation for Japanese learners, or omit
   - "meaning_ja" → Japanese gloss only (no Hangul in meaning_ja). **Depth**: ~22–45 full-width Japanese characters per item; add usage, nuance, or situation in one short phrase—**not** a long paragraph or a single-word gloss.

Root keys must be exactly: "content", "full_translation", "learning_note", "vocabulary".

【JSON syntax — invalid JSON hides the whole reply】
- Never put "word", "reading", or "meaning_*" at the root.
- Escape double quotes inside strings as \\". Do not append unquoted prose after a closing quote.
- Output must be a single JSON object from { to } with no extra text.

【Exact shape the app parses】
{"content":"…","full_translation":"…","learning_note":"…","vocabulary":[{"word":"…","reading":"…","meaning_ja":"…"},…]}

Utterance:
$utterance
''';
}

String buildDmExpressionAnalysisPrompt(
  String utterance,
  DmUtteranceScript script,
  String appUiLanguageCode,
) {
  switch (script) {
    case DmUtteranceScript.japaneseHeavy:
      return buildDmJapaneseUtteranceAnalysisPrompt(utterance, appUiLanguageCode);
    case DmUtteranceScript.koreanHeavy:
      return buildDmKoreanUtteranceAnalysisPrompt(utterance, appUiLanguageCode);
    case DmUtteranceScript.ambiguous:
      return buildDmJapaneseUtteranceAnalysisPrompt(utterance, appUiLanguageCode);
  }
}
