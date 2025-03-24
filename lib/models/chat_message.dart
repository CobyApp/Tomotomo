class ChatMessage {
  final String message;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessage({
    required this.message,
    required this.isUser,
    required this.timestamp,
  });
} 