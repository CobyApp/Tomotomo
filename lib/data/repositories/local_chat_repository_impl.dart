import 'package:hive_ce/hive.dart';

import '../../domain/entities/character.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_room_summary.dart';
import '../../domain/repositories/chat_repository.dart';

/// Local chat persistence in the `chats` box. Each character's history is one
/// entry keyed by [Character.id]: a map holding display metadata (for the
/// recent-rooms list) plus the ordered message list. Single local user.
class LocalChatRepositoryImpl implements ChatRepository {
  LocalChatRepositoryImpl(this._box);
  final Box _box;

  Map<String, dynamic>? _entry(String id) {
    final v = _box.get(id);
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }

  @override
  Future<List<ChatMessage>> getMessages(Character character) async {
    final entry = _entry(character.id);
    if (entry == null) return [];
    final raw = entry['messages'];
    if (raw is! List) return [];
    final out = <ChatMessage>[];
    for (final e in raw) {
      if (e is! Map) continue;
      out.add(ChatMessage.fromJson(Map<String, dynamic>.from(e)));
    }
    return out;
  }

  @override
  Future<String?> saveMessage(Character character, ChatMessage message) async {
    final id =
        message.serverId ?? DateTime.now().microsecondsSinceEpoch.toString();
    final stored = message.copyWith(serverId: id);

    final entry = _entry(character.id) ?? <String, dynamic>{};
    final messages = <Map<String, dynamic>>[];
    final existing = entry['messages'];
    if (existing is List) {
      for (final e in existing) {
        if (e is Map) messages.add(Map<String, dynamic>.from(e));
      }
    }
    messages.add(stored.toJson());

    entry['messages'] = messages;
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
  Future<void> clearMessages(Character character) async {
    await _box.delete(character.id);
  }

  @override
  Future<List<ChatRoomSummary>> getRecentRooms() async {
    final summaries = <ChatRoomSummary>[];
    for (final key in _box.keys) {
      final roomId = key is String ? key : key.toString();
      final entry = _entry(roomId);
      if (entry == null) continue;
      final raw = entry['messages'];
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
    await _box.delete(roomId);
  }

  @override
  Future<bool> roomExists(String roomId) async => _box.containsKey(roomId);
}
