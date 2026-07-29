import 'package:aichat/data/on_device/on_device_ai_runtime.dart';
import 'package:aichat/data/repositories/litert_lm_ai_repository_impl.dart';
import 'package:aichat/domain/entities/character.dart';
import 'package:aichat/domain/entities/chat_message.dart';
import 'package:aichat/domain/repositories/chat_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Character _friend(String id, String language) => Character(
  id: id, name: id, level: 'intermediate', description: '',
  age: 0, schoolYear: '', occupation: '', traits: const [],
  interests: const [], speechStyle: '',
  primaryColor: const Color(0xFF000000),
  secondaryColor: const Color(0xFFFFFFFF),
  hairStyle: '', hairColor: '', eyeColor: '', outfit: '',
  accessories: const [], selfReference: '', commonPhrases: const [],
  emotionalResponses: const {}, imageUrl: '', imagePath: '',
  friendLanguage: language,
);

final class _Runtime implements OnDeviceAiRuntime {
  final prompts = <String>[];
  String reply = 'ok';

  @override
  Future<String> generateText({
    required String systemInstruction,
    required String prompt,
    double temperature = 0.2,
    int maxTokens = 4096,
  }) async {
    prompts.add(prompt);
    return '{"content":"$reply","full_translation":"t",'
        '"vocabulary":['
        '{"word":"w1","reading":"きょう","meaning_ko":"이 단어의 뜻을 충분히 길게 한국어로 설명하는 문장입니다."},'
        '{"word":"w2","reading":"きょう","meaning_ko":"이 단어의 뜻을 충분히 길게 한국어로 설명하는 문장입니다."}]}';
  }

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
}

final class _Chat implements ChatRepository {
  _Chat(this._stored);
  final Map<String, List<ChatMessage>> _stored;

  @override
  Future<List<ChatMessage>> getMessages(Character character) async =>
      _stored[character.id] ?? const [];

  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnsupportedError('${i.memberName}');
}

ChatMessage _msg(String role, String text) =>
    ChatMessage(content: text, role: role, timestamp: DateTime(2026));

void main() {
  test('a reply that lands while you are in another room stays in its own room',
      () async {
    // The transcript was appended AFTER the multi-second inference, to a single
    // shared list. Backing out of room A mid-generation and opening room B meant
    // A's turns were appended to B's history, so B was prompted with your
    // conversation with A.
    final runtime = _Runtime();
    final repo = LiteRtLmAiRepositoryImpl(runtime, chatRepository: _Chat({}));

    repo.initializeForCharacter(_friend('alice', 'ja'));
    final inFlight = repo.generateResponse('SECRET-TOLD-TO-ALICE');
    repo.initializeForCharacter(_friend('bob', 'ja')); // user opens room B
    await inFlight;

    runtime.prompts.clear();
    await repo.generateResponse('hello bob');

    expect(
      runtime.prompts.join('\n'),
      isNot(contains('SECRET-TOLD-TO-ALICE')),
      reason: "alice's conversation leaked into bob's prompt",
    );
  });

  test('a friend still remembers the exchange after you visit another room',
      () async {
    final runtime = _Runtime();
    final repo = LiteRtLmAiRepositoryImpl(runtime, chatRepository: _Chat({}));

    repo.initializeForCharacter(_friend('alice', 'ja'));
    await repo.generateResponse('REMEMBER-THIS');
    repo.initializeForCharacter(_friend('bob', 'ja'));
    await repo.generateResponse('hi');
    repo.initializeForCharacter(_friend('alice', 'ja')); // back to A

    runtime.prompts.clear();
    await repo.generateResponse('do you remember?');
    expect(
      runtime.prompts.join('\n'),
      contains('REMEMBER-THIS'),
      reason: 'the friend forgot the exchange you just had',
    );
  });

  test('recent dialogue is restored from storage on a fresh run', () async {
    // Nothing rebuilt the transcript from disk, so after every relaunch a friend
    // started from "RECENT DIALOGUE (none)" even with a full history on screen.
    final runtime = _Runtime();
    final repo = LiteRtLmAiRepositoryImpl(
      runtime,
      chatRepository: _Chat({
        'alice': [_msg('user', 'STORED-EARLIER'), _msg('assistant', 'sure')],
      }),
    );

    repo.initializeForCharacter(_friend('alice', 'ja'));
    await Future<void>.delayed(Duration.zero); // let the restore settle
    await repo.generateResponse('and then?');

    expect(
      runtime.prompts.join('\n'),
      contains('STORED-EARLIER'),
      reason: 'stored dialogue was not restored into the prompt',
    );
  });

  test('resetChat clears only the friend it was called for', () async {
    final runtime = _Runtime();
    final repo = LiteRtLmAiRepositoryImpl(runtime, chatRepository: _Chat({}));

    repo.initializeForCharacter(_friend('alice', 'ja'));
    await repo.generateResponse('ALICE-TURN');
    repo.initializeForCharacter(_friend('bob', 'ja'));
    await repo.generateResponse('BOB-TURN');
    repo.resetChat(); // clears bob

    repo.initializeForCharacter(_friend('alice', 'ja'));
    runtime.prompts.clear();
    await repo.generateResponse('still there?');
    expect(runtime.prompts.join('\n'), contains('ALICE-TURN'));
  });
}
