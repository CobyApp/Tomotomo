import 'package:flutter/material.dart';
import '../../models/chat_message.dart';
import '../../utils/constants.dart';
import '../../utils/bubble_animation.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isNew;

  const ChatBubble({Key? key, required this.message, this.isNew = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    
    return BubbleAnimation(
      isNew: isNew,
      child: Container(
        margin: EdgeInsets.only(
          top: 8,
          bottom: 8,
          left: isUser ? 64 : 8,
          right: isUser ? 8 : 64,
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isUser) 
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 4),
                child: Text(
                  '럭키비키',
                  style: TextStyle(
                    color: AppColors.primaryDark, 
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                color: isUser ? AppColors.userBubble : AppColors.botBubble,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 0),
                  bottomRight: Radius.circular(isUser ? 0 : 20),
                ),
                border: isUser 
                    ? null 
                    : Border.all(color: AppColors.botBubbleBorder, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                message.message,
                style: TextStyle(
                  color: isUser ? AppColors.userBubbleText : AppColors.botBubbleText,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 