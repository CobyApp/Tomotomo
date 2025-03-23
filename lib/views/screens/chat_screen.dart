import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/chat_input.dart';
import '../widgets/message_list.dart';
import '../../utils/constants.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../services/ai_service.dart';

class ChatScreen extends StatefulWidget {
  final String memberId;
  
  const ChatScreen({Key? key, required this.memberId}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  void initState() {
    super.initState();
    // ViewModel 초기화 및 디버깅
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<ChatViewModel>(context, listen: false);
      viewModel.initializeForMember(widget.memberId);
      
      // 디버그: 멤버 ID와 이름 확인
      print('Widget memberId: ${widget.memberId}');
      print('ViewModel member name: ${viewModel.currentMember.name}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatViewModel>(
      builder: (context, viewModel, child) {
        final member = viewModel.currentMember;
        
        return Scaffold(
          backgroundColor: member.primaryColor.withOpacity(0.1),
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  backgroundImage: AssetImage(member.imageUrl),
                  radius: 16,
                ),
                const SizedBox(width: 8),
                Text(member.name),
              ],
            ),
            backgroundColor: member.primaryColor,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () {
                  viewModel.clearMessages();
                },
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/nmixx_background.jpg'),
                fit: BoxFit.cover,
                opacity: 0.2,
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
        );
      },
    );
  }
} 