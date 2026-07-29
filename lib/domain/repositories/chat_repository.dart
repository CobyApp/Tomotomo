import '../entities/character.dart';
import '../entities/chat_message.dart';
import '../entities/chat_room_summary.dart';

/// Local persistence of chat messages, one message list per character.
abstract class ChatRepository {
  Future<List<ChatMessage>> getMessages(Character character);
  /// Saves [message] locally, returns the stored message id.
  Future<String?> saveMessage(Character character, ChatMessage message);
  Future<void> clearMessages(Character character);
  /// Recent chat rooms (characters with history), newest first.
  Future<List<ChatRoomSummary>> getRecentRooms();
  /// Deletes all messages for the room identified by [roomId] (== character id here).
  Future<void> deleteRoom(String roomId);

  /// Whether a room still exists. Checked before saving a reply that finished
  /// after the user deleted the conversation — saving would recreate it.
  Future<bool> roomExists(String roomId);
}
