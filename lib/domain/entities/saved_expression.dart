/// Row in `public.saved_expressions`.
class SavedExpression {
  final String id;
  final String userId;
  final String source;
  final String? content;
  final String? explanation;
  final String? translation;
  final String? roomId;
  final DateTime createdAt;

  const SavedExpression({
    required this.id,
    required this.userId,
    required this.source,
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
      content: row['content'] as String?,
      explanation: row['explanation'] as String?,
      translation: row['translation'] as String?,
      roomId: row['room_id'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}

/// Payload for insert (current user from auth).
class SavedExpressionDraft {
  final String source;
  final String? content;
  final String? explanation;
  final String? translation;
  final String? roomId;

  const SavedExpressionDraft({
    this.source = 'chat',
    this.content,
    this.explanation,
    this.translation,
    this.roomId,
  });
}
