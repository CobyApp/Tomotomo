import '../entities/character.dart';
import '../entities/chat_message.dart';

/// Contract for AI-generated chat responses.
/// Implementations can use Gemini, OpenAI, or mock for tests.
abstract class AiChatRepository {
  void initializeForCharacter(Character character);
  Future<ChatMessage> generateResponse(String userMessage);
  void resetChat();
}
