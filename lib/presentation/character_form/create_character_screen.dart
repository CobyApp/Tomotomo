import 'package:flutter/material.dart';

import '../../core/ui/ui.dart';
import '../locale/l10n_context.dart';
import 'custom_character_editor_body.dart';

/// Screen to create a new custom character (tutor type, names, memo, avatar, visibility).
class CreateCharacterScreen extends StatelessWidget {
  const CreateCharacterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: context.tr('createCharacterTitle'),
      transparentBackground: false,
      body: const CustomCharacterEditorBody(),
    );
  }
}
