import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/storage/character_storage.dart';
import '../../core/supabase/app_supabase.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../locale/l10n_context.dart';

/// Edit current user's profile (display name, avatar, status, learning language).
class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _displayNameController = TextEditingController();
  final _statusMessageController = TextEditingController();
  final _avatarUrlController = TextEditingController();

  Profile? _profile;
  String _learningLanguage = 'ja';
  bool _loading = true;
  bool _saving = false;
  bool _uploadingAvatar = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_load());
    });
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _statusMessageController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = AppSupabase.auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = null;
          _profile = null;
        });
      }
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = context.read<ProfileRepository>();
      final p = await repo.getProfile(user.id);
      if (!mounted) return;
      if (p == null) {
        setState(() {
          _profile = null;
          _loading = false;
          _error = 'missing';
        });
        return;
      }
      _displayNameController.text = p.displayName ?? '';
      _statusMessageController.text = p.statusMessage ?? '';
      _avatarUrlController.text = p.avatarUrl ?? '';
      setState(() {
        _profile = p;
        _learningLanguage = p.learningLanguage == 'ko' ? 'ko' : 'ja';
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _profile = null;
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final user = AppSupabase.auth.currentUser;
    if (user == null) return;
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
        _uploadingAvatar = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _save() async {
    final profile = _profile;
    final user = AppSupabase.auth.currentUser;
    if (profile == null || user == null) return;
    final name = _displayNameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = context.tr('displayNameRequired'));
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      final repo = context.read<ProfileRepository>();
      final avatar = _avatarUrlController.text.trim();
      final status = _statusMessageController.text.trim();
      final updated = Profile(
        id: profile.id,
        email: profile.email,
        displayName: name,
        avatarUrl: avatar.isEmpty ? null : avatar,
        statusMessage: status.isEmpty ? null : status,
        appLanguage: profile.appLanguage,
        learningLanguage: _learningLanguage,
        createdAt: profile.createdAt,
        updatedAt: profile.updatedAt,
      );
      await repo.updateProfile(updated);
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('profileEditSaved'))));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AppSupabase.auth.currentUser;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(context.tr('profileEditTitle')),
          centerTitle: false,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(context.tr('profileEditTitle')),
          centerTitle: false,
        ),
        body: Center(child: Text(context.tr('loginRequired'))),
      );
    }

    if (_profile == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(context.tr('profileEditTitle')),
          centerTitle: false,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _error == 'missing' ? context.tr('profileEditLoadError') : (_error ?? context.tr('profileEditLoadError')),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => unawaited(_load()),
                  child: Text(context.tr('retry')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final profile = _profile!;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('profileEditTitle')),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(context.tr('save')),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          Text(
            context.tr('profileEditSubtitle'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 20),
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
            controller: _displayNameController,
            decoration: InputDecoration(
              labelText: context.tr('displayNameLabel'),
              hintText: context.tr('displayNameHint'),
              border: const OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _statusMessageController,
            decoration: InputDecoration(
              labelText: context.tr('profileStatusMessageLabel'),
              hintText: context.tr('profileStatusMessageHint'),
              border: const OutlineInputBorder(),
            ),
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 20),
          Text(context.tr('signUpProfilePhoto'), style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _uploadingAvatar ? null : _pickAndUploadAvatar,
                icon: _uploadingAvatar
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.photo_library_outlined, size: 20),
                label: Text(_uploadingAvatar ? context.tr('uploading') : context.tr('pickFromGallery')),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: _uploadingAvatar
                    ? null
                    : () {
                        _avatarUrlController.clear();
                        setState(() {});
                      },
                child: Text(context.tr('profileEditClearPhoto')),
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
          const SizedBox(height: 20),
          Text(
            context.tr('settingsLearningLanguageTitle'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('settingsLearningLanguageSubtitle'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  title: Text(context.tr('langJa')),
                  trailing: _learningLanguage == 'ja' ? const Icon(Icons.check) : null,
                  onTap: () => setState(() => _learningLanguage = 'ja'),
                ),
                const Divider(height: 1),
                ListTile(
                  title: Text(context.tr('langKo')),
                  trailing: _learningLanguage == 'ko' ? const Icon(Icons.check) : null,
                  onTap: () => setState(() => _learningLanguage = 'ko'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${context.tr('settingsEmail')}: ${profile.email ?? user.email ?? '—'}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
