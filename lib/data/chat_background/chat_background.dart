/// Immutable per-room chat background selection.
///
/// [presetId] references an entry in the preset catalog
/// (see `chat_background_presets.dart`); [intensity] (0.0–1.0) controls how
/// strong the color wash is over the base paper background. When [imagePath]
/// is set, a custom photo is used as the background and [intensity] controls
/// how much the photo shows through a paper scrim (higher = clearer photo).
class ChatBackground {
  const ChatBackground({
    required this.presetId,
    required this.intensity,
    this.imagePath,
  });

  /// Neutral default: the normal paper background at a moderate wash.
  /// The 'paper' preset renders as the plain paper surface regardless of
  /// intensity, so this is effectively "no custom background".
  const ChatBackground.defaultBg()
    : presetId = 'paper',
      intensity = 0.45,
      imagePath = null;

  final String presetId;

  /// Wash strength, clamped to 0.0–1.0.
  final double intensity;

  /// Absolute path to a custom background photo, or null to use [presetId].
  final String? imagePath;

  ChatBackground copyWith({
    String? presetId,
    double? intensity,
    String? imagePath,
    bool clearImage = false,
  }) {
    return ChatBackground(
      presetId: presetId ?? this.presetId,
      intensity: intensity ?? this.intensity,
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
    );
  }

  Map<String, dynamic> toJson() => {
    'presetId': presetId,
    'intensity': intensity,
    if (imagePath != null) 'imagePath': imagePath,
  };

  factory ChatBackground.fromJson(Map<String, dynamic> json) {
    final rawIntensity = (json['intensity'] as num?)?.toDouble() ?? 0.45;
    final path = json['imagePath']?.toString();
    return ChatBackground(
      presetId: json['presetId']?.toString() ?? 'paper',
      intensity: rawIntensity.clamp(0.0, 1.0),
      imagePath: (path != null && path.isNotEmpty) ? path : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ChatBackground &&
      other.presetId == presetId &&
      other.intensity == intensity &&
      other.imagePath == imagePath;

  @override
  int get hashCode => Object.hash(presetId, intensity, imagePath);
}
