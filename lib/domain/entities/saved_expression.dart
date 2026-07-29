/// Locally stored vocabulary entry from the chat expression sheet.
class SavedExpression {
  final String id;
  final String userId;
  final String source;

  /// Which word-book segment this row belongs to (any of
  /// `kSupportedLanguages`).
  final String notebookLang;

  /// Headword (word / phrase).
  final String? content;

  /// Legacy: old saves stored a long block here; new saves leave this null.
  final String? explanation;

  /// Pronunciation aid for [content] — hiragana, romaja, pinyin or IPA.
  ///
  /// Its own field because the two were once stored as `reading — meaning` in
  /// [translation] and split back on the first ` — `. English is the language
  /// whose reading is legitimately absent AND whose glosses idiomatically use a
  /// spaced em dash, so `Means "today" — common when asking.` came back as the
  /// reading `Means "today"` with the rest of the gloss lost. Rows written before
  /// this field existed still carry the joined form; [readingAndMeaning] handles
  /// both.
  final String? reading;

  /// Gloss for [content]. Legacy rows may hold `reading — meaning` here.
  final String? translation;
  final String? roomId;
  final DateTime createdAt;

  const SavedExpression({
    required this.id,
    required this.userId,
    required this.source,
    required this.notebookLang,
    this.content,
    this.explanation,
    this.reading,
    this.translation,
    this.roomId,
    required this.createdAt,
  });

  /// The reading and the gloss, however this row happens to store them.
  (String? reading, String meaning) get readingAndMeaning {
    final gloss = translation?.trim() ?? '';
    final own = reading?.trim() ?? '';
    if (own.isNotEmpty) return (own, gloss);
    // Legacy row: recover the pair, but only when the prefix is plausibly a
    // reading — short and without sentence punctuation. Prose before an em dash
    // is a gloss, not a pronunciation.
    const sep = ' — ';
    final i = gloss.indexOf(sep);
    if (i < 0) return (null, gloss);
    final prefix = gloss.substring(0, i).trim();
    final rest = gloss.substring(i + sep.length).trim();
    final looksLikeReading =
        prefix.isNotEmpty &&
        rest.isNotEmpty &&
        prefix.runes.length <= 24 &&
        !RegExp(r'[.!?。！？,，;；"“”]').hasMatch(prefix);
    if (!looksLikeReading) return (null, gloss);
    return (prefix, rest);
  }

  factory SavedExpression.fromRow(Map<String, dynamic> row) {
    return SavedExpression(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      source: row['source'] as String? ?? 'chat',
      notebookLang: row['notebook_lang'] as String? ?? 'ko',
      content: row['content'] as String?,
      explanation: row['explanation'] as String?,
      reading: row['reading'] as String?,
      translation: row['translation'] as String?,
      roomId: row['room_id'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}

/// Draft vocabulary entry. [explanation] stays null for current saves.
class SavedExpressionDraft {
  final String source;

  /// Which word-book segment to save into (any of `kSupportedLanguages`).
  final String notebookLang;
  final String? content;
  final String? explanation;
  final String? reading;
  final String? translation;
  final String? roomId;

  const SavedExpressionDraft({
    this.source = 'chat',
    required this.notebookLang,
    this.content,
    this.explanation,
    this.reading,
    this.translation,
    this.roomId,
  });
}
