import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/chat_viewmodel.dart';

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
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 8, 
            bottom: MediaQuery.of(context).padding.bottom + 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: memberColor.withOpacity(0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: memberColor.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: memberColor.withOpacity(0.6),
                    size: 18,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: '${viewModel.currentMember.name}에게 메시지...',
                        hintStyle: TextStyle(
                          fontFamily: 'Quicksand',
                          color: Colors.grey[400],
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      style: const TextStyle(
                        fontFamily: 'Quicksand',
                        fontSize: 15,
                      ),
                      textAlignVertical: TextAlignVertical.center,
                      minLines: 1,
                      maxLines: 4,
                      onSubmitted: (text) {
                        if (text.isNotEmpty && !viewModel.isGenerating) {
                          viewModel.sendMessage(text);
                          _controller.clear();
                        }
                      },
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(4),
                  child: GestureDetector(
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
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            memberColor,
                            HSLColor.fromColor(memberColor).withLightness(
                              HSLColor.fromColor(memberColor).lightness * 1.3
                            ).toColor(),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: memberColor.withOpacity(0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 