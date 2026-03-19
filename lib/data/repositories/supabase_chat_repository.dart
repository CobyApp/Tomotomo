import '../../core/supabase/app_supabase.dart';
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
      return await _ensureRoomId(character);
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
    final summaries = (res as List<dynamic>)
        .map((e) => ChatRoomSummary.fromRow(Map<String, dynamic>.from(e as Map)))
        .toList();
    return await _enrichDmRoomTitles(summaries, user.id);
  }

  Future<List<ChatRoomSummary>> _enrichDmRoomTitles(List<ChatRoomSummary> summaries, String me) async {
    final dmOthers = <String>{};
    for (final s in summaries) {
      if (s.isDm) {
        final o = s.otherParticipantUserId(me);
        if (o != null) dmOthers.add(o);
      }
    }
    if (dmOthers.isEmpty) return summaries;
    final profiles = await AppSupabase.client
        .from('profiles')
        .select('id,display_name,email')
        .inFilter('id', dmOthers.toList());
    final nameById = <String, String>{};
    for (final p in profiles as List<dynamic>) {
      final m = Map<String, dynamic>.from(p as Map);
      final id = m['id'] is String ? m['id'] as String : m['id'].toString();
      final dn = m['display_name'] as String?;
      final em = m['email'] as String?;
      nameById[id] = dn != null && dn.trim().isNotEmpty ? dn.trim() : (em ?? id);
    }
    return summaries.map((s) {
      if (!s.isDm) return s;
      final o = s.otherParticipantUserId(me);
      if (o == null) return s;
      final label = nameById[o];
      if (label == null || label.isEmpty) return s;
      return s.copyWith(title: label);
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

  Future<String> _ensureRoomId(Character character) async {
    final user = AppSupabase.auth.currentUser;
    if (user == null) throw Exception('Not signed in');
    final title = character.name;
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

    final existing = await AppSupabase.client
        .from('chat_rooms')
        .select('id')
        .eq('user_id', user.id)
        .eq('external_character_key', id)
        .maybeSingle();
    if (existing != null) {
      return Map<String, dynamic>.from(existing as Map)['id'] as String;
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
  Future<List<ChatMessage>> getMessages(Character character) async {
    final user = AppSupabase.auth.currentUser;
    if (user == null) return [];
    final roomId = character.isDirectMessage
        ? character.directMessageRoomId
        : await _ensureRoomId(character);
    if (roomId == null || roomId.isEmpty) return [];
    final res = await AppSupabase.client
        .from('chat_messages')
        .select('*')
        .eq('room_id', roomId)
        .order('created_at', ascending: true);
    return (res as List<dynamic>).map(_rowToMessage).toList();
  }

  ChatMessage _rowToMessage(dynamic e) {
    final row = Map<String, dynamic>.from(e as Map);
    final vocab = row['vocabulary'];
    List<Vocabulary>? vocabulary;
    if (vocab is List) {
      vocabulary = vocab
          .map((v) => Vocabulary.fromJson(Map<String, dynamic>.from(v as Map)))
          .toList();
    }
    final sid = row['sender_id'];
    return ChatMessage(
      content: row['content'] as String,
      role: row['role'] as String,
      timestamp: DateTime.parse(row['created_at'] as String),
      explanation: row['explanation'] as String?,
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
      'vocabulary': m.vocabulary?.map((v) => v.toJson()).toList(),
    };
    if (senderIdForDm != null) {
      row['sender_id'] = senderIdForDm;
    }
    return row;
  }

  @override
  Future<void> saveMessage(Character character, ChatMessage message) async {
    final user = AppSupabase.auth.currentUser;
    if (user == null) return;
    final roomId = character.isDirectMessage
        ? character.directMessageRoomId
        : await _ensureRoomId(character);
    if (roomId == null || roomId.isEmpty) return;
    final sender = character.isDirectMessage ? (message.senderId ?? user.id) : null;
    await AppSupabase.client.from('chat_messages').insert(_messageToRow(roomId, message, senderIdForDm: sender));
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
