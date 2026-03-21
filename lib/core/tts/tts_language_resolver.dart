/// Picks Korean or Japanese TTS only, from script in [raw] and UI language as fallback.
class TtsLanguageDecision {
  /// Engine locale id for `FlutterTts.setLanguage` (e.g. `ko-KR`, `ja-JP`).
  final String engineLocaleId;

  /// Normalized text safe for speech (markdown stripped, whitespace collapsed).
  final String spokenText;

  const TtsLanguageDecision({
    required this.engineLocaleId,
    required this.spokenText,
  });
}

final _reHangul = RegExp(r'[\uAC00-\uD7A3]');
final _reKana = RegExp(r'[\u3040-\u30FF\u31F0-\u31FF]'); // hiragana, katakana, katakana ext
final _reCjk = RegExp(r'[\u4E00-\u9FFF\u3400-\u4DBF]'); // CJK unified + ext A

int _countMatches(RegExp re, String s) => re.allMatches(s).length;

/// Strips light markdown / code fences so TTS reads continuous prose.
String normalizeTextForTts(String raw) {
  var s = raw.trim();
  if (s.isEmpty) return s;
  s = s.replaceAll(RegExp(r'```[\s\S]*?```'), ' ');
  s = s.replaceAll(RegExp(r'`+'), '');
  s = s.replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1');
  s = s.replaceAll(RegExp(r'\*([^*]+)\*'), r'$1');
  s = s.replaceAll(RegExp(r'__([^_]+)__'), r'$1');
  s = s.replaceAll(RegExp(r'_([^_]+)_'), r'$1');
  s = s.replaceAll(RegExp(r'\[([^\]]+)\]\([^)]*\)'), r'$1');
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  return s;
}

/// [appUiLanguage] is `ko` | `ja` from [LocaleNotifier] when script is ambiguous.
TtsLanguageDecision resolveTtsLanguage(String raw, {required String appUiLanguage}) {
  final text = normalizeTextForTts(raw);
  if (text.isEmpty) {
    return TtsLanguageDecision(
      engineLocaleId: appUiLanguage == 'ja' ? 'ja-JP' : 'ko-KR',
      spokenText: text,
    );
  }

  final h = _countMatches(_reHangul, text);
  final k = _countMatches(_reKana, text);
  final cjk = _countMatches(_reCjk, text);

  final String locale;
  if (k > 0 && h == 0) {
    locale = 'ja-JP';
  } else if (h > 0 && k == 0) {
    locale = 'ko-KR';
  } else if (h > 0 && k > 0) {
    locale = h >= k ? 'ko-KR' : 'ja-JP';
  } else if (cjk > 0) {
    // Kanji-only snippets: this app targets Japanese study — prefer Japanese unless UI is Korean-only context.
    locale = appUiLanguage == 'ko' ? 'ko-KR' : 'ja-JP';
  } else {
    // Latin / digits / emoji only: match UI language voice (still only ko or ja engines).
    locale = appUiLanguage == 'ja' ? 'ja-JP' : 'ko-KR';
  }

  return TtsLanguageDecision(engineLocaleId: locale, spokenText: text);
}
