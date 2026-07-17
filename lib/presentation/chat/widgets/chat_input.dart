import 'package:flutter/material.dart';

import '../../../../core/ui/app_tokens.dart';
import '../../../../core/ui/holo/holo_tokens.dart';
import '../../../../domain/entities/character.dart';
import '../../locale/l10n_context.dart';

class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isGenerating;
  final Character character;
  final bool canSendMessage;
  final String? hintOverride;

  const ChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    required this.isGenerating,
    required this.character,
    this.canSendMessage = true,
    this.hintOverride,
  });

  @override
  Widget build(BuildContext context) {
    final canTapSend = !isGenerating && canSendMessage;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.composerPadH,
        AppSpacing.composerPadTop,
        AppSpacing.composerPadH,
        AppSpacing.composerPadBottom,
      ),
      decoration: const BoxDecoration(
        color: Holo.surfaceCard,
        border: Border(top: BorderSide(color: Holo.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Holo.surfaceMuted,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Holo.border),
                ),
                child: TextField(
                  controller: controller,
                  readOnly: !canSendMessage,
                  decoration: InputDecoration(
                    hintText: hintOverride ?? context.tr('chatInputHint'),
                    hintStyle: TextStyle(
                      color: Holo.inkPlumSoft.withValues(alpha: 0.7),
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 11,
                    ),
                  ),
                  style: const TextStyle(fontSize: 15.5, color: Holo.inkPlum),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) {
                    if (canSendMessage) onSend();
                  },
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              decoration: BoxDecoration(
                gradient: canTapSend ? Holo.holoGradient : null,
                color: canTapSend
                    ? null
                    : Holo.inkPlumSoft.withValues(alpha: 0.3),
                shape: BoxShape.circle,
                boxShadow: canTapSend ? Holo.cardShadow : null,
              ),
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: canTapSend ? onSend : null,
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: 46,
                    height: 46,
                    child: Icon(
                      isGenerating
                          ? Icons.hourglass_empty_rounded
                          : Icons.send_rounded,
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
    );
  }
}
