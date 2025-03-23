import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/chat_input.dart';
import '../widgets/message_list.dart';
import '../../utils/constants.dart';
import '../../viewmodels/chat_viewmodel.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI Chat'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // 메시지 초기화 직접 수행
              Provider.of<ChatViewModel>(context, listen: false).clearMessages();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: const [  // const 유지
            Expanded(
              child: MessageList(),
            ),
            ChatInput(),
          ],
        ),
      ),
      resizeToAvoidBottomInset: true,
    );
  }
} 