import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../utils/constants.dart';
import '../../viewmodels/settings_viewmodel.dart';

class ChatInput extends StatefulWidget {
  const ChatInput({Key? key}) : super(key: key);

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  void _sendMessage(BuildContext context, ChatViewModel viewModel) {
    final text = _controller.text.trim();
    if (text.isNotEmpty && !viewModel.isGenerating) {
      viewModel.sendMessage(text);
      _controller.clear();
      _animationController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ChatViewModel, SettingsViewModel>(
      builder: (context, viewModel, settingsVM, child) {
        final memberColor = viewModel.currentMember.primaryColor;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: '메시지를 입력하세요...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  maxLines: null,  // 여러 줄 입력 가능
                  textInputAction: TextInputAction.send,
                  onChanged: (text) {
                    // 텍스트가 입력되면 애니메이션 시작
                    if (text.isNotEmpty && !_animationController.isCompleted) {
                      _animationController.forward();
                    } else if (text.isEmpty && _animationController.isCompleted) {
                      _animationController.reverse();
                    }
                  },
                  onSubmitted: (text) {
                    _sendMessage(context, viewModel);
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: viewModel.isGenerating
                    ? null
                    : () => _sendMessage(context, viewModel),
              ),
            ],
          ),
        );
      },
    );
  }
} 