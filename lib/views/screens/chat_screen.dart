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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/crown.png',  // 왕관 아이콘 이미지 추가 필요
              height: 24,
              width: 24,
            ),
            const SizedBox(width: 8),
            const Text('럭키비키와 대화'),
            const SizedBox(width: 8),
            Image.asset(
              'assets/images/crown.png',  // 왕관 아이콘 이미지 추가 필요
              height: 24,
              width: 24,
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              Provider.of<ChatViewModel>(context, listen: false).clearMessages();
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'), // 배경 이미지 추가 필요
            fit: BoxFit.cover,
            opacity: 0.1,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: const [
              Expanded(
                child: MessageList(),
              ),
              ChatInput(),
            ],
          ),
        ),
      ),
      resizeToAvoidBottomInset: true,
    );
  }
} 