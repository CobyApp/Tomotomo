/// A row from `chat_rooms` for the recent-chats list.
class ChatRoomSummary {
  final String roomId;
  final String title;
  final String? characterIdSupabase;
  final String? externalCharacterKey;
  final DateTime? lastMessageAt;

  /// `character` or `dm` (matches DB `room_type`).
  final String roomType;

  /// `chat_rooms.user_id` (for DM, lexicographically smaller participant id).
  final String roomOwnerUserId;

  /// Other participant for DM rows; null for character chats.
  final String? peerUserId;

  const ChatRoomSummary({
    required this.roomId,
    required this.title,
    this.characterIdSupabase,
    this.externalCharacterKey,
    this.lastMessageAt,
    this.roomType = 'character',
    required this.roomOwnerUserId,
    this.peerUserId,
  });

  bool get isDm => roomType == 'dm';

  /// The friend / peer in a DM room (not [currentUserId]).
  String? otherParticipantUserId(String currentUserId) {
    if (!isDm || peerUserId == null) return null;
    return currentUserId == roomOwnerUserId ? peerUserId : roomOwnerUserId;
  }

  ChatRoomSummary copyWith({String? title}) {
    return ChatRoomSummary(
      roomId: roomId,
      title: title ?? this.title,
      characterIdSupabase: characterIdSupabase,
      externalCharacterKey: externalCharacterKey,
      lastMessageAt: lastMessageAt,
      roomType: roomType,
      roomOwnerUserId: roomOwnerUserId,
      peerUserId: peerUserId,
    );
  }

  factory ChatRoomSummary.fromRow(Map<String, dynamic> row) {
    final uid = row['user_id'];
    return ChatRoomSummary(
      roomId: row['id'] as String,
      title: row['title'] as String,
      characterIdSupabase: row['character_id'] as String?,
      externalCharacterKey: row['external_character_key'] as String?,
      lastMessageAt: row['last_message_at'] != null
          ? DateTime.parse(row['last_message_at'] as String)
          : null,
      roomType: row['room_type'] as String? ?? 'character',
      roomOwnerUserId: uid is String ? uid : uid.toString(),
      peerUserId: row['peer_user_id'] as String?,
    );
  }
}
