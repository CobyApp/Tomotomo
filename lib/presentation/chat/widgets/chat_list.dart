import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/ui/paper/paper_theme.dart';
import '../../../../core/ui/paper/paper_tokens.dart';
import '../../../../core/ui/paper/paper_widgets.dart';
import '../../../../domain/entities/character.dart';
import '../../../../domain/entities/chat_message.dart' show ChatMessage;
import '../../locale/l10n_context.dart';
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
    if (widget.messages.isEmpty && !widget.isGenerating) {
      return _EmptyChat(character: widget.character);
    }
    return ListView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: widget.messages.length + (widget.isGenerating ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == widget.messages.length) {
          return _entrance(_buildLoadingIndicator());
        }
        final message = widget.messages[index];
        final isUser = _isFromCurrentUser(message);
        final showExpression = message.role != 'user';
        return _entrance(
          ChatBubble(
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
          ),
        );
      },
    );
  }

  /// Springy pop-in for each row: newly inserted bubbles fade + rise + scale
  /// with a gentle overshoot; reused rows (already on screen) stay put.
  Widget _entrance(Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      builder: (context, t, child) {
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 14),
            child: Transform.scale(
              scale: 0.9 + 0.1 * t,
              alignment: Alignment.bottomCenter,
              child: child,
            ),
          ),
        );
      },
      child: child,
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
                : const PersonAvatarGlyph(size: 32),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(PaperRadii.card),
              border: Border.all(color: p.ink, width: 2),
              boxShadow: [
                BoxShadow(color: p.hardShadow, offset: const Offset(3, 3)),
              ],
            ),
            child: _TypingDots(color: p.coral),
          ),
        ],
      ),
    );
  }
}

/// Friendly placeholder shown before the first message so the chat room never
/// opens to a blank void — the friend's avatar plus a short prompt.
class _EmptyChat extends StatelessWidget {
  const _EmptyChat({required this.character});

  final Character character;

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PolaroidAvatar(
              size: 96,
              child: character.hasAvatar
                  ? Image(image: character.imageProvider, fit: BoxFit.cover)
                  : const PersonAvatarGlyph(size: 96),
            ),
            const SizedBox(height: 20),
            Text(
              context.tr('chatEmptyTitle'),
              textAlign: TextAlign.center,
              style: cuteDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: p.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('chatEmptyBody'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, height: 1.45, color: p.inkSoft),
            ),
          ],
        ),
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
