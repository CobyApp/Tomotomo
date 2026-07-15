import '../entities/character.dart';
import '../entities/chat_message.dart';

/// Contract for AI-generated chat responses.
/// Implementations can use Gemini, another HTTP API, or mocks for tests.
abstract class AiChatRepository {
  /// [appUiLanguageCode] is used for tutor system prompts (e.g. [learning_note] language).
  void initializeForCharacter(
    Character character, {
    String appUiLanguageCode = 'ko',
  });
  Future<ChatMessage> generateResponse(String userMessage);
  Future<ChatMessage> generateExpressionAnalysis(
    String utterance,
    Character character, {
    required String appUiLanguageCode,
  });
  void resetChat();
}
