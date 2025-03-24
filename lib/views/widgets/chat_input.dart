import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/character.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../utils/constants.dart';
import '../../viewmodels/settings_viewmodel.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final Character character;
  final bool isGenerating;

  const ChatInput({
    Key? key,
    required this.onSendMessage,
    required this.character,
    required this.isGenerating,
  }) : super(key: key);

  @override
  _ChatInputState createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasText = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -1),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: 40,
                  maxHeight: 120,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _focusNode.hasFocus
                        ? widget.character.primaryColor
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: !widget.isGenerating,
                  style: AppTextStyles.input.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.isGenerating
                        ? '${widget.character.name}가 응답하고 있어요...'
                        : '메시지를 입력하세요',
                    hintStyle: AppTextStyles.input.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                  maxLines: null,
                  minLines: 1,
                  textAlignVertical: TextAlignVertical.center,
                  cursorColor: widget.character.primaryColor,
                  onChanged: (text) {
                    setState(() {
                      _hasText = text.trim().isNotEmpty;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _hasText ? 40 : 0,
              height: 40,
              curve: Curves.easeInOut,
              child: _hasText
                  ? Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            widget.character.primaryColor,
                            widget.character.primaryColor.withOpacity(0.8),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: widget.character.primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        type: MaterialType.transparency,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: widget.isGenerating
                              ? null
                              : () {
                                  final message = _controller.text.trim();
                                  if (message.isNotEmpty) {
                                    widget.onSendMessage(message);
                                    _controller.clear();
                                    setState(() {
                                      _hasText = false;
                                    });
                                  }
                                },
                          child: const Center(
                            child: Icon(
                              Icons.arrow_upward_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}