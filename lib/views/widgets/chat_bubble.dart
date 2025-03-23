import 'package:flutter/material.dart';
import '../../models/chat_message.dart';
import '../../utils/constants.dart';
import '../../utils/bubble_animation.dart';
import '../../viewmodels/chat_viewmodel.dart';
import 'package:provider/provider.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isNew;

  const ChatBubble({Key? key, required this.message, this.isNew = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final viewModel = Provider.of<ChatViewModel>(context, listen: false);
    final memberName = isUser ? "나" : viewModel.currentMember.name;
    final memberColor = viewModel.currentMember.primaryColor;
    
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
                  memberName,
                  style: TextStyle(
                    color: memberColor, 
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                color: isUser ? memberColor : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 0),
                  bottomRight: Radius.circular(isUser ? 0 : 20),
                ),
                border: isUser 
                    ? null 
                    : Border.all(color: memberColor.withOpacity(0.7), width: 1.5),
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
                  color: isUser ? Colors.white : Colors.black87,
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