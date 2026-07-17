import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/ui/paper/paper_tokens.dart';
import '../../../../core/ui/paper/paper_widgets.dart';
import '../../../../domain/entities/character.dart';
import '../../../../domain/entities/chat_message.dart' show ChatMessage;
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
    // Single local user: user messages are role 'user'.
    return message.role == 'user';
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
        final showExpression = message.role != 'user';
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
    final p = context.paper;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PolaroidAvatar(
            size: 32,
            rotate: -0.06,
            child: widget.character.hasAvatar
                ? Image(image: widget.character.imageProvider, fit: BoxFit.cover)
                : Center(
                    child: Text(
                      widget.character.displayNamePrimary.isNotEmpty
                          ? widget.character.displayNamePrimary.substring(0, 1)
                          : '?',
                      style: TextStyle(color: p.coral),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(PaperRadii.card),
              border: Border.all(color: p.cardEdge),
            ),
            child: _TypingDots(color: p.ink),
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

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
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
