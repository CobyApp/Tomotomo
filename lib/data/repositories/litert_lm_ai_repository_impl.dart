import 'dart:convert';

import '../../core/locale/languages.dart';
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
    // Safety net: a small on-device model does not always obey the prompt. If
    // the bundled sheet is wrong (explained in the friend's language, missing
    // the translation, too few words, or readings in the wrong script),
    // re-annotate the reply once. The reply "content" is always kept as-is.
    if (_studySheetNeedsRepair(parsed, character)) {
      try {
        final fixed = await generateExpressionAnalysis(
          parsed.content,
          character,
          appUiLanguageCode: _appUiLanguageCode,
        );
        parsed = _mergeBetterSheet(parsed, fixed);
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

  /// Minimum vocabulary rows we accept before asking for a richer sheet.
  static const _minVocabulary = 3;

  /// True when the bundled study sheet fails any quality bar the prompt asks
  /// for, so it is worth spending one repair generation.
  bool _studySheetNeedsRepair(ChatMessage message, Character character) {
    // 1. The sentence translation is mandatory.
    final translation = message.lineTranslation?.trim() ?? '';
    if (translation.isEmpty) return true;

    // 2. Explained in the wrong language (e.g. Japanese gloss, Korean learner).
    final gloss = message.vocabulary?.isNotEmpty == true
        ? message.vocabulary!.first.meaning.trim()
        : '';
    if (!_containsScriptFor('$translation $gloss', _appUiLanguageCode)) {
      return true;
    }

    // 3. Too few words — the sheet is the main study value of a reply.
    final vocabulary = message.vocabulary ?? const [];
    if (vocabulary.length < _minVocabulary) return true;

    // 4. Readings missing or written in the wrong script.
    return vocabulary.any((v) => _readingWrong(v, character.friendLanguage));
  }

  /// A reading must exist (except English) and use the friend language's
  /// pronunciation script — Hiragana for ja, Latin for ko/zh romanization.
  bool _readingWrong(Vocabulary v, String friendLanguage) {
    final reading = v.reading?.trim() ?? '';
    switch (readingSystemFor(friendLanguage)) {
      case ReadingSystem.hiragana:
        // Kana only: Kanji or Latin in a "Hiragana" reading is wrong.
        return reading.isEmpty ||
            _cjk.hasMatch(reading) ||
            _latin.hasMatch(reading);
      case ReadingSystem.romaja:
      case ReadingSystem.pinyin:
        // Romanization: must be Latin, never the source script.
        return reading.isEmpty ||
            !_latin.hasMatch(reading) ||
            _cjk.hasMatch(reading) ||
            _hangul.hasMatch(reading);
      case ReadingSystem.ipa:
        // Optional for English.
        return false;
    }
  }

  /// Keeps the reply text, and for each study field takes whichever version is
  /// actually usable — the repair pass is not automatically better.
  ChatMessage _mergeBetterSheet(ChatMessage original, ChatMessage fixed) {
    final fixedVocab = fixed.vocabulary ?? const [];
    final originalVocab = original.vocabulary ?? const [];
    final fixedVocabUsable =
        fixedVocab.length >= originalVocab.length && fixedVocab.isNotEmpty;
    final fixedTranslation = fixed.lineTranslation?.trim() ?? '';
    return ChatMessage(
      content: original.content,
      role: original.role,
      timestamp: original.timestamp,
      explanation: original.explanation,
      lineTranslation: fixedTranslation.isNotEmpty
          ? fixed.lineTranslation
          : original.lineTranslation,
      vocabulary: fixedVocabUsable ? fixedVocab : original.vocabulary,
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
