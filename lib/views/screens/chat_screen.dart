import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/chat_input.dart';
import '../widgets/message_list.dart';
import '../../viewmodels/chat_viewmodel.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<ChatViewModel>(context, listen: false);
      viewModel.initializeForMember(widget.memberId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatViewModel>(
      builder: (context, viewModel, child) {
        final member = viewModel.currentMember;
        
        return Scaffold(
          backgroundColor: Colors.white,
          // 기본 앱바 사용
          appBar: AppBar(
            backgroundColor: member.primaryColor,
            elevation: 4,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    member.primaryColor,
                    member.primaryColor.withOpacity(0.8),
                    HSLColor.fromColor(member.primaryColor).withLightness(
                      HSLColor.fromColor(member.primaryColor).lightness * 1.2
                    ).toColor(),
                  ],
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
              onPressed: () => Navigator.pop(context),
            ),
            titleSpacing: 0,
            title: Row(
              children: [
                Hero(
                  tag: 'member-${member.id}',
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundImage: AssetImage(member.imageUrl),
                      radius: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        member.name,
                        style: const TextStyle(
                          fontFamily: 'Quicksand',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        member.description,
                        style: const TextStyle(
                          fontFamily: 'Quicksand',
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.refresh_rounded, 
                  color: Colors.white,
                ),
                onPressed: () => viewModel.clearMessages(),
              ),
            ],
          ),
          // 배경과 콘텐츠 레이어 구성
          body: Stack(
            children: [
              // 배경 이미지
              Positioned.fill(
                child: Image.asset(
                  member.imageUrl,
                  fit: BoxFit.cover,
                  opacity: const AlwaysStoppedAnimation(0.15),
                ),
              ),
              // 그래디언트 오버레이
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        member.primaryColor.withOpacity(0.05),
                        Colors.white.withOpacity(0.92),
                        Colors.white,
                      ],
                    ),
                  ),
                ),
              ),
              // 채팅 내용
              SafeArea(
                bottom: false, // 하단은 채팅 입력창 때문에 제외
                child: Column(
                  children: [
                    const Expanded(
                      child: MessageList(),
                    ),
                    ChatInput(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 