import '../entities/character.dart';
import '../entities/chat_message.dart';

/// Contract for AI-generated chat responses.
/// Implementations can use an Ollama-compatible HTTP API or mocks for tests.
abstract class AiChatRepository {
  void initializeForCharacter(Character character);
  Future<ChatMessage> generateResponse(String userMessage);

  /// Human DM line: pick Japanese vs Korean tutor JSON schema from [utterance] script.
  Future<ChatMessage> generateDmExpressionAnalysis(String utterance, {required String appUiLanguageCode});

  void resetChat();
}
