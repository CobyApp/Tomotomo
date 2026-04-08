import 'package:flutter/material.dart';

import '../../core/ui/app_tokens.dart';
import '../../domain/entities/character_record.dart';
import '../locale/l10n_context.dart';

/// Bottom sheet: choose chat or paid copy for a public [CharacterRecord].
Future<void> showPublicCharacterSheet(
  BuildContext context, {
  required CharacterRecord record,
  required String subtitleLine,
  required Future<void> Function() onStartChat,
  required Future<void> Function() onAddToMine,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      final bottom = MediaQuery.paddingOf(ctx).bottom;
      return Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.sheetSide, 0, AppSpacing.sheetSide, AppSpacing.sheetBottom + bottom),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: scheme.outlineVariant.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record.name,
                              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subtitleLine,
                              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    height: 1.35,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (record.avatarUrl != null && record.avatarUrl!.trim().isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            record.avatarUrl!,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const SizedBox.shrink(),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await onStartChat();
                    },
                    icon: const Icon(Icons.chat_bubble_rounded, size: 22),
                    label: Text(ctx.tr('charactersPublicStartChat')),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await onAddToMine();
                    },
                    icon: Icon(Icons.download_rounded, size: 22, color: scheme.primary),
                    label: Text(ctx.tr('charactersPublicDownloadLine')),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: scheme.primary.withValues(alpha: 0.45)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ctx.tr('charactersPublicForkExplain'),
                    style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
                          height: 1.35,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
