import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/supabase/app_supabase.dart';
import '../../../../domain/entities/character.dart';
import '../../../../domain/entities/chat_message.dart' show ChatMessage, DmVoiceMessage;
import '../chat_expression_sheet.dart';
import '../chat_message_report.dart';
import 'chat_bubble.dart';

class ChatList extends StatefulWidget {
  final List<ChatMessage> messages;
  final Character character;
  final bool isGenerating;
  final ScrollController scrollController;
  final String? chatRoomId;

  const ChatList({
    super.key,
    required this.messages,
    required this.character,
    required this.isGenerating,
    required this.scrollController,
    this.chatRoomId,
  });

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  bool _isFromCurrentUser(ChatMessage message) {
    if (!widget.character.isDirectMessage) {
      return message.role == 'user';
    }
    final uid = AppSupabase.auth.currentUser?.id;
    if (message.senderId != null && uid != null) return message.senderId == uid;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: widget.messages.length + (widget.isGenerating ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == widget.messages.length) {
          return _buildLoadingIndicator();
        }
        final message = widget.messages[index];
        final isUser = _isFromCurrentUser(message);
        final showExpression = !DmVoiceMessage.isVoiceContent(message.content) &&
            (widget.character.isDirectMessage || message.role != 'user');
        return ChatBubble(
          message: message,
          character: widget.character,
          isUser: isUser,
          onExplanationTap: showExpression
              ? () => showChatExpressionSheet(
                    context,
                    message: message,
                    character: widget.character,
                    chatRoomId: widget.chatRoomId,
                  )
              : null,
          onLongPressReport: () => confirmAndReportChatMessage(
                context,
                message: message,
                character: widget.character,
              ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    if (widget.character.isDirectMessage) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.character.primaryColor.withValues(alpha: 0.2),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.character.primaryColor.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: widget.character.hasAvatar ? widget.character.imageProvider : null,
              child: !widget.character.hasAvatar
                  ? Text(
                      widget.character.displayNamePrimary.isNotEmpty
                          ? widget.character.displayNamePrimary.substring(0, 1)
                          : '?',
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _TypingDots(color: widget.character.primaryColor),
          ),
        ],
      ),
    );
  }
}

/// Repeating “typing…” dots while waiting for the assistant reply.
class _TypingDots extends StatefulWidget {
  final Color color;

  const _TypingDots({required this.color});

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value * 2 * math.pi;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              _dot(i, t),
            ],
          ],
        );
      },
    );
  }

  Widget _dot(int index, double t) {
    // Staggered sine wave so dots pulse in sequence (typing rhythm).
    final phase = t + index * 0.85;
    final wave = (math.sin(phase) + 1) * 0.5;
    final opacity = 0.2 + wave * 0.65;
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: widget.color.withValues(alpha: opacity.clamp(0.15, 1.0)),
        shape: BoxShape.circle,
      ),
    );
  }
}
