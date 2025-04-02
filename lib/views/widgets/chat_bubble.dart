import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../models/character.dart';
import '../../models/chat_message.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                          fontFamily: 'Pretendard',
                        ),
                        code: TextStyle(
                          backgroundColor: isUser 
                            ? Colors.white.withOpacity(0.7)
                            : Colors.grey.shade100,
                          color: Colors.black87,
                          fontSize: 14,
                          fontFamily: 'Pretendard',
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
              ),
              if (isUser) const SizedBox(width: 8),
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

  Widget _buildUserBubble(BuildContext context, ChatMessage message) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(left: 64, bottom: 8, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF6A3EA1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.content,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            height: 1.4,
            fontFamily: 'Pretendard',
          ),
        ),
      ),
    );
  }

  Widget _buildAIBubble(BuildContext context, ChatMessage message) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(right: 64, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
                height: 1.4,
                fontFamily: 'Pretendard',
              ),
            ),
            if (message.explanation != null) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _showExplanation(context, message),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6A3EA1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: const Color(0xFF6A3EA1),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '표현 설명',
                        style: TextStyle(
                          fontSize: 13,
                          color: const Color(0xFF6A3EA1),
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showExplanation(BuildContext context, ChatMessage message) {
    final levelColor = _getLevelColor(character.level);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: levelColor.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: levelColor),
                  const SizedBox(width: 12),
                  Text(
                    '표현 설명',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: levelColor,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI의 답변',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[700],
                      height: 1.5,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '표현 설명',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message.explanation!,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[700],
                      height: 1.5,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 