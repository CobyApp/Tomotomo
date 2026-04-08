import 'package:flutter/material.dart';

import '../../core/ui/app_tokens.dart';
import '../../domain/entities/character.dart';
import '../locale/l10n_context.dart';
import 'builtin_intro_l10n.dart';

Future<void> showBuiltinCharacterProfileSheet(
  BuildContext context, {
  required Character character,
  required Future<void> Function() onOpenChat,
  required Future<void> Function() onRemoveAttempt,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _BuiltinCharacterProfileSheet(
      character: character,
      onOpenChat: onOpenChat,
      onRemoveAttempt: onRemoveAttempt,
    ),
  );
}

class _BuiltinCharacterProfileSheet extends StatelessWidget {
  const _BuiltinCharacterProfileSheet({
    required this.character,
    required this.onOpenChat,
    required this.onRemoveAttempt,
  });

  final Character character;
  final Future<void> Function() onOpenChat;
  final Future<void> Function() onRemoveAttempt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final h = MediaQuery.sizeOf(context).height;
    final introKey = builtinCharacterIntroKey(character.id);
    final intro = introKey != null ? context.tr(introKey) : character.description;

    return Padding(
      padding: EdgeInsets.only(top: h * 0.08),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(22, 12, 22, 20 + bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: scheme.outlineVariant.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: CircleAvatar(
                    radius: 52,
                    backgroundImage: character.imageProvider,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  character.displayNamePrimary,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                ),
                if (character.displayNameSecondary.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    character.displayNameSecondary,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
                if (character.tagline.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                      child: Text(
                        character.tagline,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  context.tr('friendsBuiltinSelfIntroHeading'),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  intro,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await onOpenChat();
                  },
                  icon: const Icon(Icons.chat_rounded, size: 22),
                  label: Text(context.tr('friendsSheetOpenChat')),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await onRemoveAttempt();
                  },
                  icon: Icon(Icons.info_outline_rounded, size: 22, color: scheme.primary),
                  label: Text(context.tr('friendsBuiltinProfileInfoButton')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
