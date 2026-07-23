import 'package:flutter/material.dart';

import '../../../core/ui/paper/paper_tokens.dart';
import '../../../core/ui/paper/paper_widgets.dart';
import '../../../domain/entities/character.dart';
import '../../../domain/entities/chat_message.dart';

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
    final p = context.paper;
    // My messages get a solid coral fill; tutor messages sit on a cream card.
    const userTextColor = Colors.white;
    final botTextColor = p.ink;

    final bubbleRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isUser ? 18 : 6),
      bottomRight: Radius.circular(isUser ? 6 : 18),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            PolaroidAvatar(
              size: 36,
              rotate: -0.06,
              child: character.hasAvatar
                  ? Image(image: character.imageProvider, fit: BoxFit.cover)
                  : Center(
                      child: Text(
                        character.displayNamePrimary.isNotEmpty
                            ? character.displayNamePrimary.substring(0, 1)
                            : '?',
                        style: TextStyle(fontSize: 13, color: p.coral),
                      ),
                    ),
            ),
            const SizedBox(width: 10),
          ],
          if (isUser && onExplanationTap != null) ...[
            Material(
              color: p.stampBlue.withValues(alpha: 0.14),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onExplanationTap,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: p.ink,
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
                  // My bubble: neon magenta→cyan-ish gradient with a glow.
                  // Friend bubble: glassy card with a faint cyan neon edge.
                  gradient: isUser
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [p.coral, p.coralDeep],
                        )
                      : null,
                  color: isUser ? null : p.card,
                  borderRadius: bubbleRadius,
                  border: isUser
                      ? null
                      : Border.all(color: p.stampBlue.withValues(alpha: 0.35)),
                  boxShadow: isUser
                      ? [
                          BoxShadow(
                            color: p.coral.withValues(alpha: 0.40),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [
                          BoxShadow(color: p.hardShadow, offset: const Offset(0, 2)),
                          BoxShadow(color: p.softShadow, blurRadius: 14, offset: const Offset(0, 6)),
                          BoxShadow(
                            color: p.stampBlue.withValues(alpha: 0.10),
                            blurRadius: 12,
                          ),
                        ],
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
                      height: 1.5,
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
              color: p.stampBlue.withValues(alpha: 0.14),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onExplanationTap,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: p.ink,
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
