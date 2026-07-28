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
  Future<void> resetDownloadState() async {}
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

/// Returns a study sheet in the WRONG language (Japanese) on the first call,
/// then a correct Korean study sheet on the repair pass.
final class _WrongStudySheetLangRuntime implements OnDeviceAiRuntime {
  int generationCount = 0;

  @override
  String? get activeBackend => 'cpu';
  @override
  void cancelInstall() {}
  @override
  Future<void> deleteModel() async {}
  @override
  Future<void> resetDownloadState() async {}
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
    if (generationCount == 1) {
      // Reply bundles a Japanese study sheet — wrong for a Korean learner.
      return '{"content":"こんにちは！","full_translation":"日本語のあいさつの言葉です。",'
          '"vocabulary":[{"word":"こんにちは","reading":"こんにちは",'
          '"meaning_ja":"人に会ったときに使うあいさつの言葉。"}]}';
    }
    // Repair (expression-analysis) pass returns a proper Korean study sheet.
    return '{"content":"こんにちは！","full_translation":"안녕하세요!",'
        '"learning_note":"낮에 사람을 만났을 때 쓰는 대표적인 인사 표현이다.",'
        '"vocabulary":['
        '{"word":"こんにちは","reading":"こんにちは","meaning_ko":"낮 시간대에 사람을 만났을 때 하는 대표적인 인사말이다."},'
        '{"word":"！","reading":"！","meaning_ko":"밝고 친근한 어조를 나타내는 느낌표로 자주 함께 쓴다."}]}';
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
    // The reply bundles the study sheet (translation + vocabulary) in one
    // generation so the expression sheet opens instantly. No short explanation.
    expect(message.lineTranslation, '안녕하세요!');
    expect(message.vocabulary, isNotNull);
    expect(message.vocabulary!, isNotEmpty);
    expect(runtime.lastPrompt, contains('안녕'));
    expect(runtime.lastSystemInstruction, isNotEmpty);
    expect(runtime.lastSystemInstruction, contains('full_translation'));
    expect(runtime.lastSystemInstruction, contains('vocabulary'));
    expect(runtime.lastSystemInstruction, isNot(contains('learning_note')));
    expect(runtime.lastSystemInstruction, contains('next reply'));
    // The study sheet must be pinned to the learner's language (Korean), not
    // the friend's language (Japanese): explicit rule + matching meaning key.
    expect(runtime.lastSystemInstruction, contains('Korean'));
    expect(runtime.lastSystemInstruction, contains('NEVER in Japanese'));
    expect(runtime.lastSystemInstruction, contains('meaning_ko'));
    // A single generation — a Korean study sheet needs no repair pass.
    expect(runtime.generationCount, 1);
  });

  test(
    'repairs a study sheet returned in the friend language, not the learner\'s',
    () async {
      final runtime = _WrongStudySheetLangRuntime();
      final repository = LiteRtLmAiRepositoryImpl(runtime)
        ..initializeForCharacter(_character, appUiLanguageCode: 'ko');

      final message = await repository.generateResponse('안녕');

      // The reply content is untouched (still Japanese)...
      expect(message.content, 'こんにちは！');
      // ...but the study sheet is repaired into Korean for the learner.
      expect(message.lineTranslation, '안녕하세요!');
      expect(message.vocabulary, isNotNull);
      expect(message.vocabulary!.first.meaning, contains('인사'));
      // First reply generation + one repair annotation pass.
      expect(runtime.generationCount, 2);
    },
  );

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
