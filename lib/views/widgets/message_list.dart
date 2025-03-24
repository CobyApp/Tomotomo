import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/character.dart';
import '../../models/chat_message.dart';
import './dot_indicator.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../utils/constants.dart';
import '../../viewmodels/settings_viewmodel.dart';
// import 'package:intl/intl.dart';  // 주석 처리

class MessageList extends StatelessWidget {
  final List<ChatMessage> messages;
  final Character character;
  final bool isGenerating;
  final ScrollController scrollController;

  const MessageList({
    Key? key,
    required this.messages,
    required this.character,
    required this.isGenerating,
    required this.scrollController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: messages.length + (isGenerating ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length) {
          return _buildTypingIndicator();
        }
        
        final message = messages[index];
        final isLastMessage = index == messages.length - 1;
        
        return Padding(
          padding: EdgeInsets.only(bottom: isLastMessage ? 8 : 12),
          child: message.isUser
              ? _buildUserMessage(context, message)
              : _buildCharacterMessage(context, message),
        );
      },
    );
  }

  Widget _buildUserMessage(BuildContext context, ChatMessage message) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 280),
          margin: const EdgeInsets.only(left: 40),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: character.primaryColor.withOpacity(0.9),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: character.primaryColor.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            message.message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCharacterMessage(BuildContext context, ChatMessage message) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: character.primaryColor,
              width: 1.5,
            ),
            image: DecorationImage(
              image: AssetImage(character.imageUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Flexible(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 280),
            margin: const EdgeInsets.only(right: 40),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              message.message,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: character.primaryColor,
              width: 1.5,
            ),
            image: DecorationImage(
              image: AssetImage(character.imageUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) => 
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: DotIndicator(
                  color: character.primaryColor,
                  delay: Duration(milliseconds: 300 * index),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
} 