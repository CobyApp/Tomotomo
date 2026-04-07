import 'dart:convert';

import '../../domain/entities/character.dart';
import '../../domain/entities/chat_message.dart';

/// Reads a JSON string value for [key] after `"key": "` with escape handling (recovery when full JSON is invalid).
String? _extractJsonStringValue(String s, String key) {
  final re = RegExp('"${RegExp.escape(key)}"\\s*:\\s*"');
  final m = re.firstMatch(s);
  if (m == null) return null;
  var i = m.end;
  final out = StringBuffer();
  while (i < s.length) {
    final c = s[i];
    if (c == r'\') {
      if (i + 1 >= s.length) break;
      final n = s[i + 1];
      switch (n) {
        case 'n':
          out.write('\n');
          i += 2;
          continue;
        case 'r':
          out.write('\r');
          i += 2;
          continue;
        case 't':
          out.write('\t');
          i += 2;
          continue;
        case r'\':
          out.write(r'\');
          i += 2;
          continue;
        case '"':
          out.write('"');
          i += 2;
          continue;
        case 'u':
          if (i + 5 < s.length) {
            final hex = s.substring(i + 2, i + 6);
            final code = int.tryParse(hex, radix: 16);
            if (code != null) {
              out.writeCharCode(code);
              i += 6;
              continue;
            }
          }
          break;
        default:
          out.write(n);
          i += 2;
          continue;
      }
    }
    if (c == '"') break;
    out.write(c);
    i++;
  }
  return out.toString();
}

/// When [json.decode] fails, recover `content` and optional flat vocabulary fields from broken output.
Map<String, dynamic>? _fallbackMapFromLooseJsonText(String s) {
  final content = _extractJsonStringValue(s, 'content') ??
      _extractJsonStringValue(s, 'message') ??
      _extractJsonStringValue(s, 'reply') ??
      _extractJsonStringValue(s, 'text');
  if (content == null || content.isEmpty) return null;

  final meaningJa = _extractJsonStringValue(s, 'meaning_ja') ?? _extractJsonStringValue(s, 'meaningJa');
  final meaningKo = _extractJsonStringValue(s, 'meaning_ko') ?? _extractJsonStringValue(s, 'meaningKo');
  final meaning = _extractJsonStringValue(s, 'meaning');
  final hasMeaning = [meaningJa, meaningKo, meaning]
      .any((e) => e != null && e.toString().trim().isNotEmpty);
  if (!hasMeaning) {
    return {'content': content};
  }

  final word = _extractJsonStringValue(s, 'word') ?? _extractJsonStringValue(s, 'term');
  final w = (word != null && word.trim().isNotEmpty) ? word.trim() : content.trim();

  final item = <String, dynamic>{'word': w};
  final reading = _extractJsonStringValue(s, 'reading');
  if (reading != null && reading.trim().isNotEmpty) item['reading'] = reading.trim();
  if (meaningJa != null && meaningJa.trim().isNotEmpty) item['meaning_ja'] = meaningJa.trim();
  if (meaningKo != null && meaningKo.trim().isNotEmpty) item['meaning_ko'] = meaningKo.trim();
  if (meaning != null && meaning.trim().isNotEmpty) item['meaning'] = meaning.trim();

  return {'content': content, 'vocabulary': [item]};
}

/// Pulls a JSON object from model output (handles extra prose / fences / mildly invalid JSON).
Map<String, dynamic> extractJsonObject(String raw) {
  var s = raw.trim();
  if (s.isEmpty) throw FormatException('Empty model response');
  s = s.replaceAll('```json', '').replaceAll('```JSON', '').replaceAll('```', '').trim();

  final start = s.indexOf('{');
  if (start == -1) {
    if (s.isNotEmpty) return {'content': s};
    throw FormatException('No JSON object in response');
  }

  Object? lastError;
  var end = s.lastIndexOf('}');
  while (end > start) {
    final slice = s.substring(start, end + 1);
    try {
      final decoded = json.decode(slice);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      lastError = 'JSON root is not an object';
    } catch (e) {
      lastError = e;
    }
    end = s.lastIndexOf('}', end - 1);
  }

  final recovered = _fallbackMapFromLooseJsonText(s);
  if (recovered != null) return recovered;

  throw FormatException('No valid JSON object in response (${lastError ?? 'unknown'})');
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

const List<String> _vocabularyArrayKeys = [
  'vocabulary',
  'words',
  'vocabs',
  'terms',
  'key_terms',
  'keyTerms',
  'items',
  'list',
  'entries',
  'vocab_list',
  'vocabList',
];

/// Picks vocabulary array/object from [root] or nested `data` / `response` maps.
dynamic _pickVocabularyRawFromMap(Map<String, dynamic> root) {
  for (final k in _vocabularyArrayKeys) {
    final v = root[k];
    if (v != null) return v;
  }
  for (final wrap in const ['data', 'response', 'result', 'payload', 'body', 'output']) {
    final inner = root[wrap];
    if (inner is Map) {
      final m = Map<String, dynamic>.from(inner);
      for (final k in _vocabularyArrayKeys) {
        final v = m[k];
        if (v != null) return v;
      }
    }
  }
  return null;
}

/// Unwrap JSON-in-string, `{ "items": [...] }`, etc.
dynamic _unwrapVocabularyDynamic(dynamic raw) {
  if (raw == null) return null;
  if (raw is String) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    try {
      return _unwrapVocabularyDynamic(json.decode(t));
    } catch (_) {
      return null;
    }
  }
  if (raw is List) return raw;
  if (raw is Map) {
    final m = Map<String, dynamic>.from(raw);
    for (final k in _vocabularyArrayKeys) {
      final v = m[k];
      if (v is List && v.isNotEmpty) return v;
      if (v is String) {
        final u = _unwrapVocabularyDynamic(v);
        if (u is List) return u;
      }
    }
    return raw;
  }
  return null;
}

/// Maps common alternate LLM keys onto the names [Vocabulary.tryParseLoose] expects.
Map<String, dynamic> _normalizeVocabularyEntryAliases(Map<String, dynamic> m) {
  final o = Map<String, dynamic>.from(m);

  void copyIfEmpty(String target, List<String> sources) {
    if (_firstNonEmptyString(o, [target]) != null) return;
    final v = _firstNonEmptyString(o, sources);
    if (v != null) o[target] = v;
  }

  copyIfEmpty('meaning_ko', ['korean', 'ko_gloss', 'korean_gloss', 'definition_ko', 'def_ko']);
  copyIfEmpty('meaning_ja', ['ja_gloss', 'ja_meaning', 'japanese_meaning', 'nihongo', 'def_ja', 'definition_ja']);
  copyIfEmpty('word', ['headword', 'lemma', 'token', '表記', '見出し語', 'surface_form', 'surfaceForm']);
  copyIfEmpty('reading', ['yomi', 'furigana', 'romaji', 'pronunciation']);

  return o;
}

/// If the model nested one entry as `vocab` / `entry` / `item`.
Map<String, dynamic>? _unwrapNestedVocabEntry(Map<String, dynamic> m) {
  for (final k in const ['vocab', 'entry', 'item', 'row', 'card']) {
    final inner = m[k];
    if (inner is Map) return Map<String, dynamic>.from(inner);
  }
  return null;
}

List<Vocabulary>? _parseVocabularyField(
  dynamic raw, {
  required VocabularyMeaningPickMode meaningMode,
}) {
  raw = _unwrapVocabularyDynamic(raw);
  if (raw == null) return null;

  if (raw is Map) {
    final nested = _unwrapNestedVocabEntry(Map<String, dynamic>.from(raw));
    final map = _normalizeVocabularyEntryAliases(nested ?? Map<String, dynamic>.from(raw));
    final v = Vocabulary.tryParseLoose(map, meaningMode: meaningMode);
    return v == null ? null : [v];
  }
  if (raw is! List) return null;
  final out = <Vocabulary>[];
  for (final item in raw) {
    if (item is! Map) continue;
    var map = Map<String, dynamic>.from(item);
    final nested = _unwrapNestedVocabEntry(map);
    if (nested != null) map = nested;
    map = _normalizeVocabularyEntryAliases(map);
    final v = Vocabulary.tryParseLoose(map, meaningMode: meaningMode);
    if (v != null) out.add(v);
  }
  return out.isEmpty ? null : out;
}

/// If the model put a single vocabulary row on the root (valid JSON but wrong shape), hoist into `vocabulary`.
Map<String, dynamic> _hoistFlatVocabularyIntoArray(Map<String, dynamic> root) {
  final raw = _pickVocabularyRawFromMap(root);
  if (raw is List && raw.isNotEmpty) return root;

  final meaningJa = _firstNonEmptyString(root, const ['meaning_ja', 'meaningJa', 'gloss_ja']);
  final meaningKo = _firstNonEmptyString(root, const [
    'meaning_ko',
    'meaningKo',
    'korean_meaning',
    'gloss_ko',
    'ko_meaning',
  ]);
  final meaning = _firstNonEmptyString(root, const [
    'meaning',
    'definition',
    'gloss',
    'translation',
    'mean',
    '뜻',
  ]);
  if (meaningJa == null && meaningKo == null && meaning == null) return root;

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
  final word = _firstNonEmptyString(root, const [
    'word',
    'term',
    'expression',
    'surface',
    '単語',
  ]);
  final w = (word != null && word.isNotEmpty) ? word : content.trim();
  if (w.isEmpty) return root;

  final reading = _firstNonEmptyString(root, const [
    'reading',
    'read',
    'yomi',
    'hiragana',
    'kana',
  ]);

  final item = <String, dynamic>{'word': w};
  if (reading != null && reading.isNotEmpty) item['reading'] = reading;
  if (meaningJa != null && meaningJa.isNotEmpty) item['meaning_ja'] = meaningJa;
  if (meaningKo != null && meaningKo.isNotEmpty) item['meaning_ko'] = meaningKo;
  if (meaning != null && meaning.isNotEmpty) item['meaning'] = meaning;

  final out = Map<String, dynamic>.from(root);
  out['vocabulary'] = [item];
  return out;
}

/// Maps LLM JSON payload to [ChatMessage] with alternate key names.
ChatMessage chatMessageFromAiJsonMap(
  Map<String, dynamic> json,
  Character character, {
  VocabularyMeaningPickMode? vocabularyMeaningPickModeOverride,
}) {
  final root = _hoistFlatVocabularyIntoArray(_effectiveRoot(json));
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
    _pickVocabularyRawFromMap(root),
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
