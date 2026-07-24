import 'dart:convert';

import '../../domain/entities/character.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/ai_chat_repository.dart';
import '../on_device/on_device_ai_runtime.dart';
import '../rag/local_rag_retriever.dart';
import 'ai_response_parser.dart';
import 'ai_system_prompt_builder.dart';

final class LiteRtLmAiRepositoryImpl implements AiChatRepository {
  LiteRtLmAiRepositoryImpl(this._runtime, {LocalRagRetriever? ragRetriever})
    : _rag = ragRetriever;

  final OnDeviceAiRuntime _runtime;

  /// Offline local RAG (saved vocabulary + relevant past turns). Optional.
  final LocalRagRetriever? _rag;
  Character? _character;
  String _appUiLanguageCode = 'ko';
  String? _userName;
  final List<({String role, String text})> _history = [];

  static const int _maxHistoryEntries = 6;
  static const int _maxHistoryRunes = 480;
  static const int _maxCurrentMessageRunes = 1200;

  @override
  void initializeForCharacter(
    Character character, {
    String appUiLanguageCode = 'ko',
    String? userName,
  }) {
    final language = appUiLanguageCode.trim().isEmpty
        ? 'ko'
        : appUiLanguageCode.trim();
    if (_character?.id != character.id || _appUiLanguageCode != language) {
      _history.clear();
    }
    _character = character;
    _appUiLanguageCode = language;
    final trimmed = userName?.trim();
    if (trimmed != null && trimmed.isNotEmpty) _userName = trimmed;
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
    // Offline local RAG: saved vocabulary + relevant older turns.
    String memory = '';
    if (_rag != null) {
      try {
        memory = await _rag.retrieveContext(
          character: character,
          userMessage: userMessage,
        );
      } catch (_) {
        memory = '';
      }
    }

    final prompt = StringBuffer();
    if (memory.isNotEmpty) {
      prompt
        ..writeln('MEMORY (learner context; use if helpful, never quote it)')
        ..writeln(memory)
        ..writeln();
    }
    prompt
      ..writeln('RECENT DIALOGUE (oldest to newest)')
      ..writeln(transcript.isEmpty ? '(none)' : transcript)
      ..writeln()
      ..writeln('NEW USER MESSAGE (reply to this)')
      ..writeln(jsonEncode(_takeRunes(userMessage, _maxCurrentMessageRunes)));

    final raw = await _runtime.generateText(
      systemInstruction: buildChatReplySystemPrompt(
        character,
        userName: _userName,
        appUiLanguageCode: _appUiLanguageCode,
      ),
      prompt: prompt.toString(),
      maxTokens: 2048,
    );
    final lang = _appUiLanguageCode.toLowerCase();
    final meaningMode = lang.startsWith('ja')
        ? VocabularyMeaningPickMode.preferJapaneseGloss
        : lang.startsWith('en')
            ? VocabularyMeaningPickMode.preferEnglishGloss
            : lang.startsWith('zh')
                ? VocabularyMeaningPickMode.preferChineseGloss
                : VocabularyMeaningPickMode.preferKoreanGloss;
    var parsed = chatMessageFromAiJsonMap(
      extractJsonObject(raw),
      character,
      vocabularyMeaningPickModeOverride: meaningMode,
    );
    _history.add((
      role: 'user',
      text: _takeRunes(userMessage, _maxHistoryRunes),
    ));
    _history.add((
      role: 'assistant',
      text: _takeRunes(parsed.content, _maxHistoryRunes),
    ));
    // Safety net: small on-device models sometimes write the bundled study
    // sheet in the friend's language instead of the learner's. If the
    // translation/glosses are not in the learner's script, re-annotate the
    // reply once in the correct language (the reply "content" is kept as-is).
    if (_studySheetLanguageWrong(parsed)) {
      try {
        final fixed = await generateExpressionAnalysis(
          parsed.content,
          character,
          appUiLanguageCode: _appUiLanguageCode,
        );
        parsed = ChatMessage(
          content: parsed.content,
          role: parsed.role,
          timestamp: parsed.timestamp,
          explanation: parsed.explanation,
          lineTranslation: fixed.lineTranslation ?? parsed.lineTranslation,
          vocabulary: (fixed.vocabulary != null && fixed.vocabulary!.isNotEmpty)
              ? fixed.vocabulary
              : parsed.vocabulary,
        );
      } catch (_) {
        // Keep the original bundled sheet if the repair pass fails.
      }
    }
    // Keep the bundled study-sheet fields so the expression sheet opens
    // instantly without a second model call.
    return ChatMessage(
      content: parsed.content,
      role: parsed.role,
      timestamp: parsed.timestamp,
      explanation: parsed.explanation,
      lineTranslation: parsed.lineTranslation,
      vocabulary: parsed.vocabulary,
    );
  }

  /// True when the bundled study sheet is present but clearly NOT written in
  /// the learner's language (e.g. a Japanese gloss shown to a Korean learner).
  bool _studySheetLanguageWrong(ChatMessage message) {
    final translation = message.lineTranslation?.trim() ?? '';
    final gloss = message.vocabulary?.isNotEmpty == true
        ? message.vocabulary!.first.meaning.trim()
        : '';
    // Nothing to check — the analysis-repair path handles empties elsewhere.
    if (translation.isEmpty && gloss.isEmpty) return false;
    final sample = '$translation $gloss';
    return !_containsScriptFor(sample, _appUiLanguageCode);
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
    final lang = appUiLanguageCode.toLowerCase();
    final meaningMode = lang.startsWith('ja')
        ? VocabularyMeaningPickMode.preferJapaneseGloss
        : lang.startsWith('en')
            ? VocabularyMeaningPickMode.preferEnglishGloss
            : lang.startsWith('zh')
                ? VocabularyMeaningPickMode.preferChineseGloss
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
    if (_analysisNeedsRepair(parsed, character)) {
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

bool _analysisNeedsRepair(ChatMessage message, Character character) {
  if ((message.lineTranslation?.trim().isEmpty ?? true) ||
      (message.explanation?.trim().isEmpty ?? true)) {
    return true;
  }
  final vocabulary = message.vocabulary;
  if (vocabulary == null || vocabulary.length < 2) return true;
  final requireReading = character.friendLanguage != 'en';
  return vocabulary.any((item) =>
      (requireReading && (item.reading?.trim().isEmpty ?? true)) ||
      item.meaning.runes.length < 15);
}

String _takeRunes(String value, int limit) {
  final runes = value.runes;
  if (runes.length <= limit) return value;
  return String.fromCharCodes(runes.take(limit));
}

// Script ranges used to sanity-check that a study sheet is in the learner's
// language. Deliberately loose — we only need to catch a whole gloss written
// in the wrong language, not classify every character.
final RegExp _hangul = RegExp(r'[가-힣ᄀ-ᇿ㄰-㆏]');
final RegExp _kana = RegExp(r'[぀-ゟ゠-ヿ]');
final RegExp _cjk = RegExp(r'[一-鿿]');
final RegExp _latin = RegExp(r'[A-Za-z]');

/// Whether [text] contains at least one character of the script expected for
/// [appLang]. For Chinese we also require the absence of Kana/Hangul so a
/// Japanese or Korean gloss is not mistaken for Chinese (they share Kanji).
bool _containsScriptFor(String text, String appLang) {
  switch (appLang.trim().toLowerCase().startsWith('zh')
      ? 'zh'
      : appLang.trim().toLowerCase().startsWith('ja')
          ? 'ja'
          : appLang.trim().toLowerCase().startsWith('en')
              ? 'en'
              : 'ko') {
    case 'ja':
      return _kana.hasMatch(text);
    case 'en':
      // English glosses are Latin; treat any CJK/Kana/Hangul-free Latin text as
      // valid. If it has none of the others but has Latin, it's fine.
      return _latin.hasMatch(text) &&
          !_kana.hasMatch(text) &&
          !_hangul.hasMatch(text);
    case 'zh':
      return _cjk.hasMatch(text) &&
          !_kana.hasMatch(text) &&
          !_hangul.hasMatch(text);
    case 'ko':
    default:
      return _hangul.hasMatch(text);
  }
}
