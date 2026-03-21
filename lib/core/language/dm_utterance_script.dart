/// Whether a human chat line is primarily Japanese or Korean (for tutor-style notes).
enum DmUtteranceScript {
  /// Hiragana/katakana-heavy or CJK without hangul — Japanese learning notes in Korean.
  japaneseHeavy,

  /// Hangul-heavy — Korean learning notes in Japanese.
  koreanHeavy,

  /// No clear signal; [resolveDmUtteranceScript] uses [appLanguageCode].
  ambiguous,
}

/// Counts script signals in [text] for DM expression analysis routing.
DmUtteranceScript classifyDmUtteranceScript(String text) {
  final t = text.trim();
  if (t.isEmpty) return DmUtteranceScript.ambiguous;

  var hangul = 0;
  var kana = 0;
  var cjk = 0;
  for (final r in t.runes) {
    if (r >= 0xAC00 && r <= 0xD7AF) {
      hangul++;
    } else if (r >= 0x3040 && r <= 0x309F || r >= 0x30A0 && r <= 0x30FF) {
      kana++;
    } else if (r >= 0x4E00 && r <= 0x9FFF) {
      cjk++;
    }
  }

  final jaScore = kana + cjk * 0.35;
  final koScore = hangul.toDouble();

  if (hangul >= 2 && koScore >= jaScore * 1.15) {
    return DmUtteranceScript.koreanHeavy;
  }
  if (kana >= 1 && jaScore >= koScore * 1.1) {
    return DmUtteranceScript.japaneseHeavy;
  }
  if (hangul > 0 && hangul >= cjk) {
    return DmUtteranceScript.koreanHeavy;
  }
  if (kana > 0 || (cjk >= 2 && hangul == 0)) {
    return DmUtteranceScript.japaneseHeavy;
  }
  if (hangul > 0) return DmUtteranceScript.koreanHeavy;
  if (cjk > 0) return DmUtteranceScript.japaneseHeavy;

  return DmUtteranceScript.ambiguous;
}

/// Resolves [ambiguous] using app UI language: `ja` → assume Korean line, else Japanese line.
DmUtteranceScript resolveDmUtteranceScript(String text, {required String appLanguageCode}) {
  final c = classifyDmUtteranceScript(text);
  if (c != DmUtteranceScript.ambiguous) return c;
  return appLanguageCode == 'ja' ? DmUtteranceScript.koreanHeavy : DmUtteranceScript.japaneseHeavy;
}
