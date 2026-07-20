# Four-Language Support (app UI × friend language)

**Date:** 2026-07-20
**Status:** Approved (design), pending implementation plan

## Goal

Support four languages on two independent axes:

- **App UI language** (`appLanguage`): `ko` | `ja` | `en` | `zh` (Simplified 简体)
- **Friend language** (`friendLanguage`): `ko` | `ja` | `en` | `zh`

Every prompt and UI surface must behave consistently across all 4×4 = 16
combinations. The two axes are independent: e.g. a Korean-UI learner may talk to
an English-speaking friend.

## Core principle — no combination explosion

Fix, per element, which axis its language comes from:

| Element | Language source |
|---|---|
| Friend chat reply | **friend language** |
| App UI strings | **app language** |
| Expression analysis (full translation, learning note, vocab meaning/gloss) | **app language** |
| Word reading (pronunciation aid) | **friend language, fixed system** |

Reading systems by friend language:

- `ja` → Hiragana furigana (existing behavior)
- `ko` → Latin romanization (Revised Romanization of Korean)
- `zh` → Pinyin with tone marks
- `en` → IPA (optional; may be omitted since Latin is already readable)

Reading is **required** for `ja`/`ko`/`zh` and **optional** for `en`
(relaxes `_analysisNeedsRepair` accordingly).

Canonical language code set: `{'ko','ja','en','zh'}`. Introduce a small helper
for validation/fallback; `zh` means Simplified throughout.

## Scope by area

### A. Language model (backward compatible)

- `Character`: add `friendLanguage` (`ko`|`ja`|`en`|`zh`). Keep
  `koreanNationalPersona` and `tutorLocale` as **getters derived from
  `friendLanguage`** so existing consumers (fonts, name display, etc.) keep
  working untouched. New/rewritten language logic reads `friendLanguage`
  directly.
- `Character.fromJson`: read `friendLanguage` if present; otherwise derive from
  the old fields (`tutorLocale == 'ja'` → `ja`; `koreanNationalPersona` → `ko`;
  else `ko`). `toJson` writes `friendLanguage`.
- `CharacterRecord.language`: allow all four values; default preserved.
  `fromJson` migrates missing values from prior fields.
- `defaultNotebookLangForVocabSave`: derive 4-way from `friendLanguage`.

### B. Prompts (`ai_system_prompt_builder.dart`)

- `buildChatReplySystemPrompt`: reply language, forbidden-script guidance, and
  `_levelGuidance` become 4-way on `friendLanguage`. Level registers per
  language:
  - beginner: simple/casual friendly (반말 / タメ口 / casual English / 简单口语)
  - intermediate: natural everyday + light trendy usage (MZ / 若者言葉 / slang / 网络流行语)
  - advanced: native idioms/nuance
  - business: polite/professional register (존댓말 / 敬語 / professional English / 商务敬语 您)
- `buildExpressionAnalysisSystemPrompt`: explanation language = app language
  (4-way), `meaningKey = meaning_<appLang>`, `readingRule` per friend language,
  `sourceLanguage` = friend language.

### C. Vocabulary meaning gloss

- Replace fixed `VocabularyMeaningPickMode` (3 modes) with app-language-driven
  selection: prefer `meaning_<appLang>` with sensible fallbacks.
- Add `meaning_en` and `meaning_zh` throughout: `ai_response_parser.dart`
  normalization + fallback key lists, and `chat_message.dart` pick logic.

### D. App UI strings (`app_strings.dart`)

- Add complete `_en` and `_zh` maps (~222 keys each), authored in this work.
- `of()` switches across four maps with `_ko` (and `_en`) as fallback for any
  missing key.

### E. Locale plumbing + UI

- `LocaleNotifier` and `FriendLanguageNotifier`: accept all four codes
  (drop the `ko`/`ja`-only guards).
- `language_settings_screen.dart`: four app-language tiles.
- `onboarding_screen.dart`: four app-language options, four friend-language
  options; nationality gains `en`/`zh` alongside existing + `other`.
- Character editor (`custom_character_editor_body.dart`): friend-language
  selector with four choices.

### F. Word book

- `word_book_screen.dart` + `notebook_study_screen.dart`: support four notebook
  segments (`ko`/`ja`/`en`/`zh`), showing only segments that have entries;
  per-language font selection.

### G. Built-in friends

- `characters_data.dart`: add ~2 English and ~2 Chinese built-in friends with
  appropriate `friendLanguage`, names, and personas.

### H. Tests

- Prompt builder: reply/analysis prompts for all four friend/app languages.
- Parser: `meaning_en` / `meaning_zh` selection and fallbacks.
- `Character` migration: old records without `friendLanguage` map correctly.
- `AppStrings.of()`: fallback to `_ko`/`_en` for missing keys.

## Non-goals (YAGNI)

- Traditional Chinese (zh-Hant) — Simplified only.
- App-language-adaptive readings (e.g. Katakana for Korean words for JP users) —
  readings are fixed per friend language.
- Auto-translation of user-authored persona text.

## Migration / compatibility

- Existing profiles (`appLanguage` `ko`/`ja`) unchanged.
- Existing saved custom characters migrate deterministically to `friendLanguage`
  from their old fields; no data loss.
- Existing word-book entries keep their `notebookLang`; new segments appear only
  when populated.
