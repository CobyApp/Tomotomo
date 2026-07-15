import '../../domain/entities/character.dart';
import 'ai_prompts/prompt_japanese_character_korean_notes.dart';
import 'ai_prompts/prompt_japanese_immersion.dart';
import 'ai_prompts/prompt_korean_character_japanese_notes.dart';

String _learningNoteLanguageRule(String appUiLanguageCode) {
  final language = appUiLanguageCode.toLowerCase();
  if (language.startsWith('ja')) {
    return 'Write "learning_note" entirely in natural Japanese (no Korean).';
  }
  return 'Write "learning_note" entirely in natural Korean (no Japanese).';
}

/// Routes to the correct system instruction for [character] (built-in flags + custom record language).
///
/// [appUiLanguageCode] controls the language used for `learning_note`.
String buildCharacterSystemPrompt(
  Character character, {
  required String appUiLanguageCode,
}) {
  final traits = character.traits
      .map((t) => '${t.trait}(${t.weight})')
      .join(', ');
  final interests = character.interests
      .map((i) => '${i.category}: ${i.items.join(', ')}')
      .join('\n');
  final noteRule = _learningNoteLanguageRule(appUiLanguageCode);

  if (character.tutorLocale == 'ja') {
    return buildJapaneseImmersionPrompt(
      character,
      traits,
      interests,
      noteRule: noteRule,
      appUiLanguageCode: appUiLanguageCode,
    );
  }
  if (character.koreanNationalPersona) {
    return buildKoreanCharacterJapaneseNotesPrompt(
      character,
      traits,
      interests,
      noteRule: noteRule,
    );
  }
  return buildJapaneseCharacterKoreanNotesPrompt(
    character,
    traits,
    interests,
    noteRule: noteRule,
  );
}
