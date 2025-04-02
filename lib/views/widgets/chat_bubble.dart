import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../models/character.dart';
import '../../models/chat_message.dart';
import '../../utils/date_formatter.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final Character character;
  final bool isUser;
  final VoidCallback? onExplanationTap;

  const ChatBubble({
    Key? key,
    required this.message,
    required this.character,
    required this.isUser,
    this.onExplanationTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundImage: AssetImage(character.imagePath),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser 
                      ? _getLevelColor(character.level).withOpacity(0.1)
                      : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isUser 
                        ? _getLevelColor(character.level).withOpacity(0.2)
                        : Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: MarkdownBody(
                    data: message.content,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        color: isUser ? Colors.black87 : Colors.black87,
                        fontSize: 15,
                        height: 1.5,
                      ),
                      code: TextStyle(
                        backgroundColor: isUser 
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey.shade100,
                        color: Colors.black87,
                        fontSize: 14,
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: isUser 
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
              if (isUser) const SizedBox(width: 40),
            ],
          ),
          if (!isUser && onExplanationTap != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: TextButton.icon(
                onPressed: onExplanationTap,
                icon: Icon(
                  Icons.help_outline_rounded,
                  size: 16,
                  color: _getLevelColor(character.level).withOpacity(0.7),
                ),
                label: Text(
                  '표현 설명',
                  style: TextStyle(
                    fontSize: 13,
                    color: _getLevelColor(character.level).withOpacity(0.7),
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case '초급':
        return const Color(0xFF4CAF50);
      case '중급':
        return const Color(0xFF2196F3);
      case '고급':
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFF2196F3);
    }
  }
} 