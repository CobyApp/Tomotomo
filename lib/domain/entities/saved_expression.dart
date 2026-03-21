/// Row in `public.saved_expressions` — one **vocabulary** entry (from chat sheet `+`), not the full explanation popup.
class SavedExpression {
  final String id;
  final String userId;
  final String source;

  /// `ko` | `ja` — which word-book segment this row belongs to.
  final String notebookLang;

  /// Headword (word / phrase).
  final String? content;

  /// Legacy: old saves stored a long block here; new saves leave this null.
  final String? explanation;

  /// Reading + gloss line for [content].
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
    this.translation,
    this.roomId,
    required this.createdAt,
  });

  factory SavedExpression.fromRow(Map<String, dynamic> row) {
    return SavedExpression(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      source: row['source'] as String? ?? 'chat',
      notebookLang: row['notebook_lang'] as String? ?? 'ko',
      content: row['content'] as String?,
      explanation: row['explanation'] as String?,
      translation: row['translation'] as String?,
      roomId: row['room_id'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}

/// Payload for insert (current user from auth). Vocabulary row: [content] + [translation]; [explanation] should stay null.
class SavedExpressionDraft {
  final String source;

  /// `ko` | `ja`
  final String notebookLang;
  final String? content;
  final String? explanation;
  final String? translation;
  final String? roomId;

  const SavedExpressionDraft({
    this.source = 'chat',
    required this.notebookLang,
    this.content,
    this.explanation,
    this.translation,
    this.roomId,
  });
}
