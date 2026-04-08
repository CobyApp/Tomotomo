import 'package:flutter/material.dart';

import '../../core/ui/app_tokens.dart';
import '../../domain/entities/character_record.dart';
import '../locale/l10n_context.dart';

/// Shared bottom sheet for built-in and custom tutors (friends list, etc.).
Future<void> showTutorProfileSheet(
  BuildContext context, {
  required Widget avatar,
  required String namePrimary,
  String? nameSecondary,
  required String shortTagline,
  required Future<void> Function() onOpenChat,
  Future<void> Function()? onDelete,
  Future<void> Function()? onBuiltinInfo,
}) {
  assert(onDelete == null || onBuiltinInfo == null, 'Use only one secondary action');

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      final bottom = MediaQuery.paddingOf(ctx).bottom;
      final h = MediaQuery.sizeOf(ctx).height;

      return Padding(
        padding: EdgeInsets.only(top: h * 0.08),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card)),
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
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: scheme.outlineVariant.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(child: avatar),
                  const SizedBox(height: 16),
                  Text(
                    namePrimary,
                    textAlign: TextAlign.center,
                    style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                  ),
                  if (nameSecondary != null && nameSecondary.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      nameSecondary.trim(),
                      textAlign: TextAlign.center,
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                  if (shortTagline.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                        ),
                        child: Text(
                          shortTagline.trim(),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await onOpenChat();
                    },
                    icon: const Icon(Icons.chat_rounded, size: 22),
                    label: Text(ctx.tr('friendsSheetOpenChat')),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  if (onDelete != null) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        await onDelete();
                      },
                      icon: Icon(Icons.delete_outline_rounded, size: 22, color: scheme.error),
                      label: Text(ctx.tr('charactersDelete')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: scheme.error,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: scheme.error.withValues(alpha: 0.45)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ],
                  if (onBuiltinInfo != null) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        await onBuiltinInfo();
                      },
                      icon: Icon(Icons.info_outline_rounded, size: 22, color: scheme.primary),
                      label: Text(ctx.tr('friendsBuiltinProfileInfoButton')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: scheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// My Supabase tutor row — same chrome as built-in; includes delete.
Future<void> showMyTutorProfileSheet(
  BuildContext context, {
  required CharacterRecord record,
  required Future<void> Function() onOpenChat,
  required Future<void> Function() onDelete,
}) {
  final scheme = Theme.of(context).colorScheme;
  final initial = record.name.isNotEmpty ? record.name.substring(0, 1) : '?';
  final url = record.avatarUrl?.trim();
  final avatar = CircleAvatar(
    radius: 52,
    backgroundColor: scheme.primaryContainer,
    foregroundImage: url != null && url.isNotEmpty ? NetworkImage(url) : null,
    child: url == null || url.isEmpty
        ? Text(
            initial,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: scheme.onPrimaryContainer,
            ),
          )
        : null,
  );

  final raw = record.listDetailLine.trim();
  final fallback = record.language == 'ja' ? context.tr('langJa') : context.tr('langKo');
  final line = raw.isNotEmpty ? raw : fallback;
  final short = line.length > 24 ? '${line.substring(0, 23)}…' : line;

  String? secondary;
  final ns = record.nameSecondary?.trim();
  if (ns != null && ns.isNotEmpty && ns != record.name) secondary = ns;

  return showTutorProfileSheet(
    context,
    avatar: avatar,
    namePrimary: record.name,
    nameSecondary: secondary,
    shortTagline: short,
    onOpenChat: onOpenChat,
    onDelete: onDelete,
  );
}
