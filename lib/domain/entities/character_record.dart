/// Custom character stored in Supabase (public.characters).
/// For full UI (colors, traits) use domain/entities/character.dart; this is the DB row.
class CharacterRecord {
  final String id;
  final String ownerId;
  final String name;
  final String? nameSecondary;
  final String? avatarUrl;
  final String? backgroundUrl;
  final String? speechStyle;
  /// Short line shown on cards / profile-style UI (optional).
  final String? tagline;
  final String? voiceProvider;
  final String? voiceId;
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
    this.backgroundUrl,
    this.speechStyle,
    this.tagline,
    this.voiceProvider,
    this.voiceId,
    this.language = 'ja',
    this.isPublic = false,
    this.downloadCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a draft record for insert (id/dates are stripped by repository).
  static CharacterRecord draft({
    required String ownerId,
    required String name,
    String? nameSecondary,
    String? avatarUrl,
    String? backgroundUrl,
    String? speechStyle,
    String? tagline,
    String? voiceProvider,
    String? voiceId,
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
      backgroundUrl: backgroundUrl,
      speechStyle: speechStyle,
      tagline: tagline,
      voiceProvider: voiceProvider,
      voiceId: voiceId,
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
      backgroundUrl: json['background_url'] as String?,
      speechStyle: json['speech_style'] as String?,
      tagline: json['tagline'] as String?,
      voiceProvider: json['voice_provider'] as String?,
      voiceId: json['voice_id'] as String?,
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
      'background_url': backgroundUrl,
      'speech_style': speechStyle,
      'tagline': tagline,
      'voice_provider': voiceProvider,
      'voice_id': voiceId,
      'language': language,
      'is_public': isPublic,
      'download_count': downloadCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
