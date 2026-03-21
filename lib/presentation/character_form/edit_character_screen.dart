import 'package:flutter/material.dart';

import '../../../domain/entities/character_record.dart';
import '../locale/l10n_context.dart';
import 'custom_character_editor_body.dart';

/// Screen to edit an existing custom character (own characters only).
class EditCharacterScreen extends StatelessWidget {
  const EditCharacterScreen({super.key, required this.record});

  final CharacterRecord record;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('editCharacterTitle')),
        centerTitle: false,
      ),
      body: CustomCharacterEditorBody(existing: record),
    );
  }
}
