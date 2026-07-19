import 'dart:convert';

import '../../domain/entities/character.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/ai_chat_repository.dart';
import '../on_device/on_device_ai_runtime.dart';
import 'ai_response_parser.dart';
import 'ai_system_prompt_builder.dart';

final class LiteRtLmAiRepositoryImpl implements AiChatRepository {
  LiteRtLmAiRepositoryImpl(this._runtime);

  final OnDeviceAiRuntime _runtime;
  Character? _character;
  String _appUiLanguageCode = 'ko';
  final List<({String role, String text})> _history = [];

  static const int _maxHistoryEntries = 6;
  static const int _maxHistoryRunes = 480;
  static const int _maxCurrentMessageRunes = 1200;

  @override
  void initializeForCharacter(
    Character character, {
    String appUiLanguageCode = 'ko',
  }) {
    final language = appUiLanguageCode.trim().isEmpty
        ? 'ko'
        : appUiLanguageCode.trim();
    if (_character?.id != character.id || _appUiLanguageCode != language) {
      _history.clear();
    }
    _character = character;
    _appUiLanguageCode = language;
  }

  @override
  Future<ChatMessage> generateResponse(String userMessage) async {
    final character = _character;
    if (character == null) {
      throw StateError('AI 캐릭터가 초기화되지 않았습니다.');
    }

    final history = _history.length <= _maxHistoryEntries
        ? _history
        : _history.sublist(_history.length - _maxHistoryEntries);
    final transcript = history
        .map(
          (turn) =>
              '${turn.role == 'user' ? 'User' : 'Assistant'}: '
              '${_takeRunes(turn.text, _maxHistoryRunes)}',
        )
        .join('\n');
    final prompt = StringBuffer()
      ..writeln('RECENT DIALOGUE (oldest to newest)')
      ..writeln(transcript.isEmpty ? '(none)' : transcript)
      ..writeln()
      ..writeln('NEW USER MESSAGE (reply to this)')
      ..writeln(jsonEncode(_takeRunes(userMessage, _maxCurrentMessageRunes)));

    final raw = await _runtime.generateText(
      systemInstruction: buildChatReplySystemPrompt(character),
      prompt: prompt.toString(),
      maxTokens: 2048,
    );
    final parsed = chatMessageFromAiJsonMap(extractJsonObject(raw), character);
    _history.add((
      role: 'user',
      text: _takeRunes(userMessage, _maxHistoryRunes),
    ));
    _history.add((
      role: 'assistant',
      text: _takeRunes(parsed.content, _maxHistoryRunes),
    ));
    return ChatMessage(
      content: parsed.content,
      role: parsed.role,
      timestamp: parsed.timestamp,
    );
  }

  @override
  Future<ChatMessage> generateExpressionAnalysis(
    String utterance,
    Character character, {
    required String appUiLanguageCode,
  }) async {
    final systemInstruction = buildExpressionAnalysisSystemPrompt(
      character: character,
      appUiLanguageCode: appUiLanguageCode,
    );
    final encodedUtterance = jsonEncode(
      _takeRunes(utterance, _maxCurrentMessageRunes),
    );
    final meaningMode = appUiLanguageCode.toLowerCase().startsWith('ja')
        ? VocabularyMeaningPickMode.preferJapaneseGloss
        : VocabularyMeaningPickMode.preferKoreanGloss;

    Future<ChatMessage> analyze(String prompt) async {
      final raw = await _runtime.generateText(
        systemInstruction: systemInstruction,
        prompt: prompt,
        temperature: 0.1,
        maxTokens: 2048,
      );
      return chatMessageFromAiJsonMap(
        extractJsonObject(raw),
        character,
        vocabularyMeaningPickModeOverride: meaningMode,
      );
    }

    var parsed = await analyze('UTTERANCE TO ANALYZE\n$encodedUtterance');
    if (_analysisNeedsRepair(parsed)) {
      parsed = await analyze(
        'UTTERANCE TO ANALYZE\n$encodedUtterance\n\n'
        'CORRECTION REQUIRED: The previous result was incomplete. Return a '
        'complete full_translation and learning_note, 2–4 vocabulary items, '
        'a non-empty reading for every item, and a detailed meaning plus usage '
        'for every item. Follow the system JSON schema exactly.',
      );
    }
    return ChatMessage(
      content: utterance,
      role: parsed.role,
      timestamp: parsed.timestamp,
      explanation: parsed.explanation,
      lineTranslation: parsed.lineTranslation,
      vocabulary: parsed.vocabulary,
    );
  }

  @override
  void resetChat() => _history.clear();
}

bool _analysisNeedsRepair(ChatMessage message) {
  if ((message.lineTranslation?.trim().isEmpty ?? true) ||
      (message.explanation?.trim().isEmpty ?? true)) {
    return true;
  }
  final vocabulary = message.vocabulary;
  if (vocabulary == null || vocabulary.length < 2) return true;
  return vocabulary.any(
    (item) =>
        (item.reading?.trim().isEmpty ?? true) ||
        item.meaning.runes.length < 15,
  );
}

String _takeRunes(String value, int limit) {
  final runes = value.runes;
  if (runes.length <= limit) return value;
  return String.fromCharCodes(runes.take(limit));
}
