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
          padding: EdgeInsets.only(
            left: 16, 
            right: 16, 
            top: 12, 
            bottom: MediaQuery.of(context).padding.bottom + 12,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withOpacity(0.4),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: memberColor.withOpacity(0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 입력창 앞 아이콘
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: memberColor.withOpacity(0.7),
                    size: 18,
                  ),
                ),
                
                // 텍스트 입력 필드
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: '${viewModel.currentMember.getName(settingsVM.currentLanguage.code)}에게 메시지...',
                        hintStyle: TextStyle(
                          fontFamily: 'Quicksand',
                          color: Colors.grey[400],
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        isDense: true,
                      ),
                      style: const TextStyle(
                        fontFamily: 'Quicksand',
                        fontSize: 15,
                      ),
                      textAlignVertical: TextAlignVertical.center,
                      minLines: 1,
                      maxLines: 4,
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
                ),
                
                // 전송 버튼
                Container(
                  margin: const EdgeInsets.all(4),
                  child: ScaleTransition(
                    scale: _animation,
                    child: GestureDetector(
                      onTap: viewModel.isGenerating
                          ? null
                          : () => _sendMessage(context, viewModel),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              memberColor,
                              HSLColor.fromColor(memberColor)
                                  .withLightness(
                                      HSLColor.fromColor(memberColor).lightness * 1.3)
                                  .toColor(),
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
                        child: viewModel.isGenerating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
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