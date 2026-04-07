import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../../core/language/dm_utterance_script.dart';
import '../../domain/entities/character.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/ai_chat_repository.dart';
import 'ai_prompts/prompt_dm_expression_analysis.dart';
import 'ai_response_parser.dart';
import 'ai_system_prompt_builder.dart';

/// [AiChatRepository] backed by an Ollama-compatible `/api/chat` HTTP endpoint.
class OllamaAiRepositoryImpl implements AiChatRepository {
  OllamaAiRepositoryImpl({
    String? baseUrl,
    String? model,
    Map<String, dynamic>? defaultOptions,
    http.Client? httpClient,
    Duration? requestTimeout,
  })  : _baseUrl = _normalizeBaseUrl(
          baseUrl ?? _env('OLLAMA_BASE_URL') ?? 'http://taba.asia:11434',
        ),
        _model = model ?? _env('OLLAMA_MODEL') ?? 'gemma4:e2b',
        _defaultOptions = defaultOptions ?? _optionsFromEnv(),
        _http = httpClient ?? http.Client(),
        _timeout = requestTimeout ?? const Duration(seconds: 600);

  final String _baseUrl;
  final String _model;
  final Map<String, dynamic> _defaultOptions;
  final http.Client _http;
  final Duration _timeout;

  Character? _currentCharacter;
  final List<Map<String, String>> _chatMessages = [];

  static String? _env(String key) {
    if (!dotenv.isInitialized) return null;
    final v = dotenv.env[key];
    if (v == null || v.isEmpty) return null;
    return v;
  }

  static String _normalizeBaseUrl(String raw) {
    var s = raw.trim();
    while (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }

  static Map<String, dynamic> _optionsFromEnv() {
    int? parseIntEnv(String key) {
      final v = _env(key);
      if (v == null) return null;
      return int.tryParse(v);
    }

    double? parseDoubleEnv(String key) {
      final v = _env(key);
      if (v == null) return null;
      return double.tryParse(v);
    }

    return {
      'num_ctx': parseIntEnv('OLLAMA_NUM_CTX') ?? 8192,
      // Large default so long JSON (chat + DM analysis) is not cut off; override via OLLAMA_NUM_PREDICT.
      'num_predict': parseIntEnv('OLLAMA_NUM_PREDICT') ?? 8192,
      'temperature': parseDoubleEnv('OLLAMA_TEMPERATURE') ?? 0.2,
    };
  }

  Uri get _chatUri => Uri.parse('$_baseUrl/api/chat');

  Future<String> _postChat(List<Map<String, String>> messages) async {
    final body = jsonEncode({
      'model': _model,
      'messages': messages,
      'options': _defaultOptions,
      'stream': false,
      'format': 'json',
    });

    final response = await _http
        .post(
          _chatUri,
          headers: {'Content-Type': 'application/json; charset=utf-8'},
          body: body,
        )
        .timeout(_timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Ollama HTTP ${response.statusCode}: ${response.body.length > 200 ? '${response.body.substring(0, 200)}…' : response.body}',
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Ollama response is not a JSON object');
    }

    return _extractAssistantText(decoded);
  }

  String _extractAssistantText(Map<String, dynamic> body) {
    final msg = body['message'];
    if (msg is! Map) {
      throw const FormatException('Ollama response missing message object');
    }
    final content = msg['content'];
    if (content is String && content.trim().isNotEmpty) {
      return content.trim();
    }
    final thinking = msg['thinking'];
    if (thinking is String && thinking.trim().isNotEmpty) {
      debugPrint('Ollama: assistant content empty; falling back to thinking field');
      return thinking.trim();
    }
    throw Exception('Empty assistant message (content and thinking)');
  }

  @override
  void initializeForCharacter(Character character) {
    if (_currentCharacter?.id == character.id) return;

    _currentCharacter = character;
    _chatMessages.clear();
    if (character.isDirectMessage) {
      return;
    }

    final system = buildCharacterSystemPrompt(character);
    _chatMessages.add({'role': 'system', 'content': system});
  }

  @override
  Future<ChatMessage> generateResponse(String userMessage) async {
    try {
      if (_currentCharacter?.isDirectMessage == true) {
        throw StateError('Direct message chat does not use AI');
      }
      if (_currentCharacter == null) {
        throw Exception('AI 서비스가 초기화되지 않았습니다.');
      }
      if (_chatMessages.isEmpty) {
        throw Exception('AI 세션이 초기화되지 않았습니다.');
      }

      _chatMessages.add({'role': 'user', 'content': userMessage});
      final raw = await _postChat(_chatMessages);
      _chatMessages.add({'role': 'assistant', 'content': raw});

      final jsonResponse = extractJsonObject(raw);
      return chatMessageFromAiJsonMap(jsonResponse, _currentCharacter!);
    } catch (e) {
      if (_chatMessages.isNotEmpty &&
          _chatMessages.last['role'] == 'user' &&
          _chatMessages.last['content'] == userMessage) {
        _chatMessages.removeLast();
      }
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
    final script = resolveDmUtteranceScript(utterance, appLanguageCode: appUiLanguageCode);
    final prompt = buildDmExpressionAnalysisPrompt(utterance, script);
    final meaningMode = script == DmUtteranceScript.koreanHeavy
        ? VocabularyMeaningPickMode.preferJapaneseGloss
        : VocabularyMeaningPickMode.preferKoreanGloss;

    try {
      final messages = <Map<String, String>>[
        {'role': 'user', 'content': prompt},
      ];
      final raw = await _postChat(messages);
      final jsonResponse = extractJsonObject(raw);
      return chatMessageFromAiJsonMap(
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
      _chatMessages.clear();
      _currentCharacter = null;
      return;
    }
    _chatMessages.clear();
    _currentCharacter = null;
    initializeForCharacter(currentCharacter);
  }
}
