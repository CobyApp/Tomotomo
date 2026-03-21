/// Custom character stored in Supabase (`public.characters`).
///
/// **Tutor mode** ([language]): `ja` → Japanese bubble + Korean study notes (learn Japanese).
/// `ko` → Korean bubble + Japanese study notes (learn Korean). Mirror opposites; see Gemini prompts.
///
/// **Names**: [name] is the primary display script for that mode (`ja` → Japanese line, `ko` → Korean).
/// [nameSecondary] is the optional other script (e.g. Hangul for a `ja` tutor).
///
/// For chat UI and colors use [Character.fromRecord].
class CharacterRecord {
  final String id;
  final String ownerId;
  final String name;
  final String? nameSecondary;
  final String? avatarUrl;
  final String? speechStyle;
  final String language;
  final bool isPublic;
  final int downloadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CharacterRecord({
    required this.id,
    required this.ownerId,
    required this.name,
    this.nameSecondary,
    this.avatarUrl,
    this.speechStyle,
    this.language = 'ja',
    this.isPublic = false,
    this.downloadCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Text for list subtitles: [speechStyle], else [nameSecondary], else empty (caller may show language).
  String get listDetailLine {
    final m = speechStyle?.trim();
    if (m != null && m.isNotEmpty) return m;
    final s = nameSecondary?.trim();
    if (s != null && s.isNotEmpty) return s;
    return '';
  }

  /// Creates a draft record for insert (id/dates are stripped by repository).
  static CharacterRecord draft({
    required String ownerId,
    required String name,
    String? nameSecondary,
    String? avatarUrl,
    String? speechStyle,
    String language = 'ja',
    bool isPublic = false,
  }) {
    final now = DateTime.now();
    return CharacterRecord(
      id: '',
      ownerId: ownerId,
      name: name,
      nameSecondary: nameSecondary,
      avatarUrl: avatarUrl,
      speechStyle: speechStyle,
      language: language,
      isPublic: isPublic,
      downloadCount: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory CharacterRecord.fromJson(Map<String, dynamic> json) {
    return CharacterRecord(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      nameSecondary: json['name_secondary'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      speechStyle: json['speech_style'] as String?,
      language: json['language'] as String? ?? 'ja',
      isPublic: json['is_public'] as bool? ?? false,
      downloadCount: json['download_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'name_secondary': nameSecondary,
      'avatar_url': avatarUrl,
      'speech_style': speechStyle,
      'language': language,
      'is_public': isPublic,
      'download_count': downloadCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
