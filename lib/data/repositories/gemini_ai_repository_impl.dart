import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../../domain/entities/character.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/ai_chat_repository.dart';
import 'ai_response_parser.dart';
import 'ai_system_prompt_builder.dart';
import 'gemini_retry.dart';

/// [AiChatRepository] backed by Google Gemini (Generative Language API).
///
/// Uses [generateContent] with a **sliding history window** instead of an
/// ever-growing [ChatSession], so latency does not explode on long threads.
class GeminiAiRepositoryImpl implements AiChatRepository {
  GeminiAiRepositoryImpl({
    String? apiKey,
    String? model,
    double? temperature,
    int? maxOutputTokens,
    int? maxChatHistoryContents,
  }) : _apiKeyOverride = apiKey,
       _modelOverride = model,
       _temperatureOverride = temperature,
       _maxOutputTokensOverride = maxOutputTokens,
       _maxChatHistoryContentsOverride = maxChatHistoryContents;

  final String? _apiKeyOverride;
  final String? _modelOverride;
  final double? _temperatureOverride;
  final int? _maxOutputTokensOverride;
  final int? _maxChatHistoryContentsOverride;

  Character? _currentCharacter;
  GenerativeModel? _chatModel;
  String _appUiLanguageCode = 'ko';

  /// Prior turns: alternating user / model [Content] (JSON assistant lines).
  final List<Content> _history = [];

  static const Duration _timeout = Duration(seconds: 120);

  /// Cap how many [Content] blocks (user+model pairs × 2) we send per request.
  static const int _defaultMaxChatHistoryContents = 24;

  static String? _env(String key) {
    if (!dotenv.isInitialized) return null;
    final v = dotenv.env[key];
    if (v == null || v.isEmpty) return null;
    return v;
  }

  String get _apiKey =>
      (_apiKeyOverride ?? _env('GEMINI_API_KEY') ?? '').trim();

  /// Default: lowest-cost text tier on paid Standard; see SETTINGS.md.
  String get _modelName =>
      (_modelOverride ?? _env('GEMINI_MODEL') ?? 'gemini-2.5-flash-lite')
          .trim();

  double get _temperature {
    final tempOverride = _temperatureOverride;
    if (tempOverride != null) return tempOverride;
    final p = _env('GEMINI_TEMPERATURE');
    if (p != null) {
      final v = double.tryParse(p);
      if (v != null && v > 0) return v;
    }
    return 0.2;
  }

  int get _maxOutputTokens {
    final maxOverride = _maxOutputTokensOverride;
    if (maxOverride != null) return maxOverride;
    final p = _env('GEMINI_MAX_OUTPUT_TOKENS');
    if (p != null) {
      final v = int.tryParse(p);
      if (v != null && v > 0) return v;
    }
    // Tutor JSON includes full_translation + learning_note + vocabulary.
    return 768;
  }

  int get _maxChatHistoryContents {
    final o = _maxChatHistoryContentsOverride;
    if (o != null && o >= 2) return o;
    final p = _env('GEMINI_MAX_CHAT_CONTENTS');
    if (p != null) {
      final v = int.tryParse(p);
      if (v != null && v >= 2) return v;
    }
    return _defaultMaxChatHistoryContents;
  }

  void _ensureApiKey() {
    if (_apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY is not set. Add it to your .env file.');
    }
  }

  GenerationConfig get _jsonGenerationConfig => GenerationConfig(
    temperature: _temperature,
    maxOutputTokens: _maxOutputTokens,
    responseMimeType: 'application/json',
  );

  GenerativeModel _buildChatModel(Character character) {
    _ensureApiKey();
    return GenerativeModel(
      model: _modelName,
      apiKey: _apiKey,
      systemInstruction: Content.system(
        buildCharacterSystemPrompt(
          character,
          appUiLanguageCode: _appUiLanguageCode,
        ),
      ),
      generationConfig: _jsonGenerationConfig,
    );
  }

  GenerativeModel _buildAnalysisModel(
    Character character,
    String appUiLanguageCode,
  ) {
    _ensureApiKey();
    return GenerativeModel(
      model: _modelName,
      apiKey: _apiKey,
      systemInstruction: Content.system(
        buildCharacterSystemPrompt(
          character,
          appUiLanguageCode: appUiLanguageCode,
        ),
      ),
      generationConfig: _jsonGenerationConfig,
    );
  }

  /// Recent history only so each API call stays small (faster TTFT + generation).
  List<Content> _historyWindowForRequest() {
    final cap = _maxChatHistoryContents;
    if (_history.length <= cap) return List<Content>.from(_history);
    var slice = _history.sublist(_history.length - cap);
    // Prompt must start with a user turn; drop leading model chunk if any.
    while (slice.isNotEmpty && slice.first.role != 'user') {
      slice = slice.sublist(1);
    }
    return slice;
  }

  static Content _normalizeModelContent(Candidate candidate) {
    final c = candidate.content;
    if (c.role == null) {
      return Content.model(c.parts);
    }
    return c;
  }

  @override
  void initializeForCharacter(
    Character character, {
    String appUiLanguageCode = 'ko',
  }) {
    final lang = appUiLanguageCode.trim().isEmpty ? 'ko' : appUiLanguageCode;
    if (_currentCharacter?.id == character.id &&
        _chatModel != null &&
        _appUiLanguageCode == lang) {
      return;
    }
    _appUiLanguageCode = lang;
    _currentCharacter = character;
    _chatModel = null;
    _history.clear();
    _chatModel = _buildChatModel(character);
  }

  @override
  Future<ChatMessage> generateResponse(String userMessage) async {
    try {
      if (_currentCharacter == null) {
        throw Exception('AI 서비스가 초기화되지 않았습니다.');
      }
      if (_chatModel == null) {
        throw Exception('AI 세션이 초기화되지 않았습니다.');
      }

      final userContent = Content.text(userMessage);
      final prompt = [..._historyWindowForRequest(), userContent];

      final genResponse = await withGeminiRetry(
        () => _chatModel!.generateContent(prompt),
        perAttemptTimeout: _timeout,
      );
      final rawText = genResponse.text;
      if (rawText == null || rawText.trim().isEmpty) {
        throw Exception(
          'Empty Gemini response (check safety filters or model name).',
        );
      }
      final jsonResponse = extractJsonObject(rawText.trim());

      final cands = genResponse.candidates;
      if (cands.isEmpty) {
        throw Exception('Gemini returned no candidates');
      }
      _history.add(userContent);
      _history.add(_normalizeModelContent(cands.first));

      return chatMessageFromAiJsonMap(jsonResponse, _currentCharacter!);
    } catch (e) {
      debugPrint('AI 응답 오류: $e');
      rethrow;
    }
  }

  @override
  Future<ChatMessage> generateExpressionAnalysis(
    String utterance,
    Character character, {
    required String appUiLanguageCode,
  }) async {
    final model = _buildAnalysisModel(character, appUiLanguageCode);
    final response = await withGeminiRetry(
      () => model.generateContent([
        Content.text(
          'Analyze this existing tutor utterance without continuing the '
          'conversation. Return the required JSON object, keep "content" '
          'exactly equal to the utterance, and include full_translation, '
          'learning_note, and vocabulary.\n\nUtterance:\n$utterance',
        ),
      ]),
      perAttemptTimeout: _timeout,
    );
    final rawText = response.text;
    if (rawText == null || rawText.trim().isEmpty) {
      throw Exception(
        'Empty Gemini response (check safety filters or model name).',
      );
    }
    return chatMessageFromAiJsonMap(
      extractJsonObject(rawText.trim()),
      character,
    );
  }

  @override
  void resetChat() {
    if (_currentCharacter == null) return;
    final currentCharacter = _currentCharacter!;
    _chatModel = null;
    _history.clear();
    _currentCharacter = null;
    initializeForCharacter(
      currentCharacter,
      appUiLanguageCode: _appUiLanguageCode,
    );
  }
}
