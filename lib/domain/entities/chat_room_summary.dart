/// A row from `chat_rooms` for the recent-chats list.
class ChatRoomSummary {
  final String roomId;
  final String title;
  /// Optional second line (other script or DM email); list UI shows below [title].
  final String? titleSecondary;
  final String? characterIdSupabase;
  final String? externalCharacterKey;
  final DateTime? lastMessageAt;

  /// `character` or `dm` (matches DB `room_type`).
  final String roomType;

  /// `chat_rooms.user_id` (for DM, lexicographically smaller participant id).
  final String roomOwnerUserId;

  /// Other participant for DM rows; null for character chats.
  final String? peerUserId;

  /// DM peer or custom character avatar (https URL).
  final String? avatarNetworkUrl;

  /// Built-in character avatar from app assets.
  final String? avatarAssetPath;

  /// Latest `chat_messages.content` for list preview (raw; UI may shorten / localize).
  final String? lastMessageContent;

  const ChatRoomSummary({
    required this.roomId,
    required this.title,
    this.titleSecondary,
    this.characterIdSupabase,
    this.externalCharacterKey,
    this.lastMessageAt,
    this.roomType = 'character',
    required this.roomOwnerUserId,
    this.peerUserId,
    this.avatarNetworkUrl,
    this.avatarAssetPath,
    this.lastMessageContent,
  });

  bool get isDm => roomType == 'dm';

  /// The friend / peer in a DM room (not [currentUserId]).
  String? otherParticipantUserId(String currentUserId) {
    if (!isDm || peerUserId == null) return null;
    return currentUserId == roomOwnerUserId ? peerUserId : roomOwnerUserId;
  }

  ChatRoomSummary copyWith({
    String? title,
    String? titleSecondary,
    String? avatarNetworkUrl,
    String? avatarAssetPath,
    String? lastMessageContent,
  }) {
    return ChatRoomSummary(
      roomId: roomId,
      title: title ?? this.title,
      titleSecondary: titleSecondary ?? this.titleSecondary,
      characterIdSupabase: characterIdSupabase,
      externalCharacterKey: externalCharacterKey,
      lastMessageAt: lastMessageAt,
      roomType: roomType,
      roomOwnerUserId: roomOwnerUserId,
      peerUserId: peerUserId,
      avatarNetworkUrl: avatarNetworkUrl ?? this.avatarNetworkUrl,
      avatarAssetPath: avatarAssetPath ?? this.avatarAssetPath,
      lastMessageContent: lastMessageContent ?? this.lastMessageContent,
    );
  }

  factory ChatRoomSummary.fromRow(Map<String, dynamic> row) {
    final uid = row['user_id'];
    return ChatRoomSummary(
      roomId: row['id'] as String,
      title: row['title'] as String,
      titleSecondary: null,
      characterIdSupabase: row['character_id'] as String?,
      externalCharacterKey: row['external_character_key'] as String?,
      lastMessageAt: row['last_message_at'] != null
          ? DateTime.parse(row['last_message_at'] as String)
          : null,
      roomType: row['room_type'] as String? ?? 'character',
      roomOwnerUserId: uid is String ? uid : uid.toString(),
      peerUserId: row['peer_user_id'] as String?,
      avatarNetworkUrl: null,
      avatarAssetPath: null,
      lastMessageContent: null,
    );
  }
}
