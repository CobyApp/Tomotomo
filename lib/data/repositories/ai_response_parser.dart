import 'dart:convert';

import '../../domain/entities/character.dart';
import '../../domain/entities/chat_message.dart';

/// Pulls a JSON object from model output (handles extra prose / fences).
Map<String, dynamic> extractJsonObject(String raw) {
  var s = raw.trim();
  if (s.isEmpty) throw FormatException('Empty model response');
  s = s.replaceAll('```json', '').replaceAll('```JSON', '').replaceAll('```', '').trim();

  final start = s.indexOf('{');
  final end = s.lastIndexOf('}');
  if (start == -1 || end <= start) {
    throw FormatException('No JSON object in response');
  }
  final slice = s.substring(start, end + 1);
  final decoded = json.decode(slice);
  if (decoded is! Map) {
    throw FormatException('JSON root is not an object');
  }
  return Map<String, dynamic>.from(decoded);
}

String? _firstNonEmptyString(Map<String, dynamic> m, List<String> keys) {
  for (final k in keys) {
    final v = m[k];
    if (v == null) continue;
    final t = v.toString().trim();
    if (t.isNotEmpty) return t;
  }
  return null;
}

/// If the model wraps payload in `response` / `data` / `result`, use the inner map for lookups.
Map<String, dynamic> _effectiveRoot(Map<String, dynamic> json) {
  if (_firstNonEmptyString(json, const ['content', 'message', 'reply', 'text']) != null) {
    return json;
  }
  for (final k in const ['response', 'data', 'result', 'body', 'output', 'payload']) {
    final inner = json[k];
    if (inner is Map) {
      return Map<String, dynamic>.from(inner);
    }
  }
  return json;
}

List<Vocabulary>? _parseVocabularyField(
  dynamic raw, {
  required VocabularyMeaningPickMode meaningMode,
}) {
  if (raw == null) return null;
  if (raw is Map) {
    final v = Vocabulary.tryParseLoose(
      Map<String, dynamic>.from(raw),
      meaningMode: meaningMode,
    );
    return v == null ? null : [v];
  }
  if (raw is! List) return null;
  final out = <Vocabulary>[];
  for (final item in raw) {
    if (item is! Map) continue;
    final map = Map<String, dynamic>.from(item);
    final v = Vocabulary.tryParseLoose(map, meaningMode: meaningMode);
    if (v != null) out.add(v);
  }
  return out.isEmpty ? null : out;
}

/// Maps LLM JSON payload to [ChatMessage] with alternate key names.
ChatMessage chatMessageFromAiJsonMap(
  Map<String, dynamic> json,
  Character character, {
  VocabularyMeaningPickMode? vocabularyMeaningPickModeOverride,
}) {
  final root = _effectiveRoot(json);
  final meaningMode = vocabularyMeaningPickModeOverride ?? character.vocabularyMeaningPickMode;

  final content = _firstNonEmptyString(root, const [
        'content',
        'message',
        'reply',
        'text',
        'response',
        'answer',
        '発話',
        'utterance',
      ]) ??
      '';

  final explanation = _firstNonEmptyString(root, const [
    'explanation',
    'grammar_explanation',
    'grammarExplanation',
    'grammar_note',
    'note',
    'notes',
    '설명',
    '한글설명',
    'korean_explanation',
    'learning_note',
    'learningNote',
    'hint',
    'hints',
    'details',
    'detail',
    'description',
    'analysis',
  ]);

  final vocabulary = _parseVocabularyField(
    root['vocabulary'] ??
        root['words'] ??
        root['vocabs'] ??
        root['terms'] ??
        root['key_terms'] ??
        root['keyTerms'],
    meaningMode: meaningMode,
  );

  return ChatMessage(
    content: content,
    role: 'assistant',
    timestamp: DateTime.now(),
    explanation: explanation,
    vocabulary: vocabulary,
  );
}
