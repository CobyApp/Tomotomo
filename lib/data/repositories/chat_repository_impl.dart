import '../../domain/entities/character.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_room_summary.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_local_datasource.dart';

/// Local-only chat persistence (SharedPreferences). No cross-device sync.
class ChatRepositoryImpl implements ChatRepository {
  final ChatLocalDatasource _datasource;

  ChatRepositoryImpl(this._datasource);

  @override
  Future<List<ChatMessage>> getMessages(Character character) =>
      _datasource.getMessages(character.id);

  @override
  Future<void> saveMessage(Character character, ChatMessage message) async {
    final messages = await _datasource.getMessages(character.id);
    messages.add(message);
    await _datasource.saveMessages(character.id, messages);
  }

  @override
  Future<void> clearMessages(Character character) =>
      _datasource.clearMessages(character.id);

  @override
  Future<List<ChatRoomSummary>> getRecentRooms() async => [];

  @override
  Future<String?> getChatRoomId(Character character) async => null;

  @override
  Future<String> ensureDmRoom(String friendUserId) async {
    throw UnsupportedError('Direct messages require Supabase');
  }

  @override
  Future<void> deleteRoom(String roomId) async {}

  @override
  Future<void> sendDirectMessageVoiceNote(Character character, String localAudioPath) async {
    throw UnsupportedError('Direct message voice requires Supabase');
  }
}
