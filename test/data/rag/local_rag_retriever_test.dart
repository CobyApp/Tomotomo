import 'package:aichat/data/rag/local_rag_retriever.dart';
import 'package:aichat/domain/entities/character.dart';
import 'package:aichat/domain/entities/chat_message.dart';
import 'package:aichat/domain/entities/chat_room_summary.dart';
import 'package:aichat/domain/entities/saved_expression.dart';
import 'package:aichat/domain/repositories/chat_repository.dart';
import 'package:aichat/domain/repositories/saved_expression_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _character = Character(
  id: 'yuna',
  name: '유나',
  nameJp: 'ゆうな',
  nameKanji: '優奈',
  level: 'intermediate',
  description: '친구 같은 친구',
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
  // Japanese-speaking friend persona; was implicit via legacy field
  // defaults, now declared explicitly since the default friendLanguage
  // fallback (nothing specified) is 'ko', matching normalizeLang(null).
  friendLanguage: 'ja',
);

final class _FakeWordbook implements SavedExpressionRepository {
  _FakeWordbook(this.rows);
  final List<SavedExpression> rows;

  @override
  Future<List<SavedExpression>> listForCurrentUser({
    required String notebookLang,
  }) async => rows.where((r) => r.notebookLang == notebookLang).toList();

  @override
  Future<void> add(SavedExpressionDraft draft) async {}
  @override
  Future<void> delete(String id) async {}
}

final class _FakeChat implements ChatRepository {
  _FakeChat(this.messages);
  final List<ChatMessage> messages;

  @override
  Future<List<ChatMessage>> getMessages(Character character) async => messages;
  @override
  Future<String?> saveMessage(Character character, ChatMessage message) async =>
      null;
  @override
  Future<void> clearMessages(Character character) async {}
  @override
  Future<List<ChatRoomSummary>> getRecentRooms() async => const [];
  @override
  Future<void> deleteRoom(String roomId) async {}
}

SavedExpression _word(String content, String translation, {String lang = 'ja'}) {
  return SavedExpression(
    id: content,
    userId: 'me',
    source: 'chat',
    notebookLang: lang,
    content: content,
    translation: translation,
    createdAt: DateTime(2026, 1, 1),
  );
}

ChatMessage _msg(String role, String content) =>
    ChatMessage(content: content, role: role, timestamp: DateTime(2026, 1, 1));

void main() {
  test('returns empty when nothing relevant', () async {
    final r = LocalRagRetriever(
      _FakeWordbook([_word('りんご', '사과')]),
      _FakeChat([]),
    );
    final out = await r.retrieveContext(
      character: _character,
      userMessage: '天気はどう？',
    );
    expect(out, isEmpty);
  });

  test('surfaces saved vocabulary that overlaps the message', () async {
    final r = LocalRagRetriever(
      _FakeWordbook([
        _word('天気', '날씨'),
        _word('りんご', '사과'),
      ]),
      _FakeChat([]),
    );
    final out = await r.retrieveContext(
      character: _character,
      userMessage: '今日の天気はどう？',
    );
    expect(out, contains('天気'));
    expect(out, contains('날씨'));
    expect(out, isNot(contains('りんご')));
  });

  test('recalls relevant older conversation beyond the live window', () async {
    // 6 recent filler turns are excluded; the older relevant turn is recalled.
    final msgs = <ChatMessage>[
      _msg('user', '私は北海道の旅行が大好きなんだ'),
      for (var i = 0; i < 6; i++) _msg('assistant', 'そうなんだ$i'),
    ];
    final r = LocalRagRetriever(_FakeWordbook([]), _FakeChat(msgs));
    final out = await r.retrieveContext(
      character: _character,
      userMessage: '北海道の話をもっと聞かせて',
    );
    expect(out, contains('北海道'));
  });
}
