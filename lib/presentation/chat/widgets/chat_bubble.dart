import 'package:flutter/material.dart';

import '../../../../core/theme/chat_theme_data.dart';
import '../../../../domain/entities/character.dart';
import '../../../../domain/entities/chat_message.dart';
import '../../locale/l10n_context.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final Character character;
  final bool isUser;
  final VoidCallback? onExplanationTap;
  /// Long-press the bubble to open report confirmation (optional).
  final VoidCallback? onLongPressReport;

  const ChatBubble({
    super.key,
    required this.message,
    required this.character,
    required this.isUser,
    this.onExplanationTap,
    this.onLongPressReport,
  });

  @override
  Widget build(BuildContext context) {
    final voiceUrl = DmVoiceMessage.parsePublicUrl(message.content);
    if (voiceUrl != null) {
      return _DmVoiceBubbleRow(
        character: character,
        isUser: isUser,
        onLongPressReport: onLongPressReport,
      );
    }

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
                      character.displayNamePrimary.isNotEmpty ? character.displayNamePrimary.substring(0, 1) : '?',
                      style: TextStyle(fontSize: 13, color: scheme.primary),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
          ],
          if (isUser && onExplanationTap != null) ...[
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
            const SizedBox(width: 6),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: onLongPressReport,
              behavior: HitTestBehavior.opaque,
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

/// Legacy DM voice clip row: label only (playback removed).
class _DmVoiceBubbleRow extends StatelessWidget {
  final Character character;
  final bool isUser;
  final VoidCallback? onLongPressReport;

  const _DmVoiceBubbleRow({
    required this.character,
    required this.isUser,
    this.onLongPressReport,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chatTheme = Theme.of(context).extension<ChatThemeData>();
    final userBubbleColor = chatTheme?.userBubble ?? scheme.primary;
    final botBubbleColor = chatTheme?.botBubble ?? scheme.surfaceContainerHigh;
    final bubbleColor = isUser ? userBubbleColor : botBubbleColor;
    final fg = bubbleColor.computeLuminance() > 0.55 ? scheme.onSurface : Colors.white;

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
                      character.displayNamePrimary.isNotEmpty
                          ? character.displayNamePrimary.substring(0, 1)
                          : '?',
                      style: TextStyle(fontSize: 13, color: scheme.primary),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
          ],
          GestureDetector(
            onLongPress: onLongPressReport,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bubbleColor,
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.graphic_eq_rounded, color: fg.withValues(alpha: 0.85), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    context.tr('dmVoiceMessageLabel'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
