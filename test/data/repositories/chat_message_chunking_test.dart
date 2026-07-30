import 'dart:io';

import 'package:aichat/data/character/characters_data.dart';
import 'package:aichat/data/repositories/local_chat_repository_impl.dart';
import 'package:aichat/domain/entities/chat_message.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

/// A room used to be one Hive value holding every message, and Hive re-serializes
/// a whole value on put, so saving one message cost more the longer the
/// conversation got — measured at 113 KB written per message at 500 messages and
/// 897 KB at 4,000, with the box file reaching 39 MB for 400 KB of text. Recent
/// messages now live in a bounded tail and older ones in append-only chunks.
void main() {
  late Directory dir;
  late Box box;
  late LocalChatRepositoryImpl repo;
  final who = characters.first;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('chat_chunk');
    Hive.init(dir.path);
    box = await Hive.openBox('chats_chunk_test');
    await box.clear();
    repo = LocalChatRepositoryImpl(box);
  });
  tearDown(() async {
    await Hive.deleteFromDisk();
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  ChatMessage msg(int i) => ChatMessage(
    content: 'message $i',
    role: i.isEven ? 'user' : 'assistant',
    timestamp: DateTime(2026).add(Duration(minutes: i)),
  );

  Future<void> send(int count, {int from = 0}) async {
    for (var i = from; i < from + count; i++) {
      await repo.saveMessage(who, msg(i));
    }
  }

  test('every message comes back, in order, across chunks and the tail',
      () async {
    const total = kChatTailLimit * 3;
    await send(total);

    final all = await repo.getMessages(who);
    expect(all.length, total);
    expect(all.map((m) => m.content).toList(),
        List.generate(total, (i) => 'message $i'));
    expect(all.first.role, 'user');
    expect(all.map((m) => m.timestamp).toList(), isNot(contains(null)));
  });

  test('the entry rewritten on every save stays bounded', () async {
    await send(kChatTailLimit * 4);
    final entry = box.get(who.id) as Map;
    expect((entry['tail'] as List).length, lessThanOrEqualTo(kChatTailLimit));
    expect(entry.containsKey('messages'), isFalse);
    expect((entry['archivedChunks'] as num).toInt(), greaterThan(0));
  });

  group('migrating a room written by the old version', () {
    /// Exactly the shape the previous implementation wrote.
    Future<List<String>> seedLegacy(int count) async {
      final contents = <String>[];
      final messages = <Map<String, dynamic>>[];
      for (var i = 0; i < count; i++) {
        final m = msg(i).copyWith(serverId: 'id$i');
        messages.add(m.toJson());
        contents.add(m.content);
      }
      await box.put(who.id, {
        'messages': messages,
        'title': 'Old title',
        'avatarNetworkUrl': null,
        'avatarAssetPath': 'assets/a.png',
      });
      return contents;
    }

    test('a long history is preserved exactly', () async {
      final expected = await seedLegacy(1000);

      final all = await repo.getMessages(who);
      expect(all.map((m) => m.content).toList(), expected);

      final entry = box.get(who.id) as Map;
      expect(entry.containsKey('messages'), isFalse,
          reason: 'the old list was left behind, so the cost stayed');
      expect((entry['tail'] as List).length, lessThanOrEqualTo(kChatTailLimit));
      expect(entry['title'], 'Old title', reason: 'metadata was lost');
      expect(entry['avatarAssetPath'], 'assets/a.png');
    });

    test('a short history needs no chunks and is preserved', () async {
      final expected = await seedLegacy(12);
      expect((await repo.getMessages(who)).map((m) => m.content).toList(),
          expected);
      expect((box.get(who.id) as Map)['archivedChunks'], 0);
    });

    test('it happens once, not on every read', () async {
      await seedLegacy(500);
      final first = await repo.getMessages(who);
      final chunksAfterFirst = (box.get(who.id) as Map)['archivedChunks'];
      final second = await repo.getMessages(who);

      expect(second.map((m) => m.content), first.map((m) => m.content));
      expect((box.get(who.id) as Map)['archivedChunks'], chunksAfterFirst);
    });

    test('saving into an unmigrated room keeps the old messages', () async {
      final expected = await seedLegacy(400);
      await repo.saveMessage(who, msg(999));

      final all = await repo.getMessages(who);
      expect(all.length, expected.length + 1);
      expect(all.map((m) => m.content).take(expected.length).toList(), expected);
      expect(all.last.content, 'message 999');
    });

    test('the rooms list reads either layout', () async {
      await seedLegacy(50);
      final rooms = await repo.getRecentRooms();
      expect(rooms.single.lastMessageContent, 'message 49');
      expect(rooms.single.title, 'Old title');
    });
  });

  test('archive chunks are not listed as rooms', () async {
    await send(kChatTailLimit * 3);
    final rooms = await repo.getRecentRooms();
    expect(rooms.length, 1, reason: 'chunk keys leaked into the rooms list');
    expect(rooms.single.roomId, who.id);
    expect(box.keys.where((k) => LocalChatRepositoryImpl.isArchiveKey('$k')),
        isNotEmpty, reason: 'the test never archived anything');
  });

  test('deleting a room removes its chunks too', () async {
    await send(kChatTailLimit * 3);
    expect(box.keys.length, greaterThan(1));

    await repo.deleteRoom(who.id);

    expect(box.keys, isEmpty, reason: 'orphaned chunks were left behind');
    expect(await repo.getMessages(who), isEmpty);
    expect(await repo.roomExists(who.id), isFalse);
  });

  test('a room recreated with the same id does not inherit the old history',
      () async {
    await send(kChatTailLimit * 3);
    await repo.deleteRoom(who.id);
    await repo.saveMessage(who, msg(777));

    final all = await repo.getMessages(who);
    expect(all.single.content, 'message 777');
  });

  test('clearing messages leaves nothing behind either', () async {
    await send(kChatTailLimit * 2 + 10);
    await repo.clearMessages(who);
    expect(box.keys, isEmpty);
  });

  test('the per-message write cost stops growing with the room', () async {
    int fileBytes() {
      final f = File('${dir.path}/chats_chunk_test.hive');
      return f.existsSync() ? f.lengthSync() : 0;
    }

    Future<double> kbPerMessageAt(int size) async {
      while ((await repo.getMessages(who)).length < size) {
        await repo.saveMessage(who, msg(999000 + box.length));
      }
      final before = fileBytes();
      for (var k = 0; k < 10; k++) {
        await repo.saveMessage(who, msg(500000 + k + size));
      }
      return (fileBytes() - before) / 10 / 1024;
    }

    final small = await kbPerMessageAt(400);
    final large = await kbPerMessageAt(3000);

    // Was strictly proportional: ~113 KB at 500 messages, ~897 KB at 4,000.
    expect(large, lessThan(small * 2),
        reason: 'still grows with the room: $small KB -> $large KB per message');
    expect(large, lessThan(100),
        reason: '$large KB written for one message');
  }, timeout: const Timeout(Duration(minutes: 3)));
}
