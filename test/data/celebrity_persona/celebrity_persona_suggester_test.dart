import 'package:aichat/data/celebrity_persona/celebrity_persona_suggester.dart';
import 'package:aichat/data/on_device/on_device_ai_runtime.dart';
import 'package:flutter_test/flutter_test.dart';

final class _TokenLimitedRuntime implements OnDeviceAiRuntime {
  final prompts = <String>[];

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
    prompts.add(prompt);
    if (prompts.length == 1) {
      throw Exception(
        'exceeding the maxumun number of tokens allowed: 8239 >= 4096',
      );
    }
    return '{"name":"코비","language":"ko",'
        '"bio":"음악을 좋아하는 튜터",'
        '"tagline":"음악으로 배우는 한국어",'
        '"speech_style":"친근한 존댓말",'
        '"profile_image_url":null}';
  }
}

void main() {
  test('retries token-limit failures with a smaller profile prompt', () async {
    final runtime = _TokenLimitedRuntime();
    final suggester = CelebrityPersonaSuggester(runtime);
    final rawText = List.filled(
      500,
      '서로 다른 게시물 번호와 한국어 학습 이야기 🎵',
    ).asMap().entries.map((e) => '${e.key}: ${e.value}').join('\n');

    final result = await suggester.suggestFromProfileText(
      rawText,
      targetLanguage: 'ko',
    );

    expect(result.name, '코비');
    expect(runtime.prompts, hasLength(2));
    expect(
      runtime.prompts.last.runes.length,
      lessThan(runtime.prompts.first.runes.length),
    );
    expect(runtime.prompts.last.runes.length, lessThan(1400));
  });
}
