import 'package:flutter/material.dart';
import '../../models/chat_message.dart';
import '../../utils/constants.dart';
import '../../utils/bubble_animation.dart';

class ChatBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isNew;

  const ChatBubble({
    super.key,
    required this.message,
    this.isNew = true,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = BubbleAnimation.createScaleAnimation(_controller);
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    if (widget.isNew) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BubbleAnimation.buildSlideTransition(
      animation: _controller,
      isUser: widget.message.isUser,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: Align(
            alignment: widget.message.isUser 
                ? Alignment.centerRight 
                : Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              margin: EdgeInsets.only(
                left: widget.message.isUser ? 64 : 16,
                right: widget.message.isUser ? 16 : 64,
                top: 4,
                bottom: 4,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: widget.message.isUser 
                    ? AppColors.userBubble 
                    : AppColors.aiBubble,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                widget.message.message,
                style: AppTextStyles.message.copyWith(
                  color: widget.message.isUser 
                      ? Colors.white 
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 