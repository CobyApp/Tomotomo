import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../core/language/dm_utterance_script.dart';
import '../../domain/entities/character.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/ai_chat_repository.dart';
import 'gemini_prompts/prompt_dm_expression_analysis.dart';
import 'gemini_response_parser.dart';
import 'gemini_system_prompt_builder.dart';

/// Gemini-based implementation of [AiChatRepository].
class GeminiAiRepositoryImpl implements AiChatRepository {
  final String _apiKey;
  GenerativeModel? _model;
  ChatSession? _chatSession;
  Character? _currentCharacter;

  /// [apiKey] optional; when null, reads from dotenv (call dotenv.load() first in production).
  GeminiAiRepositoryImpl({String? apiKey})
      : _apiKey = apiKey ?? dotenv.env['GEMINI_API_KEY'] ?? '' {
    if (_apiKey.isEmpty) {
      debugPrint('경고: GEMINI_API_KEY가 설정되지 않았습니다.');
    } else {
      _model = GenerativeModel(
        // Cheapest stable multimodal text model in the current Gemini API lineup.
        model: 'gemini-2.5-flash-lite',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );
    }
  }

  @override
  void initializeForCharacter(Character character) {
    if (_currentCharacter?.id == character.id) return;

    _currentCharacter = character;
    if (character.isDirectMessage) {
      _chatSession = null;
      return;
    }
    if (_model == null) return;

    final prompt = buildGeminiSystemPrompt(character);

    _chatSession = _model?.startChat(history: [
      Content.text(prompt),
    ]);
  }

  @override
  Future<ChatMessage> generateResponse(String userMessage) async {
    try {
      if (_currentCharacter?.isDirectMessage == true) {
        throw StateError('Direct message chat does not use AI');
      }
      if (_currentCharacter == null || _model == null) {
        throw Exception('AI 서비스가 초기화되지 않았습니다.');
      }

      final response =
          await _chatSession!.sendMessage(Content.text(userMessage));

      if (response.text == null) {
        throw Exception('응답이 비어있습니다.');
      }

      final jsonResponse = extractJsonObject(response.text!);
      return chatMessageFromGeminiMap(jsonResponse, _currentCharacter!);
    } catch (e) {
      debugPrint('AI 응답 오류: $e');
      rethrow;
    }
  }

  static final Character _dmParseDummy = Character.forDirectMessage(
    peerUserId: '_dm_expression_parse_',
    roomId: '_',
    displayName: 'DM',
  );

  @override
  Future<ChatMessage> generateDmExpressionAnalysis(
    String utterance, {
    required String appUiLanguageCode,
  }) async {
    if (_model == null) {
      throw Exception('AI 서비스가 초기화되지 않았습니다.');
    }
    final script = resolveDmUtteranceScript(utterance, appLanguageCode: appUiLanguageCode);
    final prompt = buildDmExpressionAnalysisPrompt(utterance, script);
    final meaningMode = script == DmUtteranceScript.koreanHeavy
        ? VocabularyMeaningPickMode.preferJapaneseGloss
        : VocabularyMeaningPickMode.preferKoreanGloss;

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        throw Exception('응답이 비어있습니다.');
      }
      final jsonResponse = extractJsonObject(text);
      return chatMessageFromGeminiMap(
        jsonResponse,
        _dmParseDummy,
        vocabularyMeaningPickModeOverride: meaningMode,
      );
    } catch (e) {
      debugPrint('DM expression analysis 오류: $e');
      rethrow;
    }
  }

  @override
  void resetChat() {
    if (_currentCharacter == null) return;
    final currentCharacter = _currentCharacter!;
    if (currentCharacter.isDirectMessage) {
      _chatSession = null;
      _currentCharacter = null;
      return;
    }
    if (_model == null) return;
    _chatSession = null;
    _currentCharacter = null;
    initializeForCharacter(currentCharacter);
  }
}
