import 'package:flutter/material.dart';
import '../../../../domain/entities/character.dart';
import '../../locale/l10n_context.dart';

class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isGenerating;
  final Character character;

  const ChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    required this.isGenerating,
    required this.character,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = character.primaryColor;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
                ),
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: context.tr('chatInputHint'),
                    hintStyle: TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.55), fontSize: 15),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                  style: TextStyle(fontSize: 15.5, color: scheme.onSurface),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Material(
              color: accent,
              borderRadius: BorderRadius.circular(22),
              elevation: 0,
              child: InkWell(
                onTap: isGenerating ? null : onSend,
                borderRadius: BorderRadius.circular(22),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    isGenerating ? Icons.hourglass_empty_rounded : Icons.send_rounded,
                    color: accent.computeLuminance() > 0.5 ? scheme.onSurface : Colors.white,
                    size: 22,
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
