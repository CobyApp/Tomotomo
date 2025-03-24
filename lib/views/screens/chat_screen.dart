import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/chat_input.dart';
import '../widgets/message_list.dart';
import '../../models/character.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../utils/constants.dart';
import '../../viewmodels/settings_viewmodel.dart';
import '../../utils/app_theme.dart';
import '../../utils/localization.dart';
import '../widgets/character_profile_dialog.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

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
      _scrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChatViewModel>();
    final character = viewModel.character;
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              character.primaryColor.withOpacity(0.15),
              Colors.white.withOpacity(0.95),
            ],
          ),
          image: DecorationImage(
            image: AssetImage('assets/images/patterns/moe_pattern.png'),
            opacity: 0.03,
            repeat: ImageRepeat.repeat,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, character, theme),
              Expanded(
                child: MessageList(
                  messages: viewModel.messages,
                  character: character,
                  isGenerating: viewModel.isGenerating,
                  scrollController: _scrollController,
                ),
              ),
              ChatInput(
                onSendMessage: (message) {
                  viewModel.sendMessage(message);
                  _scrollToBottom();
                },
                character: character,
                isGenerating: viewModel.isGenerating,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, Character character, ThemeData theme) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new),
        color: character.primaryColor,
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          GestureDetector(
            onTap: () => _showCharacterProfile(context, character),
            child: Hero(
              tag: 'character_${character.id}',
              child: CircleAvatar(
                radius: 18,
                backgroundImage: AssetImage(character.imageUrl),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            character.name,
            style: TextStyle(
              fontFamily: 'Quicksand',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          color: character.primaryColor,
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('채팅 초기화'),
                content: Text('대화 내용이 모두 삭제됩니다.\n정말 초기화하시겠습니까?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      '취소',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.read<ChatViewModel>().resetChat();
                      Navigator.pop(context);
                    },
                    child: Text(
                      '초기화',
                      style: TextStyle(color: character.primaryColor),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
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
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showCharacterProfile(BuildContext context, Character character) {
    showDialog(
      context: context,
      builder: (context) => CharacterProfileDialog(character: character),
    );
  }
} 