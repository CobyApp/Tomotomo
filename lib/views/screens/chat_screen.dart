import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/chat_list.dart';
import '../widgets/chat_bubble.dart';
import '../../models/character.dart';
import '../../services/chat_storage.dart';
import '../../services/ai_service.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../widgets/chat_input.dart';

class ChatScreen extends StatefulWidget {
  final Character character;
  final ChatStorage chatStorage;
  final AIService aiService;
  
  const ChatScreen({
    Key? key,
    required this.character,
    required this.chatStorage,
    required this.aiService,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final ScrollController _scrollController = ScrollController();

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
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollToBottom();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatViewModel(
        character: widget.character,
        chatStorage: widget.chatStorage,
        aiService: widget.aiService,
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: AssetImage(widget.character.imagePath),
              ),
              const SizedBox(width: 12),
              Text(
                widget.character.name,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Pretendard',
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black54),
              onPressed: () => _showResetConfirmation(context),
            ),
          ],
        ),
        body: Container(
          color: const Color(0xFFF8F9FA),
          child: Column(
            children: [
              Expanded(
                child: Consumer<ChatViewModel>(
                  builder: (context, viewModel, child) {
                    return ChatList(
                      messages: viewModel.messages,
                      character: widget.character,
                      isGenerating: viewModel.isGenerating,
                    );
                  },
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Consumer<ChatViewModel>(
                  builder: (context, viewModel, child) {
                    return ChatInput(
                      controller: viewModel.messageController,
                      onSend: () {
                        if (viewModel.messageController.text.trim().isNotEmpty) {
                          viewModel.sendMessage();
                        }
                      },
                      isGenerating: viewModel.isGenerating,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case '초급':
        return const Color(0xFF4CAF50);
      case '중급':
        return const Color(0xFF2196F3);
      case '고급':
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFF2196F3);
    }
  }

  void _showResetConfirmation(BuildContext context) {
    final levelColor = _getLevelColor(widget.character.level);
    final viewModel = context.read<ChatViewModel>();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_rounded,
              color: levelColor.withOpacity(0.8),
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text(
              '대화 초기화',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '모든 대화 내용이 삭제됩니다.\n계속하시겠습니까?',
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '삭제된 대화는 복구할 수 없습니다',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              '취소',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              viewModel.resetChat();
              Navigator.pop(dialogContext);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Text('대화가 초기화되었습니다'),
                    ],
                  ),
                  backgroundColor: levelColor.withOpacity(0.9),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.all(16),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              '초기화',
              style: TextStyle(
                color: levelColor,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      ),
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollToBottom();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
} 