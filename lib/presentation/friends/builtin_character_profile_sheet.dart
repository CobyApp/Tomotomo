import 'package:flutter/material.dart';

import '../../domain/entities/character.dart';
import '../locale/l10n_context.dart';
import 'builtin_intro_l10n.dart';
import 'tutor_character_profile_sheet.dart';

Future<void> showBuiltinCharacterProfileSheet(
  BuildContext context, {
  required Character character,
  required Future<void> Function() onOpenChat,
  required Future<void> Function() onRemoveAttempt,
}) {
  final key = builtinCharacterShortKey(character.id);
  final short = key != null ? context.tr(key) : character.tagline;

  return showTutorProfileSheet(
    context,
    avatar: CircleAvatar(
      radius: 52,
      backgroundImage: character.imageProvider,
    ),
    namePrimary: character.displayNamePrimary,
    nameSecondary: character.displayNameSecondary.isEmpty ? null : character.displayNameSecondary,
    shortTagline: short,
    onOpenChat: onOpenChat,
    onBuiltinInfo: onRemoveAttempt,
  );
}
