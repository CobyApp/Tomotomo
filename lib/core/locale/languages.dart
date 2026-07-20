/// Canonical UI + friend language codes. `zh` = Simplified (简体).
const Set<String> kSupportedLanguages = {'ko', 'ja', 'en', 'zh'};

/// Normalizes an arbitrary code to a supported one; defaults to `ko`.
String normalizeLang(String? code) {
  if (code == null) return 'ko';
  final c = code.trim().toLowerCase();
  if (kSupportedLanguages.contains(c)) return c;
  if (c.startsWith('zh')) return 'zh';
  if (c.startsWith('ko')) return 'ko';
  if (c.startsWith('ja')) return 'ja';
  if (c.startsWith('en')) return 'en';
  return 'ko';
}

/// The name of a language in its OWN script (endonym), for language pickers —
/// so a user can recognize and pick it regardless of the current UI language.
String languageEndonym(String code) {
  switch (normalizeLang(code)) {
    case 'ja':
      return '日本語';
    case 'en':
      return 'English';
    case 'zh':
      return '中文';
    case 'ko':
    default:
      return '한국어';
  }
}

/// Pronunciation-aid system used for a friend language's vocabulary.
enum ReadingSystem { hiragana, romaja, pinyin, ipa }

ReadingSystem readingSystemFor(String friendLanguage) {
  switch (normalizeLang(friendLanguage)) {
    case 'ja':
      return ReadingSystem.hiragana;
    case 'zh':
      return ReadingSystem.pinyin;
    case 'en':
      return ReadingSystem.ipa;
    case 'ko':
    default:
      return ReadingSystem.romaja;
  }
}
