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
  // 화면을 강제로 다시 그리기 위한 키
  Key _contentKey = UniqueKey();

  void _refreshScreen() {
    setState(() {
      _contentKey = UniqueKey();
    });
  }

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
              // 메시지 초기화
              context.read<ChatViewModel>().clearMessages();
              // 화면 갱신
              _refreshScreen();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          key: _contentKey, // 키를 통해 전체 컨텐츠를 갱신
          children: const [
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