import '../../core/supabase/app_supabase.dart';
import '../../data/character/characters_data.dart' as builtin_chars;
import '../../domain/entities/character.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_room_summary.dart';
import '../../domain/repositories/chat_repository.dart';

/// Persists chat rooms and messages in Supabase (`chat_rooms`, `chat_messages`).
class SupabaseChatRepository implements ChatRepository {
  static final _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  bool _isUuid(String id) => _uuid.hasMatch(id);

  @override
  Future<String?> getChatRoomId(Character character) async {
    final user = AppSupabase.auth.currentUser;
    if (user == null) return null;
    if (character.isDirectMessage) return character.directMessageRoomId;
    try {
      return await _findExistingRoomRowId(character.id, user.id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<ChatRoomSummary>> getRecentRooms() async {
    final user = AppSupabase.auth.currentUser;
    if (user == null) return [];
    final res = await AppSupabase.client
        .from('chat_rooms')
        .select('*')
        .or('user_id.eq.${user.id},peer_user_id.eq.${user.id}')
        .order('last_message_at', ascending: false);
    var summaries = (res as List<dynamic>)
        .map((e) => ChatRoomSummary.fromRow(Map<String, dynamic>.from(e as Map)))
        .where((s) => s.lastMessageAt != null)
        .toList();
    summaries = await _roomsWithAtLeastOneUserMessage(summaries);
    final hiddenDmPeers = await _dmPeerUserIdsHiddenByBlocks(user.id);
    if (hiddenDmPeers.isNotEmpty) {
      summaries = summaries.where((s) {
        if (!s.isDm) return true;
        final o = s.otherParticipantUserId(user.id);
        return o == null || !hiddenDmPeers.contains(o);
      }).toList();
    }
    summaries = await _enrichRoomsForDisplay(summaries, user.id);
    return _attachLastMessagePreview(summaries);
  }

  /// Latest message per room (by `created_at`) for the chats list preview line.
  Future<List<ChatRoomSummary>> _attachLastMessagePreview(List<ChatRoomSummary> rooms) async {
    if (rooms.isEmpty) return rooms;
    final ids = rooms.map((r) => r.roomId).toList();
    try {
      final res = await AppSupabase.client
          .from('chat_messages')
          .select('room_id, content, created_at')
          .inFilter('room_id', ids)
          .order('created_at', ascending: false);
      final latest = <String, String>{};
      for (final row in res as List<dynamic>) {
        final m = Map<String, dynamic>.from(row as Map);
        final rawRid = m['room_id'];
        final rid = rawRid is String ? rawRid : rawRid?.toString();
        if (rid == null || latest.containsKey(rid)) continue;
        final c = m['content'];
        latest[rid] = c is String ? c : c.toString();
      }
      return rooms.map((r) => r.copyWith(lastMessageContent: latest[r.roomId])).toList();
    } catch (_) {
      return rooms;
    }
  }

  /// Peers involved in any block row with the current user (hide DM rooms with them).
  Future<Set<String>> _dmPeerUserIdsHiddenByBlocks(String me) async {
    try {
      final res = await AppSupabase.client.from('user_blocks').select('blocker_id, blocked_id');
      final hidden = <String>{};
      for (final row in res as List<dynamic>) {
        final m = Map<String, dynamic>.from(row as Map);
        final b = m['blocker_id'].toString();
        final d = m['blocked_id'].toString();
        if (b == me) hidden.add(d);
        if (d == me) hidden.add(b);
      }
      return hidden;
    } catch (_) {
      return {};
    }
  }

  /// Hides rooms where only assistant/system messages exist (e.g. legacy auto-welcome).
  Future<List<ChatRoomSummary>> _roomsWithAtLeastOneUserMessage(List<ChatRoomSummary> rooms) async {
    if (rooms.isEmpty) return [];
    final ids = rooms.map((r) => r.roomId).toList();
    final res = await AppSupabase.client
        .from('chat_messages')
        .select('room_id')
        .inFilter('room_id', ids)
        .eq('role', 'user');
    final withUser = <String>{};
    for (final row in res as List<dynamic>) {
      final m = Map<String, dynamic>.from(row as Map);
      final rid = m['room_id'];
      if (rid is String) {
        withUser.add(rid);
      } else if (rid != null) {
        withUser.add(rid.toString());
      }
    }
    return rooms.where((r) => withUser.contains(r.roomId)).toList();
  }

  /// Fills display title (DM), and avatar URL or asset path for list tiles.
  Future<List<ChatRoomSummary>> _enrichRoomsForDisplay(List<ChatRoomSummary> summaries, String me) async {
    final dmOthers = <String>{};
    final charUuids = <String>{};
    for (final s in summaries) {
      if (s.isDm) {
        final o = s.otherParticipantUserId(me);
        if (o != null) dmOthers.add(o);
      } else if (s.characterIdSupabase != null && s.characterIdSupabase!.isNotEmpty) {
        charUuids.add(s.characterIdSupabase!);
      }
    }

    final profileById = <String, Map<String, dynamic>>{};
    if (dmOthers.isNotEmpty) {
      final profiles = await AppSupabase.client
          .from('profiles')
          .select('id,display_name,email,avatar_url,status_message')
          .inFilter('id', dmOthers.toList());
      for (final p in profiles as List<dynamic>) {
        final m = Map<String, dynamic>.from(p as Map);
        final id = m['id'] is String ? m['id'] as String : m['id'].toString();
        profileById[id] = m;
      }
    }

    final charMetaById = <String, Map<String, dynamic>>{};
    if (charUuids.isNotEmpty) {
      final rows = await AppSupabase.client
          .from('characters')
          .select('id,avatar_url,name,name_secondary,language')
          .inFilter('id', charUuids.toList());
      for (final row in rows as List<dynamic>) {
        final m = Map<String, dynamic>.from(row as Map);
        final id = m['id'] is String ? m['id'] as String : m['id'].toString();
        charMetaById[id] = m;
      }
    }

    return summaries.map((s) {
      if (s.isDm) {
        final o = s.otherParticipantUserId(me);
        if (o == null) return s;
        final p = profileById[o];
        if (p == null) return s;
        final dn = p['display_name'] as String?;
        final em = p['email'] as String?;
        final av = p['avatar_url'] as String?;
        final st = p['status_message'] as String?;
        final label = dn != null && dn.trim().isNotEmpty ? dn.trim() : (em ?? o);
        final url = av != null && av.trim().isNotEmpty ? av.trim() : null;
        final statusLine = st != null && st.trim().isNotEmpty ? st.trim() : null;
        final emailLine =
            (em != null && em.trim().isNotEmpty && em.trim() != label) ? em.trim() : null;
        final secondary = statusLine ?? emailLine;
        var u = s.copyWith(title: label, avatarNetworkUrl: url);
        if (secondary != null) u = u.copyWith(titleSecondary: secondary);
        return u;
      }

      final cid = s.characterIdSupabase;
      if (cid != null && cid.isNotEmpty) {
        final m = charMetaById[cid];
        if (m != null) {
          final rawName = m['name'];
          final dbName = rawName is String ? rawName : (rawName?.toString() ?? s.title);
          final secRaw = m['name_secondary'];
          final dbSec = secRaw is String ? secRaw : secRaw?.toString();
          final langRaw = m['language'];
          final lang = langRaw is String ? langRaw : (langRaw?.toString() ?? 'ja');
          final titles = Character.bilingualChatTitlesFromCharacterDb(
            language: lang,
            dbName: dbName,
            dbNameSecondary: dbSec,
          );
          final av = m['avatar_url'];
          final url = av is String && av.trim().isNotEmpty ? av.trim() : null;
          var u = s.copyWith(title: titles.primary, avatarNetworkUrl: url);
          if (titles.secondary.isNotEmpty) u = u.copyWith(titleSecondary: titles.secondary);
          return u;
        }
        return s;
      }

      final ext = s.externalCharacterKey;
      if (ext != null && ext.isNotEmpty) {
        for (final c in builtin_chars.characters) {
          if (c.id == ext) {
            final path = c.imagePath.trim();
            var u = s.copyWith(title: c.displayNamePrimary);
            if (c.displayNameSecondary.isNotEmpty) u = u.copyWith(titleSecondary: c.displayNameSecondary);
            if (path.startsWith('http://') || path.startsWith('https://')) {
              u = u.copyWith(avatarNetworkUrl: path);
            } else {
              u = u.copyWith(avatarAssetPath: path);
            }
            return u;
          }
        }
      }

      return s;
    }).toList();
  }

  @override
  Future<String> ensureDmRoom(String friendUserId) async {
    final user = AppSupabase.auth.currentUser;
    if (user == null) throw Exception('Not signed in');
    final raw = await AppSupabase.client.rpc(
      'ensure_dm_room',
      params: {'other_user_id': friendUserId},
    );
    if (raw == null) throw Exception('ensure_dm_room failed');
    return raw is String ? raw : raw.toString();
  }

  /// Existing character room only; does not insert. Used so opening a chat without sending
  /// does not create an empty row that could appear in the recent list.
  Future<String?> _findExistingRoomRowId(String characterId, String userId) async {
    if (_isUuid(characterId)) {
      final existing = await AppSupabase.client
          .from('chat_rooms')
          .select('id')
          .eq('user_id', userId)
          .eq('character_id', characterId)
          .maybeSingle();
      if (existing != null) {
        return Map<String, dynamic>.from(existing as Map)['id'] as String;
      }
      return null;
    }

    final existing = await AppSupabase.client
        .from('chat_rooms')
        .select('id')
        .eq('user_id', userId)
        .eq('external_character_key', characterId)
        .maybeSingle();
    if (existing != null) {
      return Map<String, dynamic>.from(existing as Map)['id'] as String;
    }
    return null;
  }

  Future<String> _ensureRoomId(Character character) async {
    final user = AppSupabase.auth.currentUser;
    if (user == null) throw Exception('Not signed in');
    final title = character.displayNamePrimary;
    final id = character.id;

    if (_isUuid(id)) {
      final existing = await AppSupabase.client
          .from('chat_rooms')
          .select('id')
          .eq('user_id', user.id)
          .eq('character_id', id)
          .maybeSingle();
      if (existing != null) {
        return Map<String, dynamic>.from(existing as Map)['id'] as String;
      }
      try {
        final row = await AppSupabase.client.from('chat_rooms').insert({
          'user_id': user.id,
          'character_id': id,
          'title': title,
        }).select('id').single();
        return Map<String, dynamic>.from(row as Map)['id'] as String;
      } catch (_) {
        final again = await AppSupabase.client
            .from('chat_rooms')
            .select('id')
            .eq('user_id', user.id)
            .eq('character_id', id)
            .maybeSingle();
        if (again != null) {
          return Map<String, dynamic>.from(again as Map)['id'] as String;
        }
        rethrow;
      }
    }

    final existingExt = await AppSupabase.client
        .from('chat_rooms')
        .select('id')
        .eq('user_id', user.id)
        .eq('external_character_key', id)
        .maybeSingle();
    if (existingExt != null) {
      return Map<String, dynamic>.from(existingExt as Map)['id'] as String;
    }
    try {
      final row = await AppSupabase.client.from('chat_rooms').insert({
        'user_id': user.id,
        'external_character_key': id,
        'title': title,
      }).select('id').single();
      return Map<String, dynamic>.from(row as Map)['id'] as String;
    } catch (_) {
      final again = await AppSupabase.client
          .from('chat_rooms')
          .select('id')
          .eq('user_id', user.id)
          .eq('external_character_key', id)
          .maybeSingle();
      if (again != null) {
        return Map<String, dynamic>.from(again as Map)['id'] as String;
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteRoom(String roomId) async {
    final user = AppSupabase.auth.currentUser;
    if (user == null) throw Exception('Not signed in');
    await AppSupabase.client.from('chat_rooms').delete().eq('id', roomId);
  }

  @override
  Future<List<ChatMessage>> getMessages(Character character) async {
    final user = AppSupabase.auth.currentUser;
    if (user == null) return [];
    final String? roomId;
    if (character.isDirectMessage) {
      roomId = character.directMessageRoomId;
    } else {
      roomId = await _findExistingRoomRowId(character.id, user.id);
    }
    if (roomId == null || roomId.isEmpty) return [];
    final res = await AppSupabase.client
        .from('chat_messages')
        .select('*')
        .eq('room_id', roomId)
        .order('created_at', ascending: true);
    return (res as List<dynamic>).map((e) => _rowToMessage(e, character)).toList();
  }

  ChatMessage _rowToMessage(dynamic e, Character character) {
    final row = Map<String, dynamic>.from(e as Map);
    final vocab = row['vocabulary'];
    final mode = character.vocabularyMeaningPickMode;
    List<Vocabulary>? vocabulary;
    if (vocab is List) {
      final list = <Vocabulary>[];
      for (final v in vocab) {
        if (v is! Map) continue;
        final m = Map<String, dynamic>.from(v);
        final parsed = Vocabulary.tryParseLoose(m, meaningMode: mode);
        if (parsed != null) list.add(parsed);
      }
      vocabulary = list.isEmpty ? null : list;
    }
    final sid = row['sender_id'];
    final rawId = row['id'];
    final mid = rawId == null ? null : (rawId is String ? rawId : rawId.toString());
    return ChatMessage(
      serverId: mid,
      content: row['content'] as String,
      role: row['role'] as String,
      timestamp: DateTime.parse(row['created_at'] as String),
      explanation: row['explanation'] as String?,
      lineTranslation: row['line_translation'] as String?,
      vocabulary: vocabulary,
      senderId: sid == null ? null : (sid is String ? sid : sid.toString()),
    );
  }

  Map<String, dynamic> _messageToRow(String roomId, ChatMessage m, {String? senderIdForDm}) {
    final row = <String, dynamic>{
      'room_id': roomId,
      'role': m.role,
      'content': m.content,
      'explanation': m.explanation,
      'line_translation': m.lineTranslation,
      'vocabulary': m.vocabulary?.map((v) => v.toJson()).toList(),
    };
    if (senderIdForDm != null) {
      row['sender_id'] = senderIdForDm;
    }
    return row;
  }

  @override
  Future<String?> saveMessage(Character character, ChatMessage message) async {
    final user = AppSupabase.auth.currentUser;
    if (user == null) return null;
    final roomId = character.isDirectMessage
        ? character.directMessageRoomId
        : await _ensureRoomId(character);
    if (roomId == null || roomId.isEmpty) return null;
    final sender = character.isDirectMessage ? (message.senderId ?? user.id) : null;
    final row = await AppSupabase.client
        .from('chat_messages')
        .insert(_messageToRow(roomId, message, senderIdForDm: sender))
        .select('id')
        .maybeSingle();
    if (row == null) return null;
    final m = Map<String, dynamic>.from(row as Map);
    final id = m['id'];
    return id == null ? null : (id is String ? id : id.toString());
  }

  @override
  Future<void> clearMessages(Character character) async {
    final user = AppSupabase.auth.currentUser;
    if (user == null) return;
    final roomId = character.isDirectMessage
        ? character.directMessageRoomId
        : await _ensureRoomId(character);
    if (roomId == null || roomId.isEmpty) return;
    await AppSupabase.client.from('chat_messages').delete().eq('room_id', roomId);
  }
}
