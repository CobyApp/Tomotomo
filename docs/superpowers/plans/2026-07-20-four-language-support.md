# Four-Language Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Support four app-UI languages (ko/ja/en/zh-Hans) and four friend languages (ko/ja/en/zh-Hans) as independent axes, with consistent prompting across all 16 combinations.

**Architecture:** Fix each element's language source — friend reply = friend language; UI + explanation/gloss = app language; word reading = per-friend-language rule. Introduce `Character.friendLanguage` (keeping `koreanNationalPersona`/`tutorLocale` as derived getters for backward compatibility). Drive vocabulary gloss selection by app language. Add complete `_en`/`_zh` UI string maps.

**Tech Stack:** Flutter 3.41 / Dart 3.11, Hive, on-device Gemma (flutter_gemma), provider.

**Spec:** `docs/superpowers/specs/2026-07-20-four-language-support-design.md`

**Verification after every task:** `flutter analyze` (must be clean) and the task's tests. Full suite (`flutter test`) at task end.

---

## File Structure

- Create `lib/core/locale/languages.dart` — canonical code set + helpers (`kSupportedLanguages`, `normalizeLang`, `readingSystemFor`).
- Modify `lib/core/locale/study_language.dart` — keep helper, no longer ko/ja-only assumption in callers.
- Modify `lib/presentation/locale/locale_notifier.dart` — accept 4 codes.
- Modify `lib/presentation/locale/friend_language_notifier.dart` — accept 4 codes.
- Modify `lib/domain/entities/character.dart` — add `friendLanguage`, derive legacy getters, 4-way notebook lang.
- Modify `lib/domain/entities/character_record.dart` — allow 4 `language` values (already `String`; adjust docs/defaults only).
- Modify `lib/domain/entities/chat_message.dart` + `lib/data/repositories/ai_response_parser.dart` — gloss by app language incl. `meaning_en`/`meaning_zh`.
- Modify `lib/data/repositories/ai_system_prompt_builder.dart` — reply/analysis/level guidance/reading 4-way.
- Modify `lib/data/repositories/litert_lm_ai_repository_impl.dart` — pass app-language gloss key.
- Modify `lib/core/l10n/app_strings.dart` — add `_en`, `_zh`; 4-way `of()`.
- Modify `lib/presentation/settings/language_settings_screen.dart` — 4 tiles.
- Modify `lib/presentation/onboarding/onboarding_screen.dart` — 4 app-lang + 4 friend-lang choices.
- Modify `lib/presentation/character_form/custom_character_editor_body.dart` — 4-way friend-language selector.
- Modify `lib/presentation/notebook/word_book_screen.dart` + `notebook_study_screen.dart` — 4 notebook segments.
- Modify `lib/data/character/characters_data.dart` — add EN/ZH built-in friends.

---

## Task 1: Language constants & helpers

**Files:**
- Create: `lib/core/locale/languages.dart`
- Test: `test/core/locale/languages_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/core/locale/languages_test.dart
import 'package:aichat/core/locale/languages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('supported set is exactly ko/ja/en/zh', () {
    expect(kSupportedLanguages, {'ko', 'ja', 'en', 'zh'});
  });

  test('normalizeLang keeps supported, falls back to ko', () {
    expect(normalizeLang('en'), 'en');
    expect(normalizeLang('zh'), 'zh');
    expect(normalizeLang('zh-Hans'), 'zh');
    expect(normalizeLang('fr'), 'ko');
    expect(normalizeLang(null), 'ko');
  });

  test('readingSystemFor per friend language', () {
    expect(readingSystemFor('ja'), ReadingSystem.hiragana);
    expect(readingSystemFor('ko'), ReadingSystem.romaja);
    expect(readingSystemFor('zh'), ReadingSystem.pinyin);
    expect(readingSystemFor('en'), ReadingSystem.ipa);
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/core/locale/languages_test.dart`
Expected: FAIL (target of URI doesn't exist).

- [ ] **Step 3: Implement**

```dart
// lib/core/locale/languages.dart

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
```

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/core/locale/languages_test.dart` → PASS. Then `flutter analyze` → clean.

- [ ] **Step 5: Commit**

```bash
git add lib/core/locale/languages.dart test/core/locale/languages_test.dart
git commit -m "feat(locale): canonical 4-language code set + reading systems"
```

---

## Task 2: Locale + friend-language notifiers accept 4 codes

**Files:**
- Modify: `lib/presentation/locale/locale_notifier.dart`
- Modify: `lib/presentation/locale/friend_language_notifier.dart`
- Test: `test/presentation/locale/locale_notifiers_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/presentation/locale/locale_notifiers_test.dart
import 'package:aichat/domain/entities/profile.dart';
import 'package:aichat/domain/repositories/profile_repository.dart';
import 'package:aichat/presentation/locale/friend_language_notifier.dart';
import 'package:aichat/presentation/locale/locale_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements ProfileRepository {
  Profile? stored;
  String? friendLang;
  @override
  Future<Profile?> getProfile(String userId) async =>
      stored ??
      Profile(
        id: userId,
        appLanguage: 'en',
        learningLanguage: 'zh',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
  @override
  Future<Profile> updateProfile(Profile profile) async {
    stored = profile;
    return profile;
  }
  @override
  Future<bool> isOnboarded() async => false;
  @override
  Future<void> setOnboarded() async {}
  @override
  Future<String?> getNationality() async => null;
  @override
  Future<void> setNationality(String? value) async {}
  @override
  Future<String?> getFriendLanguage() async => friendLang;
  @override
  Future<void> setFriendLanguage(String code) async => friendLang = code;
}

void main() {
  test('LocaleNotifier loads and sets en/zh', () async {
    final repo = _FakeRepo();
    final n = LocaleNotifier(repo);
    await n.loadFromProfile('local');
    expect(n.languageCode, 'en');
    final p = (await repo.getProfile('local'))!;
    await n.setAppLanguage('zh', p);
    expect(n.languageCode, 'zh');
  });

  test('FriendLanguageNotifier accepts en/zh', () async {
    final repo = _FakeRepo();
    final n = FriendLanguageNotifier(repo);
    await n.setLanguage('zh');
    expect(n.chosen, 'zh');
    await n.setLanguage('en');
    expect(n.chosen, 'en');
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/presentation/locale/locale_notifiers_test.dart`
Expected: FAIL — `setAppLanguage('zh')` and `setLanguage('zh')` are rejected by the current `ko`/`ja`-only guards, so values don't change.

- [ ] **Step 3: Implement**

In `lib/presentation/locale/locale_notifier.dart`, add `import '../../core/locale/languages.dart';` and replace the guard logic:

```dart
  Future<void> loadFromProfile(String userId) async {
    try {
      final p = await _profileRepo.getProfile(userId);
      if (p != null && kSupportedLanguages.contains(p.appLanguage)) {
        _languageCode = p.appLanguage;
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Persists locally and updates the in-memory locale.
  Future<void> setAppLanguage(String code, Profile profile) async {
    if (!kSupportedLanguages.contains(code)) return;
    final updated = profile.copyWith(appLanguage: code);
    await _profileRepo.updateProfile(updated);
    _languageCode = code;
    notifyListeners();
  }
```

In `lib/presentation/locale/friend_language_notifier.dart`, add `import '../../core/locale/languages.dart';` and replace `setLanguage`:

```dart
  Future<void> setLanguage(String code) async {
    if (!kSupportedLanguages.contains(code)) return;
    await _profileRepo.setFriendLanguage(code);
    _chosen = code;
    notifyListeners();
  }
```

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/presentation/locale/locale_notifiers_test.dart` → PASS. `flutter analyze` → clean.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/locale/locale_notifier.dart lib/presentation/locale/friend_language_notifier.dart test/presentation/locale/locale_notifiers_test.dart
git commit -m "feat(locale): notifiers accept all four language codes"
```

---

## Task 3: Character.friendLanguage + migration

**Files:**
- Modify: `lib/domain/entities/character.dart`
- Test: `test/domain/entities/character_language_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/domain/entities/character_language_test.dart
import 'package:aichat/domain/entities/character.dart';
import 'package:aichat/domain/entities/character_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Character _base({String? friendLanguage, bool koreanPersona = false, String tutorLocale = 'ko'}) => Character(
      id: 'x', name: 'n', nameJp: 'n', nameKanji: 'n', level: 'intermediate',
      description: '', age: 0, schoolYear: '', occupation: '',
      traits: const [], interests: const [], speechStyle: '',
      primaryColor: const Color(0xFF000000), secondaryColor: const Color(0xFFFFFFFF),
      hairStyle: '', hairColor: '', eyeColor: '', outfit: '', accessories: const [],
      selfReference: '', commonPhrases: const [], emotionalResponses: const {},
      imageUrl: '', imagePath: '',
      friendLanguage: friendLanguage,
      koreanNationalPersona: koreanPersona, tutorLocale: tutorLocale);

void main() {
  test('explicit friendLanguage wins', () {
    expect(_base(friendLanguage: 'zh').friendLanguage, 'zh');
    expect(_base(friendLanguage: 'en').defaultNotebookLangForVocabSave, 'en');
  });

  test('legacy getters derive from friendLanguage', () {
    expect(_base(friendLanguage: 'ko').koreanNationalPersona, isTrue);
    expect(_base(friendLanguage: 'ja').koreanNationalPersona, isFalse);
  });

  test('migration: no friendLanguage falls back to old fields', () {
    expect(_base(koreanPersona: true).friendLanguage, 'ko');
    expect(_base(tutorLocale: 'ja').friendLanguage, 'ja');
    expect(_base().friendLanguage, 'ko'); // default
  });

  test('fromRecord maps record.language to friendLanguage', () {
    final r = CharacterRecord.draft(name: 'A', language: 'zh');
    expect(Character.fromRecord(r).friendLanguage, 'zh');
  });

  test('fromJson reads new friendLanguage, else derives', () {
    final withNew = Character.fromJson({..._json(), 'friendLanguage': 'en'});
    expect(withNew.friendLanguage, 'en');
    final legacy = Character.fromJson({..._json(), 'koreanNationalPersona': true});
    expect(legacy.friendLanguage, 'ko');
  });
}

Map<String, dynamic> _json() => {
      'id': 'x', 'name': 'n', 'nameJp': 'n', 'nameKanji': 'n', 'level': 'intermediate',
      'description': '', 'age': 0, 'schoolYear': '', 'occupation': '',
      'traits': const [], 'interests': const [], 'speechStyle': '',
      'primaryColor': '4278190080', 'secondaryColor': '4294967295',
      'hairStyle': '', 'hairColor': '', 'eyeColor': '', 'outfit': '',
      'accessories': const <String>[], 'selfReference': '',
      'commonPhrases': const <String>[], 'emotionalResponses': const <String, List<String>>{},
      'imageUrl': '', 'imagePath': '',
    };
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/domain/entities/character_language_test.dart`
Expected: FAIL — `friendLanguage` is not a parameter/field yet.

- [ ] **Step 3: Implement**

In `lib/domain/entities/character.dart`:

Add import at top: `import '../../core/locale/languages.dart';`

Replace the two legacy fields + constructor params with a stored `_friendLanguage` plus derived getters. Change the field block:

```dart
  /// Legacy immersion hint; retained for backward compat. Derived from friendLanguage.
  final String tutorLocale;

  /// Explicit friend language when known (`ko`|`ja`|`en`|`zh`); else null → derive.
  final String? _friendLanguageRaw;

  /// Legacy flag; retained for backward compat. Derived from friendLanguage.
  final bool _koreanNationalPersonaRaw;
```

Change constructor params `this.tutorLocale = 'ko'` and `this.koreanNationalPersona = false` to:

```dart
    this.tutorLocale = 'ko',
    String? friendLanguage,
    bool koreanNationalPersona = false,
    this.omitSecondaryDisplayName = false,
  })  : _friendLanguageRaw = friendLanguage,
        _koreanNationalPersonaRaw = koreanNationalPersona;
```

Add derived getters (place near the other getters):

```dart
  /// The language the friend speaks and replies in. Explicit when set;
  /// otherwise migrated from legacy fields.
  String get friendLanguage {
    final raw = _friendLanguageRaw;
    if (raw != null && kSupportedLanguages.contains(normalizeLang(raw))) {
      return normalizeLang(raw);
    }
    if (tutorLocale == 'ja') return 'ja';
    if (_koreanNationalPersonaRaw) return 'ko';
    return 'ko';
  }

  /// Backward-compatible: true when the friend speaks Korean.
  bool get koreanNationalPersona => friendLanguage == 'ko';
```

Replace `defaultNotebookLangForVocabSave` with:

```dart
  /// Notebook segment for vocabulary [+] saves: the friend language's script.
  String get defaultNotebookLangForVocabSave => friendLanguage;
```

In `fromRecord`, replace the trailing language args:

```dart
      tutorLocale: 'ko',
      friendLanguage: r.language,
      omitSecondaryDisplayName: true,
```
(Remove the `final isJaPersona = r.language == 'ja';` dependency for persona; keep `isJaPersona` only where it still selects the `occupation` string.)

In `fromJson`, replace the two legacy reads:

```dart
      tutorLocale: json['tutorLocale'] as String? ?? 'ko',
      friendLanguage: json['friendLanguage'] as String?,
      koreanNationalPersona: json['koreanNationalPersona'] as bool? ?? false,
```

In `toJson`, replace `'koreanNationalPersona': koreanNationalPersona,` with both, so old readers still work:

```dart
      'tutorLocale': tutorLocale,
      'friendLanguage': friendLanguage,
      'koreanNationalPersona': koreanNationalPersona,
```

Note: `vocabularyMeaningPickMode` getter is removed in Task 5; leave it untouched here.

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/domain/entities/character_language_test.dart` → PASS. `flutter analyze` → clean (fix any consumer that set `koreanNationalPersona:` positionally — all use named args, so unaffected).

- [ ] **Step 5: Commit**

```bash
git add lib/domain/entities/character.dart test/domain/entities/character_language_test.dart
git commit -m "feat(character): friendLanguage field with backward-compatible migration"
```

---

## Task 4: CharacterRecord allows four languages

**Files:**
- Modify: `lib/domain/entities/character_record.dart`
- Test: `test/domain/entities/character_record_lang_test.dart`

`language` is already `String`; this task only updates the doc comment and confirms round-trip for `en`/`zh`. Default stays `'ja'`.

- [ ] **Step 1: Write the failing test**

```dart
// test/domain/entities/character_record_lang_test.dart
import 'package:aichat/domain/entities/character_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round-trips en/zh language', () {
    final r = CharacterRecord.fromJson({
      'id': '1', 'name': 'A', 'language': 'zh', 'level': 'intermediate',
      'created_at': '2026-01-01T00:00:00.000', 'updated_at': '2026-01-01T00:00:00.000',
    });
    expect(r.language, 'zh');
    expect(r.toJson()['language'], 'zh');
    expect(CharacterRecord.draft(name: 'B', language: 'en').language, 'en');
  });
}
```

- [ ] **Step 2: Run to verify it fails or passes**

Run: `flutter test test/domain/entities/character_record_lang_test.dart`
Expected: likely PASS already (field is a free `String`). If field names in `fromJson` differ, adjust the test's keys to match the real ones (check `character_record.dart` lines 78–103). This task's value is the regression guard + doc update.

- [ ] **Step 3: Update doc comment**

Change the `[language]` doc (line ~3) to: `/// Friend language ([language]): 'ko' | 'ja' | 'en' | 'zh' (Simplified).`

- [ ] **Step 4: Run tests** → PASS. `flutter analyze` → clean.

- [ ] **Step 5: Commit**

```bash
git add lib/domain/entities/character_record.dart test/domain/entities/character_record_lang_test.dart
git commit -m "feat(character-record): document + guard four language values"
```

---

## Task 5: Vocabulary gloss selection by app language (add en/zh)

**Files:**
- Modify: `lib/domain/entities/chat_message.dart`
- Modify: `lib/data/repositories/ai_response_parser.dart`
- Modify: `lib/data/repositories/litert_lm_ai_repository_impl.dart`
- Modify: `lib/domain/entities/character.dart` (remove now-unused `vocabularyMeaningPickMode` getter)
- Test: `test/domain/entities/vocabulary_gloss_test.dart`

Approach: extend `VocabularyMeaningPickMode` with `preferEnglishGloss` and `preferChineseGloss`, one per app language. The mode is already chosen from the app UI language at the call site in `litert_lm_ai_repository_impl.dart`.

- [ ] **Step 1: Write the failing test**

```dart
// test/domain/entities/vocabulary_gloss_test.dart
import 'package:aichat/domain/entities/chat_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preferEnglishGloss picks meaning_en', () {
    final v = Vocabulary.tryParseLoose({
      'word': '天気', 'reading': 'てんき',
      'meaning_en': 'weather', 'meaning_ko': '날씨', 'meaning_ja': '天気',
    }, meaningMode: VocabularyMeaningPickMode.preferEnglishGloss);
    expect(v!.meaning, 'weather');
  });

  test('preferChineseGloss picks meaning_zh', () {
    final v = Vocabulary.tryParseLoose({
      'word': '天気', 'reading': 'てんき',
      'meaning_zh': '天气', 'meaning_ko': '날씨',
    }, meaningMode: VocabularyMeaningPickMode.preferChineseGloss);
    expect(v!.meaning, '天气');
  });

  test('preferEnglishGloss falls back to generic meaning', () {
    final v = Vocabulary.tryParseLoose({
      'word': 'w', 'reading': 'r', 'meaning': 'fallback',
    }, meaningMode: VocabularyMeaningPickMode.preferEnglishGloss);
    expect(v!.meaning, 'fallback');
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/domain/entities/vocabulary_gloss_test.dart`
Expected: FAIL — `preferEnglishGloss` / `preferChineseGloss` don't exist.

- [ ] **Step 3: Implement**

In `lib/domain/entities/chat_message.dart` enum, add two cases:

```dart
  /// English study notes: prefer English gloss keys.
  preferEnglishGloss,

  /// Chinese study notes: prefer Chinese gloss keys.
  preferChineseGloss,
```

In the `word` switch in `tryParseLoose`, add generic branches for the two new modes (same generic keys as `neutral`):

```dart
      VocabularyMeaningPickMode.preferEnglishGloss ||
      VocabularyMeaningPickMode.preferChineseGloss => pickString(const [
        'word', 'term', 'expression', '単語', 'japanese', 'surface',
        'headword', 'lemma', 'token', 'phrase', 'word_ko', 'wordKo',
        'phrase_ko', 'surface_ko', 'hanzi', 'pinyin_word',
      ]),
```

In the `meaning` switch, add:

```dart
      VocabularyMeaningPickMode.preferEnglishGloss => pickString(const [
        'meaning_en', 'meaningEn', 'english_meaning', 'gloss_en', 'en_meaning',
        'english', 'en_gloss',
        'meaning', 'definition', 'gloss', 'translation', 'mean',
        'meaning_ko', 'meaningKo', 'meaning_ja', 'meaningJa',
      ]),
      VocabularyMeaningPickMode.preferChineseGloss => pickString(const [
        'meaning_zh', 'meaningZh', 'chinese_meaning', 'gloss_zh', 'zh_meaning',
        'chinese', 'zh_gloss',
        'meaning', 'definition', 'gloss', 'translation', 'mean',
        'meaning_ko', 'meaningKo', 'meaning_ja', 'meaningJa',
      ]),
```

In `lib/data/repositories/ai_response_parser.dart`:
- After the existing `meaningJa`/`meaningKo` extraction (lines ~71–72), add:

```dart
  final meaningEn = _extractJsonStringValue(s, 'meaning_en') ?? _extractJsonStringValue(s, 'meaningEn');
  final meaningZh = _extractJsonStringValue(s, 'meaning_zh') ?? _extractJsonStringValue(s, 'meaningZh');
```
- After lines ~86–87 writing `meaning_ja`/`meaning_ko`, add:

```dart
  if (meaningEn != null && meaningEn.trim().isNotEmpty) item['meaning_en'] = meaningEn.trim();
  if (meaningZh != null && meaningZh.trim().isNotEmpty) item['meaning_zh'] = meaningZh.trim();
```
- Near the `copyIfEmpty` block (lines ~222–223), add:

```dart
  copyIfEmpty('meaning_en', ['english', 'en_gloss', 'english_meaning', 'definition_en', 'def_en']);
  copyIfEmpty('meaning_zh', ['chinese', 'zh_gloss', 'chinese_meaning', 'definition_zh', 'def_zh']);
```
- In the second normalization block (lines ~271, ~320–321), mirror the `meaningJa`/`meaningKo` extraction+write for `meaning_en`/`meaning_zh`.

In `lib/data/repositories/litert_lm_ai_repository_impl.dart`, replace the `meaningMode` computation in `generateExpressionAnalysis`:

```dart
    final meaningMode = switch (appUiLanguageCode.toLowerCase().substring(0, appUiLanguageCode.length >= 2 ? 2 : appUiLanguageCode.length)) {
      'ja' => VocabularyMeaningPickMode.preferJapaneseGloss,
      'en' => VocabularyMeaningPickMode.preferEnglishGloss,
      'zh' => VocabularyMeaningPickMode.preferChineseGloss,
      _ => VocabularyMeaningPickMode.preferKoreanGloss,
    };
```

In `lib/domain/entities/character.dart`, delete the now-unused `vocabularyMeaningPickMode` getter (lines ~115–121) and the `expectsKoreanStudyNotes`/`expectsJapaneseStudyNotes` getters **only if** no consumer references them (grep first: `grep -rn "vocabularyMeaningPickMode\|expectsKoreanStudyNotes\|expectsJapaneseStudyNotes" lib/`). If referenced, leave them.

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/domain/entities/vocabulary_gloss_test.dart` → PASS. `flutter analyze` → clean.

- [ ] **Step 5: Commit**

```bash
git add lib/domain/entities/chat_message.dart lib/data/repositories/ai_response_parser.dart lib/data/repositories/litert_lm_ai_repository_impl.dart lib/domain/entities/character.dart test/domain/entities/vocabulary_gloss_test.dart
git commit -m "feat(vocab): app-language gloss selection incl. English + Chinese"
```

---

## Task 6: Prompt builder — 4-way reply, analysis, level, reading

**Files:**
- Modify: `lib/data/repositories/ai_system_prompt_builder.dart`
- Test: `test/data/repositories/ai_system_prompt_builder_test.dart` (extend existing)

- [ ] **Step 1: Write the failing tests (append to the existing file)**

```dart
  test('reply prompt uses the friend language', () {
    final en = buildChatReplySystemPrompt(_friend('en'));
    expect(en, contains('natural English'));
    final zh = buildChatReplySystemPrompt(_friend('zh'));
    expect(zh, contains('Simplified Chinese'));
  });

  test('analysis prompt explains in the app language', () {
    final p = buildExpressionAnalysisSystemPrompt(
      character: _friend('ja'), appUiLanguageCode: 'en');
    expect(p, contains('English'));
    expect(p, contains('meaning_en'));
  });

  test('analysis reading rule matches the friend language', () {
    final zh = buildExpressionAnalysisSystemPrompt(
      character: _friend('zh'), appUiLanguageCode: 'ko');
    expect(zh.toLowerCase(), contains('pinyin'));
  });
```

Add a helper in the test file:

```dart
Character _friend(String friendLanguage) => Character(
      id: 'x', name: 'n', nameJp: 'n', nameKanji: 'n', level: 'intermediate',
      description: '', age: 0, schoolYear: '', occupation: '',
      traits: const [], interests: const [], speechStyle: '',
      primaryColor: const Color(0xFF000000), secondaryColor: const Color(0xFFFFFFFF),
      hairStyle: '', hairColor: '', eyeColor: '', outfit: '', accessories: const [],
      selfReference: '', commonPhrases: const [], emotionalResponses: const {},
      imageUrl: '', imagePath: '', friendLanguage: friendLanguage);
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/data/repositories/ai_system_prompt_builder_test.dart`
Expected: FAIL — English/Chinese/pinyin strings absent (builder is ko/ja only).

- [ ] **Step 3: Implement**

Add a language-name helper and rewrite the branch logic. At top of `ai_system_prompt_builder.dart` add `import '../../domain/entities/character.dart';` (already present) and:

```dart
String _friendLanguageName(String code) {
  switch (code) {
    case 'ja':
      return 'natural Japanese';
    case 'en':
      return 'natural English';
    case 'zh':
      return 'natural Simplified Chinese (简体中文)';
    case 'ko':
    default:
      return 'natural Korean (Hangul)';
  }
}

String _appLanguageName(String code) {
  switch (code.toLowerCase().startsWith('ja') ? 'ja'
      : code.toLowerCase().startsWith('en') ? 'en'
      : code.toLowerCase().startsWith('zh') ? 'zh' : 'ko') {
    case 'ja':
      return 'Japanese';
    case 'en':
      return 'English';
    case 'zh':
      return 'Simplified Chinese (简体中文)';
    default:
      return 'Korean';
  }
}
```

Rewrite `_levelGuidance` to take the friend language:

```dart
String _levelGuidance(String level, String friendLanguage) {
  String reg(String ko, String ja, String en, String zh) {
    switch (friendLanguage) {
      case 'ja':
        return ja;
      case 'en':
        return en;
      case 'zh':
        return zh;
      default:
        return ko;
    }
  }
  final casual = reg('반말/편한 말투', 'フレンドリーなタメ口', 'a casual, friendly tone', '轻松친切的口语（你）');
  final trendy = reg('요즘 쓰는 MZ 표현', '若者言葉・流行り言葉', 'current everyday slang', '网络流行语/年轻人用语');
  final polite = reg('존댓말·격식 있는 표현', '敬語・丁寧語', 'a polite, professional register', '商务敬语（您）');
  switch (level) {
    case 'beginner':
      return 'The learner is a BEGINNER. Use very simple, short sentences and '
          'basic everyday vocabulary. Warm, casual, friendly tone ($casual). '
          'Avoid rare words, idioms, and complex grammar.';
    case 'advanced':
      return 'The learner is ADVANCED. Speak like a native at a natural, rich '
          'level — idioms, nuance, and varied vocabulary are welcome.';
    case 'business':
      return 'This is BUSINESS/FORMAL practice. Use $polite. Clear, courteous, '
          'professional wording. Avoid slang and overly casual speech.';
    case 'intermediate':
    default:
      return 'The learner is INTERMEDIATE. Use natural everyday conversational '
          'language of moderate difficulty. Casual, friendly speech; you may '
          'sprinkle common $trendy naturally (not excessively).';
  }
}
```

Rewrite `buildChatReplySystemPrompt` header lines:

```dart
String buildChatReplySystemPrompt(Character character, {String? userName}) {
  final friendLang = character.friendLanguage;
  final replyLanguage = _friendLanguageName(friendLang);
  final otherScripts = kSupportedLanguages
      .where((c) => c != friendLang)
      .map(_friendLanguageName)
      .join(', ');
  // ... keep the ABOUT THE PERSON block unchanged ...
```

(Add `import '../../core/locale/languages.dart';`.) Replace `SPEAKING LEVEL` line with `${_levelGuidance(character.level, friendLang)}` and REPLY RULE 1 with:

```
1. Reply in $replyLanguage only. Do not use other languages ($otherScripts) or add a translation.
```

Rewrite `buildExpressionAnalysisSystemPrompt`:

```dart
  final explanationLanguage = _appLanguageName(appUiLanguageCode);
  final glossKey = appUiLanguageCode.toLowerCase().startsWith('ja') ? 'meaning_ja'
      : appUiLanguageCode.toLowerCase().startsWith('en') ? 'meaning_en'
      : appUiLanguageCode.toLowerCase().startsWith('zh') ? 'meaning_zh' : 'meaning_ko';
  final friendLang = character.friendLanguage;
  final sourceLanguage = _friendLanguageName(friendLang);
  final readingRule = switch (readingSystemFor(friendLang)) {
    ReadingSystem.hiragana => 'Write the complete Hiragana reading for every Japanese word; include it even when the word is already Kana.',
    ReadingSystem.romaja => 'Write the Revised Romanization (Latin) reading for every Korean word or expression.',
    ReadingSystem.pinyin => 'Write Hanyu Pinyin with tone marks for every Chinese word or expression.',
    ReadingSystem.ipa => 'Provide a simple IPA pronunciation when helpful; the reading may be empty for common English words.',
  };
  final readingRequired = friendLang != 'en';
```

Use `$glossKey`, `$explanationLanguage`, `$sourceLanguage`, `$readingRule` in the prompt body (replacing `$meaningKey`, the old `$explanationLanguage`, `$sourceLanguage`, `$readingRule`). Keep the rest identical. In the reading-required clause of the JSON schema instructions, phrase it as: "Every item MUST have a non-empty \"reading\"." only when `readingRequired`, else "Include a \"reading\" when helpful." Implement with a small interpolated variable.

Also relax `_analysisNeedsRepair` in `litert_lm_ai_repository_impl.dart` so a missing reading does not trigger repair for English friends: change the top-level function to accept the character and skip the reading check when `character.friendLanguage == 'en'`. Concretely, pass `character` into `_analysisNeedsRepair(parsed, character)` and guard:

```dart
bool _analysisNeedsRepair(ChatMessage message, Character character) {
  if ((message.lineTranslation?.trim().isEmpty ?? true) ||
      (message.explanation?.trim().isEmpty ?? true)) {
    return true;
  }
  final vocabulary = message.vocabulary;
  if (vocabulary == null || vocabulary.length < 2) return true;
  final requireReading = character.friendLanguage != 'en';
  return vocabulary.any((item) =>
      (requireReading && (item.reading?.trim().isEmpty ?? true)) ||
      item.meaning.runes.length < 15);
}
```

Update its two call sites to pass `character`.

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/data/repositories/ai_system_prompt_builder_test.dart` → PASS. `flutter analyze` → clean.

- [ ] **Step 5: Commit**

```bash
git add lib/data/repositories/ai_system_prompt_builder.dart lib/data/repositories/litert_lm_ai_repository_impl.dart test/data/repositories/ai_system_prompt_builder_test.dart
git commit -m "feat(prompt): 4-language reply/analysis, per-language register + reading"
```

---

## Task 7: App UI strings — `_en` and `_zh` maps + 4-way `of()`

**Files:**
- Modify: `lib/core/l10n/app_strings.dart`
- Test: `test/core/l10n/app_strings_test.dart`

The concrete deliverable is the translated content. Author `_en` and `_zh` as complete copies of the `_ko` key set (every key present), translating each value. `zh` = Simplified. Preserve `{placeholder}` tokens (e.g. `{points}`, `{remaining}`, `{max}`) verbatim.

- [ ] **Step 1: Write the failing test**

```dart
// test/core/l10n/app_strings_test.dart
import 'package:aichat/core/l10n/app_strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('en and zh resolve (not identical to ko) for a known key', () {
    expect(AppStrings.of('en', 'tabChats'), 'Chats');
    expect(AppStrings.of('zh', 'tabChats'), '聊天');
  });

  test('unknown language falls back to ko', () {
    expect(AppStrings.of('fr', 'tabChats'), AppStrings.of('ko', 'tabChats'));
  });

  test('placeholder substitution works in en', () {
    final s = AppStrings.of('en', 'adEarnTitle');
    expect(s, isNotEmpty);
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/core/l10n/app_strings_test.dart`
Expected: FAIL — `of('en', ...)` currently returns the `_ko` value.

- [ ] **Step 3: Implement**

Add two full maps after `_ja`:

```dart
  static const Map<String, String> _en = {
    'tabChats': 'Chats',
    'tabCharacters': 'Friends',
    'tabNotebook': 'Word Book',
    'tabSettings': 'Settings',
    // … every key from _ko, translated to English …
  };

  static const Map<String, String> _zh = {
    'tabChats': '聊天',
    'tabCharacters': '朋友',
    'tabNotebook': '生词本',
    'tabSettings': '设置',
    // … every key from _ko, translated to Simplified Chinese …
  };
```

Replace `of()`:

```dart
  static String of(String languageCode, String key, {Map<String, String>? params}) {
    final code = languageCode.toLowerCase();
    final Map<String, String> m = code.startsWith('ja')
        ? _ja
        : code.startsWith('en')
            ? _en
            : code.startsWith('zh')
                ? _zh
                : _ko;
    var s = m[key] ?? _en[key] ?? _ko[key] ?? key;
    if (params != null) {
      params.forEach((k, v) => s = s.replaceAll('{$k}', v));
    }
    return s;
  }
```

Also update the `settingsAppLanguageSubtitle` value in every map to list all four (e.g. `한국어 / 日本語 / English / 中文`).

Completeness guard: after authoring, run this to ensure no key is missing from `_en`/`_zh` (should print nothing):

```bash
grep -oE "^\s*'[a-zA-Z0-9_]+':" lib/core/l10n/app_strings.dart | sort | uniq -c | awk '$1<4'
```
Any key with a count < 4 (present in fewer than ko/ja/en/zh) is missing a translation — add it. (Keys nested only in some maps will show; verify each.)

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/core/l10n/app_strings_test.dart` → PASS. `flutter analyze` → clean.

- [ ] **Step 5: Commit**

```bash
git add lib/core/l10n/app_strings.dart test/core/l10n/app_strings_test.dart
git commit -m "feat(l10n): full English + Simplified Chinese UI strings"
```

---

## Task 8: Settings, onboarding, editor — four language choices

**Files:**
- Modify: `lib/presentation/settings/language_settings_screen.dart`
- Modify: `lib/presentation/onboarding/onboarding_screen.dart`
- Modify: `lib/presentation/character_form/custom_character_editor_body.dart`
- Test: manual + existing widget tests must still pass.

- [ ] **Step 1: Language settings — add English + Chinese tiles**

After the Japanese `AppSettingsNavTile`, add two more, mirroring the pattern:

```dart
                  AppSettingsNavTile(
                    icon: Icons.language_rounded,
                    title: context.tr('langEnglish'),
                    showChevron: false,
                    trailing: profile.appLanguage == 'en'
                        ? Icon(Icons.check_circle_rounded, color: p.coral, size: 24)
                        : null,
                    onTap: () => _set(context, 'en', profile),
                  ),
                  AppSettingsNavTile(
                    icon: Icons.language_rounded,
                    title: context.tr('langChinese'),
                    showChevron: false,
                    trailing: profile.appLanguage == 'zh'
                        ? Icon(Icons.check_circle_rounded, color: p.coral, size: 24)
                        : null,
                    onTap: () => _set(context, 'zh', profile),
                  ),
```

Add keys `langEnglish` (`English`/`英語`/`English`/`英语`) and `langChinese` (`중국어`/`中国語`/`Chinese`/`中文`) to all four maps in Task 7 (add them there; note here so they aren't forgotten).

- [ ] **Step 2: Onboarding — app language (Step 1) add 2 cards**

After the `🇯🇵 日本語` card in `_stepAppLanguage`, add:

```dart
        const SizedBox(height: 14),
        _ChoiceCard(emoji: '🇺🇸', label: 'English', selected: appLang == 'en', onTap: () => _selectAppLanguage('en')),
        const SizedBox(height: 14),
        _ChoiceCard(emoji: '🇨🇳', label: '中文', selected: appLang == 'zh', onTap: () => _selectAppLanguage('zh')),
```

- [ ] **Step 3: Onboarding — friend language (Step 3) add 2 cards**

After the existing `🇰🇷` friend card in `_stepFriendLanguage`, add English + Chinese cards using keys `onboardingFriendEn` / `onboardingFriendZh` (add to all four string maps):

```dart
        const SizedBox(height: 14),
        _ChoiceCard(emoji: '🇺🇸', label: context.tr('onboardingFriendEn'), selected: _friendLanguage == 'en', onTap: () => setState(() => _friendLanguage = 'en')),
        const SizedBox(height: 14),
        _ChoiceCard(emoji: '🇨🇳', label: context.tr('onboardingFriendZh'), selected: _friendLanguage == 'zh', onTap: () => setState(() => _friendLanguage = 'zh')),
```

- [ ] **Step 4: Onboarding — nationality (optional) add 2 cards**

After `🇯🇵` nationality card, add `🇺🇸`/`🇨🇳` using keys `onboardingNationalityEn` / `onboardingNationalityZh`. Keep `other`.

- [ ] **Step 5: Character editor — 4-way friend language selector**

In `custom_character_editor_body.dart`, the field `_language` currently toggles ja/ko. Wherever the language is chosen in the UI (find the two-option control), replace with a 4-chip row (reuse the `_LevelChip` visual pattern already in this file). Each chip sets `_language` to `'ko'|'ja'|'en'|'zh'` with labels from keys `friendLangKo/Ja/En/Zh`. The save path already passes `language: _language` to `CharacterRecord.draft(...)`, so no save changes are needed.

- [ ] **Step 6: Verify**

Run: `flutter analyze` → clean. `flutter test` → all pass. Launch the app (see Task 11) and switch app language to English then Chinese; confirm tabs/settings render translated.

- [ ] **Step 7: Commit**

```bash
git add lib/presentation/settings/language_settings_screen.dart lib/presentation/onboarding/onboarding_screen.dart lib/presentation/character_form/custom_character_editor_body.dart lib/core/l10n/app_strings.dart
git commit -m "feat(ui): four-language choices in settings, onboarding, editor"
```

---

## Task 9: Word book — four notebook segments

**Files:**
- Modify: `lib/presentation/notebook/word_book_screen.dart`
- Modify: `lib/presentation/notebook/notebook_study_screen.dart`
- Test: manual.

- [ ] **Step 1: Segment selector**

The screen holds `_notebookLang` (default `'ko'`). Replace the current two-way language toggle with a selector over the languages that actually have entries. Compute available segments once per load:

```dart
  static const _allSegments = ['ko', 'ja', 'en', 'zh'];
```

When building the selector, show a chip per segment in `_allSegments` (or only those with entries if you prefer minimal UI). On tap, set `_notebookLang` and reload via the existing `listForCurrentUser(notebookLang: ...)` path. Default `_notebookLang` should follow the current friend language: initialize from `context.read<FriendLanguageNotifier>().resolve(appLang)` instead of hard-coded `'ko'`.

- [ ] **Step 2: Per-language font**

The existing `usePretendard = e.notebookLang == 'ko'` and `fontFamily: notebookLanguage == 'ko' ? 'Pretendard' : null` rules stay valid (Korean → Pretendard). Extend: for `zh`/`en`/`ja` leave `null` (system/rounded fallback already configured). No change required unless a Chinese-specific font is desired (out of scope).

- [ ] **Step 3: Verify**

Run: `flutter analyze` → clean. Manually add a Chinese friend, save a word, confirm it lands in the `zh` segment and displays.

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/notebook/word_book_screen.dart lib/presentation/notebook/notebook_study_screen.dart
git commit -m "feat(notebook): support four vocabulary segments"
```

---

## Task 10: Built-in English & Chinese friends

**Files:**
- Modify: `lib/data/character/characters_data.dart`
- Test: `test/data/character/characters_data_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/data/character/characters_data_test.dart
import 'package:aichat/data/character/characters_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('has at least one friend per language', () {
    final langs = characters.map((c) => c.friendLanguage).toSet();
    expect(langs.containsAll({'ko', 'ja', 'en', 'zh'}), isTrue);
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/data/character/characters_data_test.dart`
Expected: FAIL — only ko/ja friends exist.

- [ ] **Step 3: Implement**

Append two English and two Chinese `Character` entries to the `characters` list, following the existing `yuna`/`junho` structure. Set `friendLanguage: 'en'` (or `'zh'`), give each an `id`, `name`, `nameJp`/`nameKanji` (reuse the display name for non-JP friends), persona `traits`/`interests`/`speechStyle`, colors, and an `imageUrl`/`imagePath`. If no bundled avatar image exists for the new ids, reuse an existing asset path or add new assets under the image base path. Example skeleton for one English friend:

```dart
  Character(
    id: 'emily',
    name: 'Emily',
    nameJp: 'Emily',
    nameKanji: 'Emily',
    level: 'intermediate',
    tagline: 'Chat in easy, friendly English!',
    description: 'A cheerful American college student who loves movies and travel.',
    age: 21,
    schoolYear: 'University',
    occupation: 'Student',
    traits: const [CharacterTrait('friendly', 0.8)],
    interests: const [CharacterInterest(category: 'life', items: ['movies', 'travel'])],
    speechStyle: 'warm and casual',
    primaryColor: const Color(0xFF3E7BA1),
    secondaryColor: const Color(0xFFE6F0FF),
    hairStyle: '-', hairColor: '-', eyeColor: '-', outfit: '-', accessories: const [],
    selfReference: 'I',
    commonPhrases: const [],
    emotionalResponses: const {},
    imageUrl: '$_imageBasePath/emily$_imageExtension',
    imagePath: '$_imageBasePath/emily$_imageExtension',
    friendLanguage: 'en',
    omitSecondaryDisplayName: true,
  ),
```

Repeat with a second English friend and two Chinese friends (`friendLanguage: 'zh'`, Chinese names, e.g. `李娜`/`王伟`). Add `_characterTaglines` entries if referenced, or inline the tagline string as above.

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/data/character/characters_data_test.dart` → PASS. `flutter analyze` → clean.

- [ ] **Step 5: Commit**

```bash
git add lib/data/character/characters_data.dart test/data/character/characters_data_test.dart
git commit -m "feat(friends): add built-in English and Chinese friends"
```

---

## Task 11: Full verification & device install

**Files:** none (verification only).

- [ ] **Step 1: Analyze + full test suite**

Run: `flutter analyze` → "No issues found!"
Run: `flutter test` → all pass (baseline 46 + new tests).

- [ ] **Step 2: Run the app and smoke-test each axis**

Launch on the connected device or simulator. Verify:
- App language ko → ja → en → zh switches all visible UI.
- Create/select an English friend and a Chinese friend; send a message; reply comes back in that language.
- Open the expression sheet on a reply; full translation + notes render in the current app language; readings match the friend language (hiragana/romaja/pinyin; English may omit).
- Saved words land in the correct notebook segment.

- [ ] **Step 3: Release build + install to Coby**

```bash
flutter build ios --release
xcrun devicectl device install app --device A6DC9D73-C596-5DAD-A209-A6FCF6DC39C3 build/ios/iphoneos/Runner.app
```

- [ ] **Step 4: Final commit (if any doc/cleanup) + push**

```bash
git push origin paper-cartoon-redesign
```

---

## Self-Review Notes

- **Spec coverage:** A(Task 3,4) B(Task 6) C(Task 5) D(Task 7) E(Task 2,8) F(Task 9) G(Task 10) H(tests in each) — all covered.
- **Type consistency:** `friendLanguage` (String getter), `VocabularyMeaningPickMode.preferEnglishGloss`/`preferChineseGloss`, `ReadingSystem`, `normalizeLang`, `kSupportedLanguages` used consistently across tasks.
- **Reading required:** relaxed for `en` in both the analysis prompt and `_analysisNeedsRepair` (Task 6).
- **Backward compat:** legacy `koreanNationalPersona`/`tutorLocale` retained as derived; `toJson` writes both old and new keys.
