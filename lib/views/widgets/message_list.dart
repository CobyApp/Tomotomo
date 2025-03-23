import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'chat_bubble.dart';
import '../../viewmodels/chat_viewmodel.dart';

class MessageList extends StatelessWidget {
  const MessageList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatViewModel>(
      builder: (context, viewModel, child) {
        return ListView.builder(
          padding: EdgeInsets.only(
            left: 8,
            right: 8,
            top: 8,
            bottom: MediaQuery.of(context).padding.bottom + 8,
          ),
          reverse: true,
          physics: const BouncingScrollPhysics(),
          itemCount: viewModel.messages.length,
          itemBuilder: (context, index) {
            final message = viewModel.messages[viewModel.messages.length - 1 - index];
            return ChatBubble(
              message: message,
              isNew: index == 0 && viewModel.messages.isNotEmpty,
            );
          },
        );
      },
    );
  }
} 