import 'package:flutter/material.dart';

import '../locale/l10n_context.dart';
import 'custom_character_editor_body.dart';

/// Screen to create a new custom character (tutor type, names, memo, avatar, visibility).
class CreateCharacterScreen extends StatelessWidget {
  const CreateCharacterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('createCharacterTitle')),
        centerTitle: false,
      ),
      body: const CustomCharacterEditorBody(),
    );
  }
}
