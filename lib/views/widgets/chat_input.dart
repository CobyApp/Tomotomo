import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/constants.dart';
import '../../viewmodels/chat_viewmodel.dart';

class ChatInput extends StatefulWidget {
  const ChatInput({super.key});

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_controller.text.trim().isEmpty) return;
    
    final viewModel = context.read<ChatViewModel>();
    viewModel.sendMessage(_controller.text);
    _controller.clear();
    _focusNode.requestFocus(); // 포커스 유지
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChatViewModel>();
    
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        border: Border(
          top: BorderSide(
            color: AppColors.divider,
            width: 0.5,
          ),
        ),
      ),
      child: Container(
        decoration: AppDecorations.inputDecoration,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: !viewModel.isGenerating,
                style: AppTextStyles.input,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: viewModel.isGenerating 
                      ? 'AI가 응답을 생성하고 있습니다...' 
                      : '메시지를 입력하세요...',
                  hintStyle: AppTextStyles.input.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: viewModel.isGenerating ? null : (_) => _handleSubmit(),
              ),
            ),
            Material(
              type: MaterialType.transparency,
              child: IconButton(
                icon: viewModel.isGenerating
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        Icons.arrow_upward_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                onPressed: viewModel.isGenerating ? null : _handleSubmit,
                splashRadius: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 