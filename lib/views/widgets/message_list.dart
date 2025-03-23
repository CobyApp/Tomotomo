import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'chat_bubble.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../models/chat_message.dart';

class MessageList extends StatelessWidget {
  const MessageList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Selector<ChatViewModel, List<ChatMessage>>(
      selector: (_, model) => model.messages,
      shouldRebuild: (prev, next) => true, // 항상 다시 빌드
      builder: (context, messages, _) {
        // 빈 화면 체크 제거 - 항상 메시지 리스트 표시
        return ListView.separated(
          reverse: true,
          padding: EdgeInsets.only(
            left: 8,
            right: 8,
            top: 8,
            bottom: MediaQuery.of(context).padding.bottom + 8,
          ),
          physics: const BouncingScrollPhysics(),
          itemCount: messages.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final reversedIndex = messages.length - 1 - index;
            final message = messages[reversedIndex];
            return ChatBubble(
              key: ValueKey('message_${message.timestamp.millisecondsSinceEpoch}'),
              message: message,
              isNew: index == 0,
            );
          },
        );
      },
    );
  }
} 