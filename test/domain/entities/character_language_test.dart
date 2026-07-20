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
