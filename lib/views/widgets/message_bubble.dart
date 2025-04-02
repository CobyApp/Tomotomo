import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../models/character.dart';
import '../../models/chat_message.dart';
import '../../utils/date_formatter.dart';

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final DateTime timestamp;
  final Character character;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isUser,
    required this.timestamp,
    required this.character,
  }) : super(key: key);

  Color _getLevelColor() {
    switch (character.level) {
      case '초급':
        return const Color(0xFF4CAF50); // 초록색
      case '중급':
        return const Color(0xFF2196F3); // 파란색
      case '고급':
        return const Color(0xFF9C27B0); // 보라색
      default:
        return const Color(0xFF2196F3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final levelColor = _getLevelColor();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: isUser 
                  ? levelColor
                  : const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(24),
                  topRight: const Radius.circular(24),
                  bottomLeft: Radius.circular(isUser ? 24 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isUser ? levelColor : Colors.black).withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: isUser 
                  ? null 
                  : Border.all(
                      color: const Color(0xFFE9ECEF),
                      width: 1.0,
                    ),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  textSelectionTheme: TextSelectionThemeData(
                    selectionColor: isUser 
                      ? levelColor.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.2),
                  ),
                ),
                child: MarkdownBody(
                  data: message,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                    p: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 16,
                      height: 1.6,
                      fontWeight: isUser ? FontWeight.w600 : FontWeight.w400,
                      letterSpacing: 0.3,
                    ),
                    blockquoteDecoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    blockquote: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 16,
                      height: 1.6,
                      fontWeight: isUser ? FontWeight.w600 : FontWeight.w400,
                      letterSpacing: 0.3,
                    ),
                    code: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 14,
                      fontFamily: 'monospace',
                      fontWeight: isUser ? FontWeight.w600 : FontWeight.w400,
                      letterSpacing: 0.3,
                    ),
                    codeblockDecoration: null,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 