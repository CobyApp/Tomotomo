import 'package:flutter/material.dart';

import '../../../../core/ui/holo/holo_tokens.dart';
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

    // HOLO-KITSCH bubbles: my messages get the holo gradient fill; tutor/AI
    // messages get a white card with a cyan hairline border.
    final userTextColor = Colors.white;
    const botTextColor = Holo.inkPlum;

    final bubbleRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isUser ? 18 : 6),
      bottomRight: Radius.circular(isUser ? 6 : 18),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: Holo.surfaceCard,
              backgroundImage: character.hasAvatar
                  ? character.imageProvider
                  : null,
              child: !character.hasAvatar
                  ? Text(
                      character.displayNamePrimary.isNotEmpty
                          ? character.displayNamePrimary.substring(0, 1)
                          : '?',
                      style: const TextStyle(fontSize: 13, color: Holo.pink),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
          ],
          if (isUser && onExplanationTap != null) ...[
            Material(
              color: Holo.lilac.withValues(alpha: 0.25),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onExplanationTap,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: Holo.inkPlum,
                  ),
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
                  gradient: isUser ? Holo.holoGradient : null,
                  color: isUser ? null : Holo.surfaceCard,
                  borderRadius: bubbleRadius,
                  border: isUser
                      ? null
                      : Border.all(color: Holo.cyan, width: 2),
                  boxShadow: Holo.cardShadow,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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
              color: Holo.lilac.withValues(alpha: 0.25),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onExplanationTap,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: Holo.inkPlum,
                  ),
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
    final fg = isUser ? Colors.white : Holo.inkPlum;

    final bubbleRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isUser ? 18 : 6),
      bottomRight: Radius.circular(isUser ? 6 : 18),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: Holo.surfaceCard,
              backgroundImage: character.hasAvatar
                  ? character.imageProvider
                  : null,
              child: !character.hasAvatar
                  ? Text(
                      character.displayNamePrimary.isNotEmpty
                          ? character.displayNamePrimary.substring(0, 1)
                          : '?',
                      style: const TextStyle(fontSize: 13, color: Holo.pink),
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
                gradient: isUser ? Holo.holoGradient : null,
                color: isUser ? null : Holo.surfaceCard,
                borderRadius: bubbleRadius,
                border: isUser ? null : Border.all(color: Holo.cyan, width: 2),
                boxShadow: Holo.cardShadow,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.graphic_eq_rounded,
                    color: fg.withValues(alpha: 0.85),
                    size: 22,
                  ),
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
