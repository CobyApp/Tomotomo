import 'package:flutter/material.dart';

import '../../../core/ui/paper/paper_tokens.dart';
import '../../../core/ui/paper/paper_widgets.dart';
import '../../../domain/entities/character.dart';
import '../../locale/l10n_context.dart';

class ChatInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isGenerating;
  final Character character;
  final bool canSendMessage;
  final String? hintOverride;

  /// Shown when the last message never got a reply — the app was terminated
  /// mid-generation, so the room would otherwise sit in unexplained silence.
  final bool showRetry;
  final VoidCallback? onRetry;

  const ChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    required this.isGenerating,
    required this.character,
    this.canSendMessage = true,
    this.hintOverride,
    this.showRetry = false,
    this.onRetry,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  @override
  void initState() {
    super.initState();
    // The button looked fully enabled — coral gradient, gloss, shadow — with an
    // empty field, and the tap was dropped by the caller. Nothing listened to the
    // widget.controller, so it could not rebuild on text change; the disabled visual it
    // already has was only ever used for widget.isGenerating.
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(ChatInput old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.trim().isNotEmpty;
    final canTapSend =
        !widget.isGenerating && widget.canSendMessage && hasText;
    final p = context.paper;

    // One unified "sticker bar": the text field and the send button live
    // inside a single rounded card that floats over the chat background.
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showRetry && widget.onRetry != null && !widget.isGenerating)
              ChatRetryNotice(onRetry: widget.onRetry!),
            Container(
          padding: const EdgeInsets.fromLTRB(6, 5, 5, 5),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: p.ink, width: 2.5),
            boxShadow: [
              BoxShadow(color: p.hardShadow, offset: const Offset(0, 3)),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  // Not readOnly while a reply generates: EditableText drops its
                  // input connection when readOnly, so the keyboard collapsed the
                  // moment you sent — for the several seconds on-device inference
                  // takes — and tapping the field did nothing. You can draft the
                  // next line now; only SENDING is gated, by canTapSend.
                  enabled: true,
                  decoration: InputDecoration(
                    hintText: widget.hintOverride ?? context.tr('chatInputHint'),
                    hintStyle: TextStyle(
                      color: p.inkSoft.withValues(alpha: 0.7),
                      fontSize: 15,
                    ),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    isCollapsed: true,
                    contentPadding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                  ),
                  style: TextStyle(fontSize: 15.5, color: p.ink),
                  maxLines: 5,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) {
                    if (widget.canSendMessage) widget.onSend();
                  },
                ),
              ),
              const SizedBox(width: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: 44,
                height: 44,
                foregroundDecoration: canTapSend
                    ? stickerGloss(shape: BoxShape.circle, strength: 0.3)
                    : null,
                decoration: BoxDecoration(
                  gradient: canTapSend
                      ? LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [p.coral, p.coralDeep],
                        )
                      : null,
                  color: canTapSend ? null : p.inkSoft.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                  border: Border.all(color: p.ink, width: 2),
                  boxShadow: canTapSend
                      ? [BoxShadow(color: p.hardShadow, offset: const Offset(1, 2))]
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: canTapSend ? widget.onSend : null,
                    customBorder: const CircleBorder(),
                    child: Center(
                      child: Icon(
                        widget.isGenerating
                            ? Icons.more_horiz_rounded
                            : Icons.arrow_upward_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The "no reply arrived" affordance, shared by the composer and the model gate.
///
/// It used to live only inside [ChatInput], which the gate bar *replaces* while
/// the model is not ready — and a cold start after a termination mid-inference
/// is exactly when the model is still being probed. The one explanation for the
/// room's silence was therefore hidden in the case it was written for.
class ChatRetryNotice extends StatelessWidget {
  /// Null while the model is not ready: retrying would only fail, so the
  /// explanation shows without an action the user cannot successfully take.
  final VoidCallback? onRetry;

  const ChatRetryNotice({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              context.tr('chatReplyMissing'),
              style: TextStyle(fontSize: 12.5, color: p.inkSoft),
            ),
          ),
          if (onRetry != null) ...[
          const SizedBox(width: 8),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 32),
            ),
            child: Text(
              context.tr('retry'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: p.coralDeep,
              ),
            ),
          ),
          ],
        ],
      ),
    );
  }
}
