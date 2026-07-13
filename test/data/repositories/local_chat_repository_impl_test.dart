import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:aichat/data/repositories/local_chat_repository_impl.dart';
import 'package:aichat/domain/entities/character.dart';
import 'package:aichat/domain/entities/chat_message.dart';

Character _testCharacter({String id = 'char-1', String name = 'さくら'}) {
  return Character(
    id: id,
    name: name,
    nameJp: name,
    nameKanji: name,
    level: '일본어',
    description: '',
    age: 0,
    schoolYear: '',
    occupation: '',
    traits: const [],
    interests: const [],
    speechStyle: '',
    primaryColor: const Color(0xFF6A3EA1),
    secondaryColor: const Color(0xFFF0E6FF),
    hairStyle: '-',
    hairColor: '-',
    eyeColor: '-',
    outfit: '-',
    accessories: const [],
    selfReference: name,
    commonPhrases: const [],
    emotionalResponses: const {},
    imageUrl: 'assets/img.png',
    imagePath: 'assets/img.png',
  );
}

ChatMessage _msg(String content, String role) => ChatMessage(
      content: content,
      role: role,
      timestamp: DateTime.now(),
    );

void main() {
  late Box box;
  late LocalChatRepositoryImpl repo;

  setUp(() async {
    Hive.init('./.dart_tool/hive_test_chats');
    box = await Hive.openBox('chats');
    repo = LocalChatRepositoryImpl(box);
  });
  tearDown(() async => Hive.deleteFromDisk());

  test('saveMessage / getMessages round-trip in order', () async {
    final c = _testCharacter();
    final id1 = await repo.saveMessage(c, _msg('こんにちは', 'user'));
    final id2 = await repo.saveMessage(c, _msg('はい！', 'assistant'));
    expect(id1, isNotNull);
    expect(id2, isNotNull);

    final msgs = await repo.getMessages(c);
    expect(msgs.length, 2);
    expect(msgs[0].content, 'こんにちは');
    expect(msgs[0].role, 'user');
    expect(msgs[1].content, 'はい！');
    expect(msgs[0].serverId, id1);
  });

  test('getRecentRooms lists rooms with history, newest first', () async {
    final a = _testCharacter(id: 'char-a', name: 'A');
    final b = _testCharacter(id: 'char-b', name: 'B');
    await repo.saveMessage(a, _msg('first', 'user'));
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await repo.saveMessage(b, _msg('latest', 'user'));

    final rooms = await repo.getRecentRooms();
    expect(rooms.length, 2);
    expect(rooms.first.roomId, 'char-b');
    expect(rooms.first.lastMessageContent, 'latest');
    expect(rooms.first.title, 'B');
    expect(rooms.first.avatarAssetPath, 'assets/img.png');
  });

  test('deleteRoom / clearMessages remove history', () async {
    final c = _testCharacter();
    await repo.saveMessage(c, _msg('hi', 'user'));
    expect((await repo.getMessages(c)).length, 1);

    await repo.deleteRoom(c.id);
    expect((await repo.getMessages(c)).isEmpty, isTrue);
    expect((await repo.getRecentRooms()).isEmpty, isTrue);

    await repo.saveMessage(c, _msg('again', 'user'));
    await repo.clearMessages(c);
    expect((await repo.getMessages(c)).isEmpty, isTrue);
  });
}
