/// Summary of a locally stored character chat.
class ChatRoomSummary {
  const ChatRoomSummary({
    required this.roomId,
    required this.title,
    this.lastMessageAt,
    this.avatarNetworkUrl,
    this.avatarAssetPath,
    this.lastMessageContent,
  });

  final String roomId;
  final String title;
  final DateTime? lastMessageAt;
  final String? avatarNetworkUrl;
  final String? avatarAssetPath;
  final String? lastMessageContent;
}
