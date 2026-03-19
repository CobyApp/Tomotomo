/// User theme overrides stored in Supabase (public.themes).
/// All colors are optional hex strings (e.g. "FF6A3EA1" or "#FF6A3EA1").
class UserTheme {
  final String? chatBubbleUser;
  final String? chatBubbleBot;
  final String? chatBg;
  final String? accent;

  const UserTheme({
    this.chatBubbleUser,
    this.chatBubbleBot,
    this.chatBg,
    this.accent,
  });

  factory UserTheme.fromRow(Map<String, dynamic> row) {
    return UserTheme(
      chatBubbleUser: row['chat_bubble_user'] as String?,
      chatBubbleBot: row['chat_bubble_bot'] as String?,
      chatBg: row['chat_bg'] as String?,
      accent: row['accent'] as String?,
    );
  }

  Map<String, dynamic> toRow() {
    return {
      'chat_bubble_user': chatBubbleUser,
      'chat_bubble_bot': chatBubbleBot,
      'chat_bg': chatBg,
      'accent': accent,
    };
  }

  UserTheme copyWith({
    String? chatBubbleUser,
    String? chatBubbleBot,
    String? chatBg,
    String? accent,
  }) {
    return UserTheme(
      chatBubbleUser: chatBubbleUser ?? this.chatBubbleUser,
      chatBubbleBot: chatBubbleBot ?? this.chatBubbleBot,
      chatBg: chatBg ?? this.chatBg,
      accent: accent ?? this.accent,
    );
  }
}
