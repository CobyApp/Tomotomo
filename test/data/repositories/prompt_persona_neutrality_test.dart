import 'package:aichat/domain/entities/character.dart';
import 'package:aichat/domain/entities/character_record.dart';
import 'package:flutter_test/flutter_test.dart';

/// A custom friend built from a stored record used to carry a hardcoded Role of
/// '한국어 튜터 · 말풍선 한국어, 단어 뜻 일본어' (or the Japanese mirror of it).
/// That line goes into the system prompt as "Role:", where it contradicted the
/// reply and explanation languages the same prompt states below — and was flatly
/// wrong for an English or Chinese friend. A small on-device model given two
/// conflicting language instructions is exactly how the wrong language leaks out.
void main() {
  CharacterRecord record(String language) => CharacterRecord.draft(
    name: 'Sam',
    language: language,
    level: 'intermediate',
  );

  test('no persona field dictates a script for any friend language', () {
    for (final language in const ['ko', 'ja', 'en', 'zh']) {
      final character = Character.fromRecord(record(language));
      final persona = [
        character.occupation,
        character.speechStyle,
        ...character.traits.map((t) => t.trait),
        ...character.interests.expand((i) => i.items),
      ].join(' ');

      for (final claim in const [
        '한국어',
        '일본어',
        '말풍선',
        '단어 뜻',
        'Korean',
        'Japanese',
        'Chinese',
        'English',
      ]) {
        expect(
          persona,
          isNot(contains(claim)),
          reason:
              'a $language friend\'s persona asserts "$claim", which can '
              'contradict the prompt\'s own language rules',
        );
      }
    }
  });

  test('the friend still speaks the record language', () {
    for (final language in const ['ko', 'ja', 'en', 'zh']) {
      expect(Character.fromRecord(record(language)).friendLanguage, language);
    }
  });

  test('the single name reaches the primary display line in every language', () {
    for (final language in const ['ko', 'ja', 'en', 'zh']) {
      final character = Character.fromRecord(record(language));
      expect(character.displayNamePrimary, 'Sam');
      expect(character.displayNameSecondary, isEmpty);
    }
  });
}
