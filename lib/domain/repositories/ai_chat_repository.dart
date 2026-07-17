import '../entities/character.dart';
import '../entities/chat_message.dart';

/// Contract for AI-generated chat responses.
/// Production inference runs locally; tests may provide an in-memory fake.
abstract class AiChatRepository {
  /// [appUiLanguageCode] determines the learner's explanation language.
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
