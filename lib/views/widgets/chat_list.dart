import 'package:flutter/material.dart';
import '../../models/chat_message.dart';
import '../../models/character.dart';
import 'chat_bubble.dart';

class ChatList extends StatelessWidget {
  final List<ChatMessage> messages;
  final Character character;
  final bool isGenerating;
  final ScrollController scrollController;

  const ChatList({
    Key? key,
    required this.messages,
    required this.character,
    required this.isGenerating,
    required this.scrollController,
  }) : super(key: key);

  void _showExplanation(BuildContext context, ChatMessage message) {
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
                color: character.primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: character.primaryColor),
                  const SizedBox(width: 12),
                  Text(
                    '표현 설명',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: character.primaryColor,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        message.content,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: Colors.grey[800],
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (message.explanation != null) ...[
                      Text(
                        message.explanation!,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: Colors.grey[700],
                          fontFamily: 'Pretendard',
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (message.vocabulary != null && message.vocabulary!.isNotEmpty) ...[
                      ...message.vocabulary!.map((vocab) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              children: [
                                Text(
                                  vocab.word,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                if (vocab.reading != null && vocab.reading!.isNotEmpty)
                                  Text(
                                    '(${vocab.reading})',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              vocab.meaning,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: messages.length + (isGenerating ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: character.primaryColor.withOpacity(0.2),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: character.primaryColor.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundImage: AssetImage(character.imagePath),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLoadingDot(0),
                      const SizedBox(width: 8),
                      _buildLoadingDot(1),
                      const SizedBox(width: 8),
                      _buildLoadingDot(2),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final message = messages[index];
        final isUser = message.role == 'user';

        return ChatBubble(
          message: message,
          character: character,
          isUser: isUser,
          onExplanationTap: !isUser ? () => _showExplanation(context, message) : null,
        );
      },
    );
  }

  Widget _buildLoadingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        final delay = index * 0.2;
        final opacity = (value + delay) % 1.0;
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: character.primaryColor.withOpacity(opacity * 0.8),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
} 