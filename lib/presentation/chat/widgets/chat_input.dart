import 'package:flutter/material.dart';

import '../../../core/ui/app_tokens.dart';
import '../../../core/ui/paper/paper_tokens.dart';
import '../../../domain/entities/character.dart';
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
    final p = context.paper;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.composerPadH,
        AppSpacing.composerPadTop,
        AppSpacing.composerPadH,
        AppSpacing.composerPadBottom,
      ),
      decoration: BoxDecoration(
        color: p.card,
        border: Border(top: BorderSide(color: p.cardEdge)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: p.paperBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: p.ink, width: 2),
                ),
                child: TextField(
                  controller: controller,
                  readOnly: !canSendMessage,
                  decoration: InputDecoration(
                    hintText: hintOverride ?? context.tr('chatInputHint'),
                    hintStyle: TextStyle(
                      color: p.inkSoft.withValues(alpha: 0.7),
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 13,
                    ),
                  ),
                  style: TextStyle(fontSize: 15.5, color: p.ink),
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
                gradient: canTapSend
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [p.coral, p.coralDeep],
                      )
                    : null,
                color: canTapSend ? null : p.inkSoft.withValues(alpha: 0.3),
                shape: BoxShape.circle,
                border: Border.all(color: p.ink, width: 2),
                boxShadow: canTapSend
                    ? [BoxShadow(color: p.hardShadow, offset: const Offset(2, 2))]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: canTapSend ? onSend : null,
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: 48,
                    height: 48,
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
