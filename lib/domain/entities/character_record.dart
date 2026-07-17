/// Custom character stored locally in Hive.
///
/// **Tutor mode** ([language]): `ja` → Japanese bubble + Korean study notes (learn Japanese).
/// `ko` → Korean bubble + Japanese study notes (learn Korean). Mirror opposites; see `ai_prompts/`.
///
/// **Name**: [name] is the only display name. [nameSecondary] remains solely
/// for reading records created by older app versions.
///
/// For chat UI and colors use [Character.fromRecord].
class CharacterRecord {
  final String id;
  final String name;
  final String? nameSecondary;
  final String? avatarUrl;

  /// One-line list subtitle (~20 chars); not the full AI memo ([speechStyle]).
  final String? tagline;
  final String? speechStyle;
  final String language;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CharacterRecord({
    required this.id,
    required this.name,
    this.nameSecondary,
    this.avatarUrl,
    this.tagline,
    this.speechStyle,
    this.language = 'ja',
    required this.createdAt,
    required this.updatedAt,
  });

  /// Text for list subtitles: [tagline], else first line of [speechStyle].
  String get listDetailLine {
    final tag = tagline?.trim();
    if (tag != null && tag.isNotEmpty) return tag;
    final m = speechStyle?.trim();
    if (m != null && m.isNotEmpty) {
      final first = m.split(RegExp(r'\r?\n')).first.trim();
      if (first.length > 48) return '${first.substring(0, 45)}…';
      return first;
    }
    return '';
  }

  /// Creates a draft record for insert (id/dates are stripped by repository).
  static CharacterRecord draft({
    required String name,
    String? nameSecondary,
    String? avatarUrl,
    String? tagline,
    String? speechStyle,
    String language = 'ja',
  }) {
    final now = DateTime.now();
    return CharacterRecord(
      id: '',
      name: name,
      nameSecondary: nameSecondary,
      avatarUrl: avatarUrl,
      tagline: tagline,
      speechStyle: speechStyle,
      language: language,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory CharacterRecord.fromJson(Map<String, dynamic> json) {
    return CharacterRecord(
      id: json['id'] as String,
      name: json['name'] as String,
      nameSecondary: json['name_secondary'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      tagline: json['tagline'] as String?,
      speechStyle: json['speech_style'] as String?,
      language: json['language'] as String? ?? 'ja',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_secondary': nameSecondary,
      'avatar_url': avatarUrl,
      'tagline': tagline,
      'speech_style': speechStyle,
      'language': language,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
