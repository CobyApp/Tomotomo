/// Which JSON keys to prefer when filling [Vocabulary.meaning] (LLMs often send both JA/KO fields).
enum VocabularyMeaningPickMode {
  /// Japanese-speaking tutor, Korean study notes: prefer Korean gloss keys; do not take `meaning_ja` before `meaning`.
  preferKoreanGloss,

  /// Korean friend, Japanese study notes: prefer Japanese gloss keys.
  preferJapaneseGloss,

  /// Japanese immersion or local cache: prefer generic `meaning`, then others.
  neutral,

  /// English study notes: prefer English gloss keys.
  preferEnglishGloss,

  /// Chinese study notes: prefer Chinese gloss keys.
  preferChineseGloss,
}

/// Gloss preference driven by the learner's app UI language, so cached and
/// freshly-parsed vocabulary meanings are picked consistently in every language.
VocabularyMeaningPickMode meaningPickModeForApp(String appLanguageCode) {
  final lang = appLanguageCode.toLowerCase();
  if (lang.startsWith('ja')) return VocabularyMeaningPickMode.preferJapaneseGloss;
  if (lang.startsWith('en')) return VocabularyMeaningPickMode.preferEnglishGloss;
  if (lang.startsWith('zh')) return VocabularyMeaningPickMode.preferChineseGloss;
  return VocabularyMeaningPickMode.preferKoreanGloss;
}

class ChatMessage {
  /// Persistent local message identifier; null for optimistic rows.
  final String? serverId;
  final String content;
  final String role;
  final DateTime timestamp;
  final String? explanation;

  /// Full-line translation for learners (e.g. Japanese line → Korean).
  final String? lineTranslation;

  final List<Vocabulary>? vocabulary;

  ChatMessage({
    this.serverId,
    required this.content,
    required this.role,
    required this.timestamp,
    this.explanation,
    this.lineTranslation,
    this.vocabulary,
  });

  ChatMessage copyWith({
    String? serverId,
    String? content,
    String? role,
    DateTime? timestamp,
    String? explanation,
    String? lineTranslation,
    List<Vocabulary>? vocabulary,
  }) {
    return ChatMessage(
      serverId: serverId ?? this.serverId,
      content: content ?? this.content,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      explanation: explanation ?? this.explanation,
      lineTranslation: lineTranslation ?? this.lineTranslation,
      vocabulary: vocabulary ?? this.vocabulary,
    );
  }

  Map<String, dynamic> toJson() => {
    if (serverId != null) 'serverId': serverId,
    'content': content,
    'role': role,
    'timestamp': timestamp.toIso8601String(),
    'explanation': explanation,
    'lineTranslation': lineTranslation,
    'vocabulary': vocabulary?.map((v) => v.toJson()).toList(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    serverId: json['serverId'] as String?,
    content: json['content'] as String,
    role: json['role'] as String,
    timestamp: DateTime.parse(json['timestamp']),
    explanation: json['explanation'] as String?,
    lineTranslation: json['lineTranslation'] as String?,
    vocabulary: json['vocabulary'] != null
        ? () {
            final out = <Vocabulary>[];
            for (final v in json['vocabulary'] as List) {
              if (v is! Map) continue;
              final m = Map<String, dynamic>.from(v);
              final p = Vocabulary.tryParseLoose(
                m,
                meaningMode: VocabularyMeaningPickMode.neutral,
              );
              if (p != null) out.add(p);
            }
            return out.isEmpty ? null : out;
          }()
        : null,
  );
}

class Vocabulary {
  final String word;
  final String? reading;
  final String meaning;

  Vocabulary({required this.word, this.reading, required this.meaning});

  Map<String, dynamic> toJson() {
    return {'word': word, 'reading': reading, 'meaning': meaning};
  }

  factory Vocabulary.fromJson(Map<String, dynamic> json) {
    final parsed = tryParseLoose(json);
    if (parsed == null) {
      throw FormatException('Vocabulary.fromJson: missing word/meaning: $json');
    }
    return parsed;
  }

  static bool _hasHangul(String s) => RegExp(r'[가-힣]').hasMatch(s);

  static bool _hasKana(String s) => RegExp(r'[\u3040-\u30ff]').hasMatch(s);

  static bool _hasCjkUnified(String s) =>
      RegExp(r'[\u4e00-\u9fff]').hasMatch(s);

  /// For Korean gloss mode: reject strings that look like Japanese (kana or kanji-only) without Hangul.
  static bool _looksLikeKoreanVocabMeaning(String t) {
    if (_hasHangul(t)) return true;
    if (_hasKana(t)) return false;
    if (_hasCjkUnified(t)) return false;
    return true;
  }

  /// Accepts common alternate keys from LLM / legacy rows.
  static Vocabulary? tryParseLoose(
    Map<String, dynamic> json, {
    VocabularyMeaningPickMode meaningMode = VocabularyMeaningPickMode.neutral,
  }) {
    String? pickString(List<String> keys) {
      for (final k in keys) {
        final v = json[k];
        if (v == null) continue;
        final t = v.toString().trim();
        if (t.isNotEmpty) return t;
      }
      return null;
    }

    String? pickFirstWhere(List<String> keys, bool Function(String t) accept) {
      for (final k in keys) {
        final v = json[k];
        if (v == null) continue;
        final t = v.toString().trim();
        if (t.isNotEmpty && accept(t)) return t;
      }
      return null;
    }

    final String? word = switch (meaningMode) {
      VocabularyMeaningPickMode.preferJapaneseGloss => () {
        const koKeys = [
          'word_ko',
          'wordKo',
          'korean_word',
          'phrase_ko',
          'surface_ko',
          'expression_ko',
          'hangul',
        ];
        const generic = [
          'word',
          'term',
          'expression',
          'surface',
          'headword',
          'lemma',
          'token',
          'phrase',
          '単語',
          'japanese',
        ];
        return pickString(koKeys) ??
            pickFirstWhere(generic, _hasHangul) ??
            pickString(generic);
      }(),
      VocabularyMeaningPickMode.preferKoreanGloss => pickString(const [
        'word',
        'term',
        'expression',
        '単語',
        'japanese',
        'surface',
        'headword',
        'lemma',
        'token',
        'phrase',
        'hangul',
        'word_ko',
        'wordKo',
        'phrase_ko',
        'surface_ko',
      ]),
      VocabularyMeaningPickMode.neutral => pickString(const [
        'word',
        'term',
        'expression',
        '単語',
        'japanese',
        'surface',
        'headword',
        'lemma',
        'token',
        'phrase',
        'word_ko',
        'wordKo',
        'phrase_ko',
        'surface_ko',
      ]),
      VocabularyMeaningPickMode.preferEnglishGloss ||
      VocabularyMeaningPickMode.preferChineseGloss => pickString(const [
        'word', 'term', 'expression', '単語', 'japanese', 'surface',
        'headword', 'lemma', 'token', 'phrase', 'word_ko', 'wordKo',
        'phrase_ko', 'surface_ko', 'hanzi', 'pinyin_word',
      ]),
    };

    final String? meaning = switch (meaningMode) {
      VocabularyMeaningPickMode.preferKoreanGloss => () {
        const strictKo = [
          'meaning_ko',
          'meaningKo',
          'korean_meaning',
          'gloss_ko',
          'ko_meaning',
          'hint_ko',
          'korean',
          'ko_gloss',
        ];
        const loose = [
          'meaning',
          'definition',
          'gloss',
          'translation',
          'mean',
          '뜻',
        ];
        const jaFallback = ['meaning_ja', 'meaningJa', 'gloss_ja'];
        return pickString(strictKo) ??
            pickFirstWhere(loose, _looksLikeKoreanVocabMeaning) ??
            pickString(loose) ??
            pickString(jaFallback);
      }(),
      VocabularyMeaningPickMode.preferJapaneseGloss => pickString(const [
        'meaning_ja',
        'meaningJa',
        'gloss_ja',
        'ja_meaning',
        'ja_gloss',
        'japanese_meaning',
        'nihongo',
        'meaning',
        'definition',
        'gloss',
        'translation',
        'mean',
        '뜻',
        'meaning_ko',
        'meaningKo',
        'korean_meaning',
        'gloss_ko',
      ]),
      VocabularyMeaningPickMode.neutral => pickString(const [
        'meaning',
        'definition',
        'gloss',
        'translation',
        'mean',
        '뜻',
        'meaning_ko',
        'meaningKo',
        'korean_meaning',
        'gloss_ko',
        'meaning_ja',
        'meaningJa',
        'gloss_ja',
      ]),
      VocabularyMeaningPickMode.preferEnglishGloss => pickString(const [
        'meaning_en', 'meaningEn', 'english_meaning', 'gloss_en', 'en_meaning',
        'english', 'en_gloss',
        'meaning', 'definition', 'gloss', 'translation', 'mean',
        'meaning_ko', 'meaningKo', 'meaning_ja', 'meaningJa',
      ]),
      VocabularyMeaningPickMode.preferChineseGloss => pickString(const [
        'meaning_zh', 'meaningZh', 'chinese_meaning', 'gloss_zh', 'zh_meaning',
        'chinese', 'zh_gloss',
        'meaning', 'definition', 'gloss', 'translation', 'mean',
        'meaning_ko', 'meaningKo', 'meaning_ja', 'meaningJa',
      ]),
    };
    if (word == null || meaning == null) return null;

    final reading = pickString(const [
      'reading',
      'read',
      'yomi',
      'hiragana',
      'kana',
      'pronunciation_ja',
      'pronunciationJa',
      'yomi_ja',
      'yomikata',
      'furigana',
      'ruby',
      'katakana',
      'よみ',
      '読み',
      '読み方',
    ]);

    return Vocabulary(word: word, reading: reading, meaning: meaning);
  }
}
