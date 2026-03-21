import '../../domain/entities/character.dart';
import 'gemini_prompts/prompt_japanese_character_korean_notes.dart';
import 'gemini_prompts/prompt_japanese_immersion.dart';
import 'gemini_prompts/prompt_korean_character_japanese_notes.dart';

/// Routes to the correct system instruction for [character] (built-in flags + custom record language).
String buildGeminiSystemPrompt(Character character) {
  final traits =
      character.traits.map((t) => '${t.trait}(${t.weight})').join(', ');
  final interests = character.interests
      .map((i) => '${i.category}: ${i.items.join(', ')}')
      .join('\n');

  if (character.tutorLocale == 'ja') {
    return buildJapaneseImmersionPrompt(character, traits, interests);
  }
  if (character.koreanNationalPersona) {
    return buildKoreanCharacterJapaneseNotesPrompt(character, traits, interests);
  }
  return buildJapaneseCharacterKoreanNotesPrompt(character, traits, interests);
}
