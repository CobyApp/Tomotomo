import 'package:flutter/material.dart';
import '../../models/chat_message.dart';
import '../../models/character.dart';
import 'chat_bubble.dart';

class ChatList extends StatelessWidget {
  final List<ChatMessage> messages;
  final Character character;
  final bool isGenerating;
  final ScrollController? scrollController;

  const ChatList({
    Key? key,
    required this.messages,
    required this.character,
    this.isGenerating = false,
    this.scrollController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: messages.length + (isGenerating ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
          );
        }

        final message = messages[index];
        return ChatBubble(
          message: message.content,
          isUser: message.isUser,
          timestamp: message.timestamp,
          character: character,
        );
      },
    );
  }
} 