import 'package:flutter/material.dart';
import '../../../../core/theme/chat_theme_data.dart';
import '../../../../domain/entities/character.dart';
import '../../../../domain/entities/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final Character character;
  final bool isUser;
  final VoidCallback? onExplanationTap;

  const ChatBubble({
    super.key,
    required this.message,
    required this.character,
    required this.isUser,
    this.onExplanationTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chatTheme = Theme.of(context).extension<ChatThemeData>();
    final userBubbleColor = chatTheme?.userBubble ?? scheme.primary;
    final botBubbleColor = chatTheme?.botBubble ?? scheme.surfaceContainerHigh;

    final userTextColor =
        userBubbleColor.computeLuminance() > 0.55 ? scheme.onSurface : Colors.white;
    final botTextColor = scheme.onSurface;

    final bubbleRadius = BorderRadius.only(
      topLeft: const Radius.circular(22),
      topRight: const Radius.circular(22),
      bottomLeft: Radius.circular(isUser ? 22 : 6),
      bottomRight: Radius.circular(isUser ? 6 : 22),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: scheme.surfaceContainerHighest,
              backgroundImage: character.hasAvatar ? character.imageProvider : null,
              child: !character.hasAvatar
                  ? Text(
                      character.name.isNotEmpty ? character.name.substring(0, 1) : '?',
                      style: TextStyle(fontSize: 13, color: scheme.primary),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                color: isUser ? userBubbleColor : botBubbleColor,
                borderRadius: bubbleRadius,
                border: isUser
                    ? null
                    : Border.all(color: scheme.outlineVariant.withValues(alpha: 0.45)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  message.content,
                  style: TextStyle(
                    fontSize: 15.5,
                    height: 1.45,
                    color: isUser ? userTextColor : botTextColor,
                  ),
                ),
              ),
            ),
          ),
          if (!isUser && onExplanationTap != null) ...[
            const SizedBox(width: 6),
            Material(
              color: scheme.primaryContainer.withValues(alpha: 0.5),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onExplanationTap,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(Icons.info_outline_rounded, size: 18, color: scheme.primary),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
