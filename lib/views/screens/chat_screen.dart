import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/chat_input.dart';
import '../widgets/message_list.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../utils/constants.dart';

class ChatScreen extends StatefulWidget {
  final String memberId;
  
  const ChatScreen({Key? key, required this.memberId}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<ChatViewModel>(context, listen: false);
      viewModel.initializeForMember(widget.memberId);
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatViewModel>(
      builder: (context, viewModel, child) {
        final member = viewModel.currentMember;
        
        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            titleSpacing: 0,
            elevation: 0,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    member.primaryColor,
                    HSLColor.fromColor(member.primaryColor)
                        .withLightness(
                            HSLColor.fromColor(member.primaryColor).lightness * 1.2)
                        .toColor(),
                  ],
                ),
              ),
            ),
            leading: ScaleTransition(
              scale: _animation,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    backgroundImage: AssetImage(member.imageUrl),
                    radius: 18,
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
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        member.description,
                        style: const TextStyle(
                          fontFamily: 'Quicksand',
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
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
                tooltip: '채팅 초기화',
                onPressed: () => viewModel.clearMessages(),
              ),
            ],
          ),
          body: Stack(
            children: [
              // 배경 이미지
              Positioned.fill(
                child: Opacity(
                  opacity: 0.25,
                  child: Image.asset(
                    member.imageUrl,
                    fit: BoxFit.cover,
                  ),
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
                        member.primaryColor.withOpacity(0.1),
                        Colors.white.withOpacity(0.8),
                        Colors.white.withOpacity(0.95),
                      ],
                    ),
                  ),
                ),
              ),
              
              // 채팅 내용
              SafeArea(
                bottom: false,
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