import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/supabase/app_supabase.dart';
import '../../../core/storage/character_storage.dart';
import '../../../domain/entities/character_record.dart';
import '../../../domain/repositories/character_record_repository.dart';
import '../locale/l10n_context.dart';

/// Screen to edit an existing custom character (own characters only).
class EditCharacterScreen extends StatefulWidget {
  const EditCharacterScreen({super.key, required this.record});

  final CharacterRecord record;

  @override
  State<EditCharacterScreen> createState() => _EditCharacterScreenState();
}

class _EditCharacterScreenState extends State<EditCharacterScreen> {
  late final CharacterRecord _record;
  final _nameController = TextEditingController();
  final _nameSecondaryController = TextEditingController();
  final _speechStyleController = TextEditingController();
  final _avatarUrlController = TextEditingController();
  final _backgroundUrlController = TextEditingController();

  String _language = 'ja';
  bool _isPublic = false;
  bool _saving = false;
  bool _uploadingAvatar = false;
  bool _uploadingBackground = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _record = widget.record;
    _nameController.text = _record.name;
    _nameSecondaryController.text = _record.nameSecondary ?? '';
    _speechStyleController.text = _record.speechStyle ?? '';
    _avatarUrlController.text = _record.avatarUrl ?? '';
    _backgroundUrlController.text = _record.backgroundUrl ?? '';
    _language = _record.language;
    _isPublic = _record.isPublic;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameSecondaryController.dispose();
    _speechStyleController.dispose();
    _avatarUrlController.dispose();
    _backgroundUrlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final user = AppSupabase.auth.currentUser;
    if (user == null || user.id != _record.ownerId) {
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
    try {
      final repo = context.read<CharacterRecordRepository>();
      final updated = CharacterRecord(
        id: _record.id,
        ownerId: _record.ownerId,
        name: name,
        nameSecondary: _nameSecondaryController.text.trim().isEmpty
            ? null
            : _nameSecondaryController.text.trim(),
        speechStyle: _speechStyleController.text.trim().isEmpty
            ? null
            : _speechStyleController.text.trim(),
        avatarUrl: _avatarUrlController.text.trim().isEmpty
            ? null
            : _avatarUrlController.text.trim(),
        backgroundUrl: _backgroundUrlController.text.trim().isEmpty
            ? null
            : _backgroundUrlController.text.trim(),
        language: _language,
        isPublic: _isPublic,
        voiceProvider: _record.voiceProvider,
        voiceId: _record.voiceId,
        downloadCount: _record.downloadCount,
        createdAt: _record.createdAt,
        updatedAt: DateTime.now(),
      );
      await repo.updateCharacter(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('characterUpdated'))),
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

  Future<void> _pickAndUploadAvatar() async {
    final user = AppSupabase.auth.currentUser;
    if (user == null || user.id != _record.ownerId) return;
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 512, imageQuality: 85);
    if (x == null || !mounted) return;
    setState(() {
      _error = null;
      _uploadingAvatar = true;
    });
    try {
      final url = await CharacterStorage.uploadAvatar(user.id, File(x.path));
      if (!mounted) return;
      _avatarUrlController.text = url;
      setState(() => _uploadingAvatar = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('avatarUploadDone'))));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _uploadingAvatar = false;
      });
    }
  }

  Future<void> _pickAndUploadBackground() async {
    final user = AppSupabase.auth.currentUser;
    if (user == null || user.id != _record.ownerId) return;
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 85);
    if (x == null || !mounted) return;
    setState(() {
      _error = null;
      _uploadingBackground = true;
    });
    try {
      final url = await CharacterStorage.uploadBackground(user.id, File(x.path));
      if (!mounted) return;
      _backgroundUrlController.text = url;
      setState(() => _uploadingBackground = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('bgUploadDone'))));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _uploadingBackground = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('editCharacterTitle')),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          if (_error != null) ...[
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: context.tr('name'),
              hintText: context.tr('nameHint'),
              border: const OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nameSecondaryController,
            decoration: InputDecoration(
              labelText: context.tr('nameSecondary'),
              hintText: context.tr('nameSecondaryHint'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _speechStyleController,
            decoration: InputDecoration(
              labelText: context.tr('speechStyle'),
              hintText: context.tr('speechStyleHint'),
              alignLabelWithHint: true,
              border: const OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          Text(context.tr('avatarImage'), style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _uploadingAvatar ? null : _pickAndUploadAvatar,
                icon: _uploadingAvatar
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.photo_library_outlined, size: 20),
                label: Text(_uploadingAvatar ? context.tr('uploading') : context.tr('pickFromGallery')),
              ),
            ],
          ),
          TextFormField(
            controller: _avatarUrlController,
            decoration: InputDecoration(
              labelText: context.tr('avatarUrlHint'),
              hintText: context.tr('optional'),
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 12),
          Text(context.tr('bgImage'), style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _uploadingBackground ? null : _pickAndUploadBackground,
                icon: _uploadingBackground
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.photo_library_outlined, size: 20),
                label: Text(_uploadingBackground ? context.tr('uploading') : context.tr('pickFromGallery')),
              ),
            ],
          ),
          TextFormField(
            controller: _backgroundUrlController,
            decoration: InputDecoration(
              labelText: context.tr('bgUrlHint'),
              hintText: context.tr('optional'),
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _language,
            decoration: InputDecoration(
              labelText: context.tr('langField'),
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(value: 'ja', child: Text(context.tr('langJa'))),
              DropdownMenuItem(value: 'ko', child: Text(context.tr('langKo'))),
            ],
            onChanged: (v) => setState(() => _language = v ?? 'ja'),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: Text(context.tr('publicSwitch')),
            value: _isPublic,
            onChanged: (v) => setState(() => _isPublic = v),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(context.tr('save')),
          ),
        ],
      ),
    );
  }
}
