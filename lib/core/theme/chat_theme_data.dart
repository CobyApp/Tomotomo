import 'package:flutter/material.dart';

/// Chat-specific colors (bubbles, background) from user theme. Use via Theme.of(context).extension<ChatThemeData>().
class ChatThemeData extends ThemeExtension<ChatThemeData> {
  final Color? userBubble;
  final Color? botBubble;
  final Color? chatBg;

  const ChatThemeData({
    this.userBubble,
    this.botBubble,
    this.chatBg,
  });

  static Color _parseHex(String hex) {
    String s = hex.startsWith('#') ? hex.substring(1) : hex;
    if (s.length == 6) s = 'FF$s';
    return Color(int.parse(s, radix: 16));
  }

  static ChatThemeData fromUserTheme({
    String? chatBubbleUser,
    String? chatBubbleBot,
    String? chatBg,
  }) {
    return ChatThemeData(
      userBubble: chatBubbleUser != null && chatBubbleUser.isNotEmpty
          ? _parseHex(chatBubbleUser)
          : null,
      botBubble: chatBubbleBot != null && chatBubbleBot.isNotEmpty
          ? _parseHex(chatBubbleBot)
          : null,
      chatBg: chatBg != null && chatBg.isNotEmpty ? _parseHex(chatBg) : null,
    );
  }

  @override
  ChatThemeData copyWith({Color? userBubble, Color? botBubble, Color? chatBg}) {
    return ChatThemeData(
      userBubble: userBubble ?? this.userBubble,
      botBubble: botBubble ?? this.botBubble,
      chatBg: chatBg ?? this.chatBg,
    );
  }

  @override
  ChatThemeData lerp(covariant ChatThemeData? other, double t) {
    if (other == null) return this;
    return ChatThemeData(
      userBubble: Color.lerp(userBubble, other.userBubble, t),
      botBubble: Color.lerp(botBubble, other.botBubble, t),
      chatBg: Color.lerp(chatBg, other.chatBg, t),
    );
  }
}
