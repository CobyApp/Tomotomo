import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/storage/character_storage.dart';
import '../../../core/supabase/app_supabase.dart';
import '../../../domain/entities/character_record.dart';
import '../../../domain/repositories/character_record_repository.dart';
import '../locale/l10n_context.dart';

/// Shared form for [CreateCharacterScreen] and [EditCharacterScreen].
class CustomCharacterEditorBody extends StatefulWidget {
  const CustomCharacterEditorBody({super.key, this.existing});

  /// `null` = create. Otherwise edit this row (must be owned by current user).
  final CharacterRecord? existing;

  @override
  State<CustomCharacterEditorBody> createState() => _CustomCharacterEditorBodyState();
}

class _CustomCharacterEditorBodyState extends State<CustomCharacterEditorBody> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nameSecondaryController = TextEditingController();
  final _memoController = TextEditingController();

  String _language = 'ja';
  bool _isPublic = false;
  bool _saving = false;
  bool _uploadingAvatar = false;
  String? _error;
  String? _avatarUrl;

  CharacterRecord? get _existing => widget.existing;

  @override
  void initState() {
    super.initState();
    final r = _existing;
    if (r != null) {
      _nameController.text = r.name;
      _nameSecondaryController.text = r.nameSecondary ?? '';
      _memoController.text = r.speechStyle?.trim() ?? '';
      _language = r.language;
      _isPublic = r.isPublic;
      _avatarUrl = (r.avatarUrl != null && r.avatarUrl!.trim().isNotEmpty) ? r.avatarUrl : null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameSecondaryController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final user = AppSupabase.auth.currentUser;
    if (user == null) {
      setState(() => _error = context.tr('loginRequired'));
      return;
    }
    final existing = _existing;
    if (existing != null && user.id != existing.ownerId) {
      setState(() => _error = context.tr('editCharacterOwnOnly'));
      return;
    }
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = context.tr('nameRequired'));
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    final memo = _memoController.text.trim();
    final secondary = _nameSecondaryController.text.trim();
    try {
      final repo = context.read<CharacterRecordRepository>();
      if (existing == null) {
        final record = CharacterRecord.draft(
          ownerId: user.id,
          name: name,
          nameSecondary: secondary.isEmpty ? null : secondary,
          speechStyle: memo.isEmpty ? null : memo,
          avatarUrl: _avatarUrl,
          language: _language,
          isPublic: _isPublic,
        );
        await repo.createCharacter(record);
      } else {
        final updated = CharacterRecord(
          id: existing.id,
          ownerId: existing.ownerId,
          name: name,
          nameSecondary: secondary.isEmpty ? null : secondary,
          speechStyle: memo.isEmpty ? null : memo,
          avatarUrl: _avatarUrl,
          language: _language,
          isPublic: _isPublic,
          downloadCount: existing.downloadCount,
          createdAt: existing.createdAt,
          updatedAt: DateTime.now(),
        );
        await repo.updateCharacter(updated);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(existing == null ? 'characterCreated' : 'characterUpdated'),
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _saving = false;
      });
    }
  }

  Future<void> _pickAvatar() async {
    final user = AppSupabase.auth.currentUser;
    if (user == null) {
      setState(() => _error = context.tr('loginRequired'));
      return;
    }
    final existing = _existing;
    if (existing != null && user.id != existing.ownerId) return;
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      imageQuality: 85,
    );
    if (x == null || !mounted) return;
    setState(() {
      _error = null;
      _uploadingAvatar = true;
    });
    try {
      final url = await CharacterStorage.uploadAvatar(user.id, File(x.path));
      if (!mounted) return;
      setState(() {
        _avatarUrl = url;
        _uploadingAvatar = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('avatarUploadDone'))),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _uploadingAvatar = false;
      });
    }
  }

  void _clearAvatar() {
    setState(() => _avatarUrl = null);
  }

  String _labelDisplayName(BuildContext context) =>
      _language == 'ja' ? context.tr('characterDisplayNameJa') : context.tr('characterDisplayNameKo');

  String _hintDisplayName(BuildContext context) =>
      _language == 'ja' ? context.tr('characterDisplayNameJaHint') : context.tr('characterDisplayNameKoHint');

  String _labelAltName(BuildContext context) =>
      _language == 'ja' ? context.tr('characterAltNameJa') : context.tr('characterAltNameKo');

  String _hintAltName(BuildContext context) =>
      _language == 'ja' ? context.tr('characterAltNameJaHint') : context.tr('characterAltNameKoHint');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          if (_error != null) ...[
            Card(
              color: scheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _error!,
                  style: TextStyle(color: scheme.onErrorContainer),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            context.tr('characterTutorType'),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: [
              ButtonSegment<String>(
                value: 'ja',
                label: Text(context.tr('characterTutorJaShort')),
                tooltip: context.tr('characterTutorJaHelp'),
              ),
              ButtonSegment<String>(
                value: 'ko',
                label: Text(context.tr('characterTutorKoShort')),
                tooltip: context.tr('characterTutorKoHelp'),
              ),
            ],
            selected: {_language},
            onSelectionChanged: (Set<String> next) {
              if (next.isEmpty) return;
              setState(() => _language = next.first);
            },
          ),
          const SizedBox(height: 6),
          Text(
            _language == 'ja' ? context.tr('characterTutorJaHelp') : context.tr('characterTutorKoHelp'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: _labelDisplayName(context),
              hintText: _hintDisplayName(context),
              border: const OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
            validator: (v) => (v == null || v.trim().isEmpty) ? context.tr('nameRequired') : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nameSecondaryController,
            decoration: InputDecoration(
              labelText: _labelAltName(context),
              hintText: _hintAltName(context),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _memoController,
            decoration: InputDecoration(
              labelText: context.tr('characterMemo'),
              hintText: context.tr('characterMemoHint'),
              alignLabelWithHint: true,
              border: const OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          Text(
            context.tr('characterAvatarSection'),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                    ? NetworkImage(_avatarUrl!)
                    : null,
                child: (_avatarUrl == null || _avatarUrl!.isEmpty)
                    ? Icon(Icons.face, color: scheme.onSurfaceVariant)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _uploadingAvatar ? null : _pickAvatar,
                      icon: _uploadingAvatar
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.photo_library_outlined, size: 20),
                      label: Text(_uploadingAvatar ? context.tr('uploading') : context.tr('pickFromGallery')),
                    ),
                    if (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                      TextButton(
                        onPressed: _clearAvatar,
                        child: Text(context.tr('characterRemoveAvatar')),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            title: Text(context.tr('publicSwitch')),
            value: _isPublic,
            onChanged: (v) => setState(() => _isPublic = v),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving
                ? null
                : () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      await _save();
                    }
                  },
            child: _saving
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(context.tr(_existing == null ? 'create' : 'save')),
          ),
        ],
      ),
    );
  }
}
