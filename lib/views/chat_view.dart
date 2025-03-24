import 'package:flutter/material.dart';

class ChatView extends StatefulWidget {
  // ... (existing code)

  @override
  _ChatViewState createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 화면이 처음 로드될 때 스크롤
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,  // 스크롤 컨트롤러 추가
              // ... existing ListView.builder code ...
            ),
          ),
          ChatInput(
            hintText: "메시지를 입력하세요",
            primaryColor: // your primary color,
            onSendMessage: (message) {
              // your message handling code
            },
            onMessageSent: _scrollToBottom,  // 스크롤 콜백 전달
          ),
        ],
      ),
    );
  }
} 