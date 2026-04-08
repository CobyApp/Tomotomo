/// User profile stored in Supabase (public.profiles).
class Profile {
  final String id;
  final String? email;
  final String? displayName;
  final String? avatarUrl;
  final String? statusMessage;
  final String appLanguage;
  final String learningLanguage;
  /// In-app currency for AI / downloads (server-owned; do not trust client writes).
  final int pointBalance;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Profile({
    required this.id,
    this.email,
    this.displayName,
    this.avatarUrl,
    this.statusMessage,
    this.appLanguage = 'ko',
    this.learningLanguage = 'ja',
    this.pointBalance = 500,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      email: json['email'] as String?,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      statusMessage: json['status_message'] as String?,
      appLanguage: json['app_language'] as String? ?? 'ko',
      learningLanguage: json['learning_language'] as String? ?? 'ja',
      pointBalance: (json['point_balance'] as num?)?.toInt() ?? 500,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'status_message': statusMessage,
      'app_language': appLanguage,
      'learning_language': learningLanguage,
      'point_balance': pointBalance,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Profile copyWith({
    String? displayName,
    String? avatarUrl,
    String? statusMessage,
    String? appLanguage,
    String? learningLanguage,
    int? pointBalance,
  }) {
    return Profile(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      statusMessage: statusMessage ?? this.statusMessage,
      appLanguage: appLanguage ?? this.appLanguage,
      learningLanguage: learningLanguage ?? this.learningLanguage,
      pointBalance: pointBalance ?? this.pointBalance,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
