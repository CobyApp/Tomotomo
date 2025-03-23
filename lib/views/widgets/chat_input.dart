import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../utils/constants.dart';

class ChatInput extends StatefulWidget {
  const ChatInput({Key? key}) : super(key: key);

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatViewModel>(
      builder: (context, viewModel, child) {
        final memberColor = viewModel.currentMember.primaryColor;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: '${viewModel.currentMember.name}에게 메시지 보내기...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: memberColor.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: memberColor),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  minLines: 1,
                  maxLines: 5,
                  onSubmitted: (text) {
                    if (text.isNotEmpty && !viewModel.isGenerating) {
                      viewModel.sendMessage(text);
                      _controller.clear();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: memberColor,
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: viewModel.isGenerating
                      ? null
                      : () {
                          final text = _controller.text;
                          if (text.isNotEmpty) {
                            viewModel.sendMessage(text);
                            _controller.clear();
                          }
                        },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 