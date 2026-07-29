/// Character cap on a friend's tagline, enforced both by the editor's text
/// field and by the clamp applied to an imported one — a width-only budget let
/// an imported ASCII tagline open the field already over its own limit.
const int kTaglineMaxChars = 40;

/// Custom character stored locally in Hive.
///
/// Friend language ([language]): 'ko' | 'ja' | 'en' | 'zh' (Simplified).
///
/// **Name**: [name] is the only display name.
///
/// For chat UI and colors use [Character.fromRecord].
class CharacterRecord {
  final String id;
  final String name;
  final String? avatarUrl;

  /// One-line list subtitle (~20 chars); not the full AI memo ([speechStyle]).
  final String? tagline;
  final String? speechStyle;
  final String language;

  /// Learner speech level: 'beginner' | 'intermediate' | 'advanced' | 'business'.
  /// Shapes the friend's register (반말/MZ/경어 …) + difficulty in the chat prompt.
  final String level;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CharacterRecord({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.tagline,
    this.speechStyle,
    this.language = 'ja',
    this.level = 'intermediate',
    required this.createdAt,
    required this.updatedAt,
  });


  /// Creates a draft record for insert (id/dates are stripped by repository).
  static CharacterRecord draft({
    required String name,
    String? avatarUrl,
    String? tagline,
    String? speechStyle,
    String language = 'ja',
    String level = 'intermediate',
  }) {
    final now = DateTime.now();
    return CharacterRecord(
      id: '',
      name: name,
      avatarUrl: avatarUrl,
      tagline: tagline,
      speechStyle: speechStyle,
      language: language,
      level: level,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory CharacterRecord.fromJson(Map<String, dynamic> json) {
    return CharacterRecord(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      tagline: json['tagline'] as String?,
      speechStyle: json['speech_style'] as String?,
      language: json['language'] as String? ?? 'ja',
      level: json['level'] as String? ?? 'intermediate',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar_url': avatarUrl,
      'tagline': tagline,
      'speech_style': speechStyle,
      'language': language,
      'level': level,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
