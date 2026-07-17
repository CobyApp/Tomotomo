import 'package:flutter/material.dart';

import '../../core/ui/paper/paper_scaffold.dart';
import '../locale/l10n_context.dart';
import 'custom_character_editor_body.dart';

/// Screen to create a new custom character (tutor type, names, memo, avatar, visibility).
class CreateCharacterScreen extends StatelessWidget {
  const CreateCharacterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PaperScaffold(
      title: context.tr('createCharacterTitle'),
      subtitle: context.tr('createCharacterSubtitle'),
      showPointsChip: true,
      transparentBackground: false,
      body: const CustomCharacterEditorBody(),
    );
  }
}
