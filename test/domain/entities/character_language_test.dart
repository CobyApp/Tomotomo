import 'package:aichat/domain/entities/character.dart';
import 'package:aichat/domain/entities/character_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Character _base({required String friendLanguage}) => Character(
  id: 'x', name: 'n', level: 'intermediate',
  description: '', age: 0, schoolYear: '', occupation: '',
  traits: const [], interests: const [], speechStyle: '',
  primaryColor: const Color(0xFF000000), secondaryColor: const Color(0xFFFFFFFF),
  hairStyle: '', hairColor: '', eyeColor: '', outfit: '', accessories: const [],
  selfReference: '', commonPhrases: const [], emotionalResponses: const {},
  imageUrl: '', imagePath: '',
  friendLanguage: friendLanguage,
);

void main() {
  // The legacy-migration cases that used to live here are gone with the fields
  // they migrated from (koreanNationalPersona, tutorLocale, the nameJp/nameKanji
  // pair) and with Character.fromJson — Character is never deserialized, every
  // construction passes friendLanguage, and the compiler now requires it.
  test('friendLanguage is carried through, for all four languages', () {
    for (final lang in const ['ko', 'ja', 'en', 'zh']) {
      expect(_base(friendLanguage: lang).friendLanguage, lang);
      expect(_base(friendLanguage: lang).defaultNotebookLangForVocabSave, lang);
    }
  });

  test('a region tag or odd casing still resolves', () {
    expect(_base(friendLanguage: 'zh-Hans').friendLanguage, 'zh');
    expect(_base(friendLanguage: 'EN').friendLanguage, 'en');
  });

  test('fromRecord maps record.language to friendLanguage', () {
    for (final lang in const ['ko', 'ja', 'en', 'zh']) {
      final r = CharacterRecord.draft(name: 'A', language: lang);
      expect(Character.fromRecord(r).friendLanguage, lang);
    }
  });
}
