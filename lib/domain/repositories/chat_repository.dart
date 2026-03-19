import '../entities/chat_message.dart';

/// Contract for persisting and loading chat messages.
/// Implementations can use local storage, remote API, etc.
abstract class ChatRepository {
  Future<List<ChatMessage>> getMessages(String characterId);
  Future<void> saveMessage(String characterId, ChatMessage message);
  Future<void> clearMessages(String characterId);
}
