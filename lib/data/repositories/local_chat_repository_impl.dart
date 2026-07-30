import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';

import '../../domain/entities/character.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_room_summary.dart';
import '../../domain/repositories/chat_repository.dart';

/// How many recent messages stay in the room entry. Only these are re-serialized
/// when a message is saved, so this — not the room's size — is what one save
/// costs.
const int kChatTailLimit = 300;

/// How many messages move into an archive chunk once the tail passes the limit.
/// Chunks are written once and never rewritten.
const int kChatChunkSize = 150;

/// Local chat persistence in the `chats` box.
///
/// The room entry (keyed by [Character.id]) holds display metadata for the
/// recent-rooms list plus a bounded tail of recent messages. Older messages live
/// in append-only chunks under `arch/<roomId>/<n>`.
///
/// It used to keep every message in the room entry, and Hive re-serializes a
/// whole value on every put, so saving one message cost more the longer the
/// conversation got: measured at 113 KB written per message at 500 messages,
/// 449 KB at 2,000 and 897 KB at 4,000, with the box file reaching 39 MB for
/// 400 KB of actual text. Ordinary daily use made every reply slower and wrote
/// more, with no ceiling.
class LocalChatRepositoryImpl implements ChatRepository {
  LocalChatRepositoryImpl(this._box);
  final Box _box;

  static const String _archivePrefix = 'arch/';

  /// True for the archive-chunk keys that share this box with room entries.
  /// [getRecentRooms] walks every key, so chunks must not read as rooms.
  static bool isArchiveKey(String key) => key.startsWith(_archivePrefix);

  String _chunkKey(String roomId, int index) => '$_archivePrefix$roomId/$index';

  Map<String, dynamic>? _entry(String id) {
    final v = _box.get(id);
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }

  static List<Map<String, dynamic>> _asMessageList(Object? raw) {
    if (raw is! List) return <Map<String, dynamic>>[];
    final out = <Map<String, dynamic>>[];
    for (final e in raw) {
      if (e is Map) out.add(Map<String, dynamic>.from(e));
    }
    return out;
  }

  /// Moves a pre-chunking room's single `messages` list into archive chunks.
  ///
  /// Ordered so an interruption cannot lose messages: the chunks are written and
  /// read back first, and only then does the entry drop `messages`. Cut off
  /// anywhere before that, the original list is still there and this runs again
  /// on the next call.
  Future<Map<String, dynamic>?> _migrate(String roomId) async {
    final entry = _entry(roomId);
    if (entry == null) return null;
    final legacy = _asMessageList(entry['messages']);
    if (legacy.isEmpty) {
      entry.remove('messages');
      await _box.put(roomId, entry);
      return entry;
    }

    // The newest messages go straight to the tail, so the common case — open a
    // room and send something — touches no chunk at all.
    final tailStart = legacy.length > kChatTailLimit
        ? legacy.length - kChatTailLimit
        : 0;
    final toArchive = legacy.sublist(0, tailStart);
    final tail = legacy.sublist(tailStart);

    var chunks = 0;
    for (var i = 0; i < toArchive.length; i += kChatChunkSize) {
      final end = i + kChatChunkSize <= toArchive.length
          ? i + kChatChunkSize
          : toArchive.length;
      await _box.put(_chunkKey(roomId, chunks), toArchive.sublist(i, end));
      chunks++;
    }

    // Read back before dropping the original: a write that silently stored
    // nothing would otherwise erase the conversation.
    var recovered = 0;
    for (var i = 0; i < chunks; i++) {
      recovered += _asMessageList(_box.get(_chunkKey(roomId, i))).length;
    }
    if (recovered != toArchive.length) {
      debugPrint(
        'Chat migration for $roomId read back $recovered of '
        '${toArchive.length} archived messages — keeping the original',
      );
      return entry;
    }

    entry
      ..remove('messages')
      ..['archivedChunks'] = chunks
      ..['tail'] = tail;
    await _box.put(roomId, entry);
    return entry;
  }

  /// The room entry, moved to the chunked layout if it was not already.
  Future<Map<String, dynamic>?> _entryMigrated(String roomId) async {
    final entry = _entry(roomId);
    if (entry == null) return null;
    if (!entry.containsKey('messages')) return entry;
    return _migrate(roomId);
  }

  @override
  Future<List<ChatMessage>> getMessages(Character character) async {
    final entry = await _entryMigrated(character.id);
    if (entry == null) return [];

    final out = <ChatMessage>[];
    final chunks = (entry['archivedChunks'] as num?)?.toInt() ?? 0;
    for (var i = 0; i < chunks; i++) {
      for (final m in _asMessageList(_box.get(_chunkKey(character.id, i)))) {
        out.add(ChatMessage.fromJson(m));
      }
    }
    for (final m in _asMessageList(entry['tail'])) {
      out.add(ChatMessage.fromJson(m));
    }
    return out;
  }

  @override
  Future<String?> saveMessage(Character character, ChatMessage message) async {
    final id =
        message.serverId ?? DateTime.now().microsecondsSinceEpoch.toString();
    final stored = message.copyWith(serverId: id);

    final entry = await _entryMigrated(character.id) ?? <String, dynamic>{};
    final tail = _asMessageList(entry['tail'])..add(stored.toJson());
    var chunks = (entry['archivedChunks'] as num?)?.toInt() ?? 0;

    if (tail.length > kChatTailLimit) {
      // One chunk write, then the tail shrinks by the same amount, so the entry
      // rewritten on every save never grows past the limit.
      final moving = tail.sublist(0, kChatChunkSize);
      await _box.put(_chunkKey(character.id, chunks), moving);
      if (_asMessageList(_box.get(_chunkKey(character.id, chunks))).length ==
          moving.length) {
        tail.removeRange(0, kChatChunkSize);
        chunks++;
      } else {
        // Keep them in the tail rather than drop them. It grows past the limit
        // until a chunk write succeeds.
        debugPrint('Could not archive a chunk for ${character.id}');
      }
    }

    entry['tail'] = tail;
    entry['archivedChunks'] = chunks;
    entry['title'] = character.name;
    entry['avatarNetworkUrl'] = character.isNetworkImage
        ? character.imagePath
        : null;
    entry['avatarAssetPath'] =
        (!character.isNetworkImage && character.imagePath.isNotEmpty)
        ? character.imagePath
        : null;

    await _box.put(character.id, entry);
    return id;
  }

  @override
  Future<void> clearMessages(Character character) => deleteRoom(character.id);

  @override
  Future<List<ChatRoomSummary>> getRecentRooms() async {
    final summaries = <ChatRoomSummary>[];
    for (final key in _box.keys) {
      final roomId = key is String ? key : key.toString();
      if (isArchiveKey(roomId)) continue;
      final entry = _entry(roomId);
      if (entry == null) continue;

      // Deliberately not migrated here: this runs for every room on every chats
      // tab load, and the last message reads the same from either layout.
      final raw = entry['tail'] ?? entry['messages'];
      if (raw is! List || raw.isEmpty) continue;

      final last = raw.last;
      DateTime? lastAt;
      String? lastContent;
      if (last is Map) {
        final m = Map<String, dynamic>.from(last);
        final ts = m['timestamp'];
        if (ts is String) lastAt = DateTime.tryParse(ts);
        final c = m['content'];
        lastContent = c is String ? c : c?.toString();
      }

      summaries.add(
        ChatRoomSummary(
          roomId: roomId,
          title: (entry['title'] as String?) ?? roomId,
          lastMessageAt: lastAt,
          avatarNetworkUrl: entry['avatarNetworkUrl'] as String?,
          avatarAssetPath: entry['avatarAssetPath'] as String?,
          lastMessageContent: lastContent,
        ),
      );
    }
    summaries.sort((a, b) {
      final at = a.lastMessageAt;
      final bt = b.lastMessageAt;
      if (at == null && bt == null) return 0;
      if (at == null) return 1;
      if (bt == null) return -1;
      return bt.compareTo(at);
    });
    return summaries;
  }

  @override
  Future<void> deleteRoom(String roomId) async {
    // The chunks would otherwise stay in the box forever, and a room later
    // created with the same id would read a deleted conversation's history.
    final chunks = (_entry(roomId)?['archivedChunks'] as num?)?.toInt() ?? 0;
    await _box.deleteAll([
      roomId,
      for (var i = 0; i < chunks; i++) _chunkKey(roomId, i),
    ]);
  }

  @override
  Future<bool> roomExists(String roomId) async => _box.containsKey(roomId);
}
