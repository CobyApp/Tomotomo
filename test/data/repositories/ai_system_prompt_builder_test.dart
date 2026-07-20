import 'package:aichat/data/repositories/ai_system_prompt_builder.dart';
import 'package:aichat/domain/entities/character.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _character = Character(
  id: 'yuna',
  name: '유나',
  nameJp: 'ゆうな',
  nameKanji: '優奈',
  level: 'intermediate',
  description: '친구',
  age: 20,
  schoolYear: '',
  occupation: '친구',
  traits: [],
  interests: [],
  speechStyle: '친근하게',
  primaryColor: Color(0xFF000000),
  secondaryColor: Color(0xFFFFFFFF),
  hairStyle: '',
  hairColor: '',
  eyeColor: '',
  outfit: '',
  accessories: [],
  selfReference: '私',
  commonPhrases: [],
  emotionalResponses: {},
  imageUrl: '',
  imagePath: '',
);

void main() {
  test('reply prompt includes the learner name when provided', () {
    final prompt = buildChatReplySystemPrompt(_character, userName: '도영');
    expect(prompt, contains('도영'));
    expect(prompt, contains("ABOUT THE PERSON YOU'RE TALKING WITH"));
  });

  test('reply prompt omits the name section when unknown', () {
    expect(
      buildChatReplySystemPrompt(_character),
      isNot(contains("ABOUT THE PERSON YOU'RE TALKING WITH")),
    );
    expect(
      buildChatReplySystemPrompt(_character, userName: '   '),
      isNot(contains("ABOUT THE PERSON YOU'RE TALKING WITH")),
    );
  });

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
}

Character _friend(String friendLanguage) => Character(
      id: 'x', name: 'n', nameJp: 'n', nameKanji: 'n', level: 'intermediate',
      description: '', age: 0, schoolYear: '', occupation: '',
      traits: const [], interests: const [], speechStyle: '',
      primaryColor: const Color(0xFF000000), secondaryColor: const Color(0xFFFFFFFF),
      hairStyle: '', hairColor: '', eyeColor: '', outfit: '', accessories: const [],
      selfReference: '', commonPhrases: const [], emotionalResponses: const {},
      imageUrl: '', imagePath: '', friendLanguage: friendLanguage);
