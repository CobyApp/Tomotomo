import '../locale/languages.dart';

/// Script ranges. Deliberately loose — these only have to catch a whole line
/// written in the wrong language, not classify every character.
final RegExp _hangulRe = RegExp(r'[가-힣ᄀ-ᇿ㄰-㆏]');
final RegExp _kanaRe = RegExp(r'[぀-ゟ゠-ヿ]');
final RegExp _hanRe = RegExp(r'[一-鿿]');

/// Latin letters INCLUDING the accented forms pinyin tone marks produce (à è é
/// ò ń …). Plain `[A-Za-z]` rejected every single-syllable toned reading: 啊 → à,
/// 饿 → è, 鹅 → é, 哦 → ò, 嗯 → ń, all common in casual chat.
final RegExp _latinRe = RegExp(r'[A-Za-zÀ-ɏḀ-ỿ]');

class _ScriptCounts {
  const _ScriptCounts(this.hangul, this.kana, this.han, this.latin);
  final int hangul, kana, han, latin;
}

_ScriptCounts _count(String text) {
  var hangul = 0, kana = 0, han = 0, latin = 0;
  for (final r in text.runes) {
    if (r >= 0xAC00 && r <= 0xD7A3) {
      hangul++;
    } else if ((r >= 0x3040 && r <= 0x30FF) || (r >= 0x31F0 && r <= 0x31FF)) {
      kana++;
    } else if (r >= 0x4E00 && r <= 0x9FFF) {
      han++;
    } else if ((r >= 0x41 && r <= 0x5A) || (r >= 0x61 && r <= 0x7A)) {
      latin++;
    }
  }
  return _ScriptCounts(hangul, kana, han, latin);
}

/// Whether [text] reads as [languageCode], judged by which script DOMINATES.
///
/// A study-sheet gloss normally quotes the word it explains, so the learner's
/// language and the friend's language both appear: `The question word "what"
/// (なに).` is good English and `意为“今天”，日语写作「今日」` is good Chinese. A
/// contains-check cannot express that, and neither can a check that rejects any
/// trace of another script — the app previously used one of each, so a Chinese
/// gloss quoting a kana word counted as Japanese while both glosses above were
/// rejected outright. Being rejected here costs a second on-device generation,
/// the slowest thing the app does, so false alarms are expensive.
bool dominantScriptIs(String text, String languageCode) {
  final c = _count(text);
  switch (normalizeLang(languageCode)) {
    case 'ja':
      // Kana is the only script unique to Japanese, so require it and require it
      // not to be outnumbered by Hangul.
      return c.kana > 0 && c.kana >= c.hangul;
    case 'en':
      return c.latin > 0 && c.latin > c.hangul + c.kana + c.han;
    case 'zh':
      // Han is shared with Japanese; kana breaks the tie.
      return c.han > 0 && c.han > c.kana && c.hangul == 0;
    case 'ko':
    default:
      return c.hangul > 0 && c.hangul >= c.kana;
  }
}

/// Whether [reading] is unusable as the pronunciation aid for [friendLanguage].
///
/// The app uses four systems and each has to be judged on its own terms:
/// hiragana for Japanese, Revised Romanization for Korean, Hanyu Pinyin for
/// Chinese, and IPA for English, where the prompt allows it to be omitted.
bool readingLooksWrong(String? value, String friendLanguage) {
  final reading = value?.trim() ?? '';
  switch (readingSystemFor(friendLanguage)) {
    case ReadingSystem.hiragana:
      // Kana, and actually present: Han or Latin here is wrong, and so is a
      // "reading" carrying no kana at all.
      return reading.isEmpty ||
          !_kanaRe.hasMatch(reading) ||
          _hanRe.hasMatch(reading) ||
          _latinRe.hasMatch(reading);
    case ReadingSystem.romaja:
    case ReadingSystem.pinyin:
      // Romanization: Latin letters, accented ones included, never the source
      // script.
      return reading.isEmpty ||
          !_latinRe.hasMatch(reading) ||
          _hanRe.hasMatch(reading) ||
          _hangulRe.hasMatch(reading) ||
          _kanaRe.hasMatch(reading);
    case ReadingSystem.ipa:
      // The prompt lets an English reading be omitted, so anything passes —
      // including nothing. The one unenforced system of the four.
      return false;
  }
}
