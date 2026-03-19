import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/chat_theme_data.dart';
import '../../domain/entities/character.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/repositories/ai_chat_repository.dart';
import 'chat_viewmodel.dart';
import 'widgets/chat_list.dart';
import 'widgets/chat_input.dart';

class ChatScreen extends StatefulWidget {
  final Character character;
  final ChatRepository chatRepository;
  final AiChatRepository aiChatRepository;

  const ChatScreen({
    super.key,
    required this.character,
    required this.chatRepository,
    required this.aiChatRepository,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _controller;
  final ScrollController _scrollController = ScrollController();
  late final ChatViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ChatViewModel(
      character: widget.character,
      chatRepository: widget.chatRepository,
      aiChatRepository: widget.aiChatRepository,
    );
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    if (mounted) _scrollToBottom();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && mounted) {
      _viewModel.onAppResumedSync();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ChatViewModel>.value(
      value: _viewModel,
      child: Consumer<ChatViewModel>(
        builder: (context, viewModel, child) {
          return _ChatScreenContent(
            character: widget.character,
            scrollController: _scrollController,
            chatRoomId: viewModel.chatRoomId,
            onResetPressed: (context) => _showResetDialog(context, viewModel),
          );
        },
      ),
    );
  }

  void _showResetDialog(BuildContext context, ChatViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: widget.character.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.refresh,
                  size: 36,
                  color: widget.character.primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '대화 초기화',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: widget.character.primaryColor,
                  fontFamily: 'Pretendard',
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '삭제된 대화는 복구할 수 없습니다',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.4,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      '취소',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600], fontFamily: 'Pretendard'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _resetChat(context, viewModel);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.character.primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text(
                      '초기화',
                      style: TextStyle(fontSize: 16, color: Colors.white, fontFamily: 'Pretendard'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resetChat(BuildContext context, ChatViewModel viewModel) {
    viewModel.resetChat();
    _scrollToBottom();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.character.primaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                '대화가 초기화되었습니다',
                style: TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Pretendard'),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 96, left: 16, right: 16),
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
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _controller.dispose();
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

class _ChatScreenContent extends StatelessWidget {
  final Character character;
  final ScrollController scrollController;
  final String? chatRoomId;
  final Function(BuildContext) onResetPressed;

  const _ChatScreenContent({
    required this.character,
    required this.scrollController,
    required this.chatRoomId,
    required this.onResetPressed,
  });

  void _scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chatTheme = Theme.of(context).extension<ChatThemeData>();
    final chatBg =
        chatTheme?.chatBg ?? (Color.lerp(scheme.surfaceContainerLow, scheme.primary, 0.04) ?? scheme.surfaceContainerLow);

    return Scaffold(
      backgroundColor: chatBg,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: scheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: scheme.surfaceContainerHighest,
              backgroundImage: character.hasAvatar ? character.imageProvider : null,
              child: !character.hasAvatar
                  ? Text(
                      character.name.isNotEmpty ? character.name.substring(0, 1) : '?',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: scheme.primary),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    character.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    character.nameJp,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (!character.isDirectMessage)
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: scheme.primary),
              onPressed: () => onResetPressed(context),
            ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            Expanded(
              child: Consumer<ChatViewModel>(
                builder: (context, viewModel, child) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                  return ChatList(
                    messages: viewModel.messages,
                    character: character,
                    isGenerating: viewModel.isGenerating,
                    scrollController: scrollController,
                    chatRoomId: chatRoomId,
                  );
                },
              ),
            ),
            Consumer<ChatViewModel>(
              builder: (context, viewModel, child) {
                return ChatInput(
                  controller: viewModel.messageController,
                  onSend: () {
                    if (viewModel.messageController.text.trim().isNotEmpty) {
                      viewModel.sendMessage();
                    }
                  },
                  isGenerating: viewModel.isGenerating,
                  character: character,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
