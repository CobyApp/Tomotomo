/// Immutable per-room chat background selection.
///
/// [presetId] references an entry in the preset catalog
/// (see `chat_background_presets.dart`); [intensity] (0.0–1.0) controls how
/// strong the color wash is over the base paper background.
class ChatBackground {
  const ChatBackground({required this.presetId, required this.intensity});

  /// Neutral default: the normal paper background at a moderate wash.
  /// The 'paper' preset renders as the plain paper surface regardless of
  /// intensity, so this is effectively "no custom background".
  const ChatBackground.defaultBg() : presetId = 'paper', intensity = 0.45;

  final String presetId;

  /// Wash strength, clamped to 0.0–1.0.
  final double intensity;

  ChatBackground copyWith({String? presetId, double? intensity}) {
    return ChatBackground(
      presetId: presetId ?? this.presetId,
      intensity: intensity ?? this.intensity,
    );
  }

  Map<String, dynamic> toJson() => {
    'presetId': presetId,
    'intensity': intensity,
  };

  factory ChatBackground.fromJson(Map<String, dynamic> json) {
    final rawIntensity = (json['intensity'] as num?)?.toDouble() ?? 0.45;
    return ChatBackground(
      presetId: json['presetId']?.toString() ?? 'paper',
      intensity: rawIntensity.clamp(0.0, 1.0),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ChatBackground &&
      other.presetId == presetId &&
      other.intensity == intensity;

  @override
  int get hashCode => Object.hash(presetId, intensity);
}
