import 'package:aichat/data/on_device/on_device_ai_runtime.dart';
import 'package:aichat/data/repositories/litert_lm_ai_repository_impl.dart';
import 'package:aichat/domain/entities/character.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeRuntime implements OnDeviceAiRuntime {
  String response =
      '{"content":"こんにちは！","full_translation":"안녕하세요!",'
      '"learning_note":"인사 표현",'
      '"vocabulary":[{"word":"こんにちは","meaning_ko":"안녕하세요"}]}';
  String? lastSystemInstruction;
  String? lastPrompt;
  int generationCount = 0;

  @override
  String? get activeBackend => 'cpu';
  @override
  void cancelInstall() {}
  @override
  Future<void> deleteModel() async {}
  @override
  Future<void> dispose() async {}
  @override
  Future<void> initialize() async {}
  @override
  Future<void> installModel({
    required void Function(double progress) onProgress,
    void Function()? onVerifying,
  }) async {}
  @override
  Future<bool> isModelInstalled() async => true;

  @override
  Future<String> generateText({
    required String systemInstruction,
    required String prompt,
    double temperature = 0.2,
    int maxTokens = 4096,
  }) async {
    generationCount++;
    lastSystemInstruction = systemInstruction;
    lastPrompt = prompt;
    if (systemInstruction.contains('language-learning annotator') &&
        generationCount == 2) {
      return '{"content":"잘못 바뀐 원문","full_translation":"오늘은 무엇을 할 거야?",'
          '"learning_note":"상대방의 오늘 계획을 자연스럽게 묻는 표현이다.",'
          '"vocabulary":['
          '{"word":"今日","reading":"きょう","meaning_ko":"말하는 당일을 뜻하며 일상적인 계획을 물을 때 자주 쓴다."},'
          '{"word":"何をする","reading":"なにをする","meaning_ko":"무엇을 할지 묻는 표현으로 상대방의 계획이나 행동을 확인할 때 쓴다."}]}';
    }
    return response;
  }
}

const _character = Character(
  id: 'yuna',
  name: '유나',
  nameJp: 'ゆうな',
  nameKanji: '優奈',
  level: '일본어',
  description: '친구 같은 튜터',
  age: 20,
  schoolYear: '',
  occupation: '튜터',
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
  test('generates and parses tutor JSON through the local runtime', () async {
    final runtime = _FakeRuntime();
    final repository = LiteRtLmAiRepositoryImpl(runtime)
      ..initializeForCharacter(_character, appUiLanguageCode: 'ko');

    final message = await repository.generateResponse('안녕');

    expect(message.content, 'こんにちは！');
    // The reply now bundles the study-sheet analysis in one generation so the
    // expression sheet opens instantly.
    expect(message.lineTranslation, '안녕하세요!');
    expect(message.explanation, '인사 표현');
    expect(message.vocabulary, isNotNull);
    expect(message.vocabulary!, isNotEmpty);
    expect(runtime.lastPrompt, contains('안녕'));
    expect(runtime.lastSystemInstruction, isNotEmpty);
    expect(runtime.lastSystemInstruction, contains('learning_note'));
    expect(runtime.lastSystemInstruction, contains('next reply'));
  });

  test('expression analysis is isolated from chat continuation', () async {
    final runtime = _FakeRuntime();
    final repository = LiteRtLmAiRepositoryImpl(runtime);

    final analysis = await repository.generateExpressionAnalysis(
      '今日は何をする？',
      _character,
      appUiLanguageCode: 'ko',
    );

    expect(runtime.lastPrompt, contains('今日は何をする？'));
    expect(runtime.lastSystemInstruction, contains('full_translation'));
    expect(runtime.lastSystemInstruction, contains('in Korean'));
    expect(analysis.content, '今日は何をする？');
    expect(analysis.lineTranslation, '오늘은 무엇을 할 거야?');
    expect(analysis.vocabulary, hasLength(2));
    expect(analysis.vocabulary!.first.reading, 'きょう');
    expect(runtime.generationCount, 2);
  });
}
