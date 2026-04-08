import '../entities/character.dart';
import '../entities/chat_message.dart';
import '../entities/chat_room_summary.dart';

/// Contract for persisting and loading chat messages.
/// Implementations can use local storage, remote API, etc.
abstract class ChatRepository {
  Future<List<ChatMessage>> getMessages(Character character);
  /// Returns `chat_messages.id` after insert, or null if nothing was written.
  Future<String?> saveMessage(Character character, ChatMessage message);
  Future<void> clearMessages(Character character);

  /// Recent chat rooms for the current user (newest first). Empty if not signed in.
  Future<List<ChatRoomSummary>> getRecentRooms();

  /// Supabase chat room id for this character (creates room if needed). Null if offline / local-only.
  Future<String?> getChatRoomId(Character character);

  /// Creates or returns existing DM room with a friend (mutual friendship). Supabase only.
  Future<String> ensureDmRoom(String friendUserId);

  /// Deletes the chat room and all messages (cascade). RLS must allow the current user.
  Future<void> deleteRoom(String roomId);
}
