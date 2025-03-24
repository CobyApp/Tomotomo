import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/chat_input.dart';
import '../widgets/message_list.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../utils/constants.dart';
import '../../viewmodels/settings_viewmodel.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

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
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ChatViewModel>(context);
    final settingsVM = Provider.of<SettingsViewModel>(context);
    final character = viewModel.currentMember;

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        return false;
      },
      child: Scaffold(
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
                  character.primaryColor,
                  HSLColor.fromColor(character.primaryColor)
                      .withLightness(
                          HSLColor.fromColor(character.primaryColor).lightness * 1.2)
                      .toColor(),
                ],
              ),
            ),
          ),
          leading: ScaleTransition(
            scale: _animation,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: Row(
            children: [
              CircleAvatar(
                backgroundImage: AssetImage(character.imageUrl),
                radius: 16,
              ),
              const SizedBox(width: 8),
              Text(character.getName(settingsVM.currentLanguage.code)),
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
                  character.imageUrl,
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
                      character.primaryColor.withOpacity(0.1),
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
                  Expanded(
                    child: MessageList(),
                  ),
                  ChatInput(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 