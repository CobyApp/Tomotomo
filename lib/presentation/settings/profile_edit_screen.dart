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

/// Edit current user's profile (display name, gallery avatar, status). App language: Settings.
class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _displayNameController = TextEditingController();
  final _statusMessageController = TextEditingController();

  Profile? _profile;
  String? _avatarUrl;
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
      _avatarUrl = p.avatarUrl;
      setState(() {
        _profile = p;
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
      setState(() {
        _avatarUrl = url;
        _uploadingAvatar = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.trRead('avatarUploadDone'))));
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
      setState(() => _error = context.trRead('displayNameRequired'));
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      final repo = context.read<ProfileRepository>();
      final status = _statusMessageController.text.trim();
      final avatar = _avatarUrl?.trim();
      final updated = Profile(
        id: profile.id,
        email: profile.email,
        displayName: name,
        avatarUrl: avatar == null || avatar.isEmpty ? null : avatar,
        statusMessage: status.isEmpty ? null : status,
        appLanguage: profile.appLanguage,
        learningLanguage: profile.learningLanguage,
        createdAt: profile.createdAt,
        updatedAt: profile.updatedAt,
      );
      await repo.updateProfile(updated);
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.trRead('profileEditSaved'))));
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
    final scheme = Theme.of(context).colorScheme;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('profileEditTitle')), centerTitle: false),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('profileEditTitle')), centerTitle: false),
        body: Center(child: Text(context.tr('loginRequired'))),
      );
    }

    if (_profile == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('profileEditTitle')), centerTitle: false),
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
                FilledButton(onPressed: () => unawaited(_load()), child: Text(context.tr('retry'))),
              ],
            ),
          ),
        ),
      );
    }

    final profile = _profile!;
    final hasPhoto = _avatarUrl != null && _avatarUrl!.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('profileEditTitle')),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: scheme.primary),
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          if (_error != null) ...[
            Card(
              color: scheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_error!, style: TextStyle(color: scheme.onErrorContainer)),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Material(
                  color: scheme.surfaceContainerHigh,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
                    child: SizedBox(
                      width: 112,
                      height: 112,
                      child: _uploadingAvatar
                          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                          : hasPhoto
                              ? Image.network(
                                  _avatarUrl!.trim(),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.broken_image_outlined,
                                    size: 40,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                )
                              : Icon(Icons.person_outline, size: 48, color: scheme.onSurfaceVariant),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: FloatingActionButton.small(
                    heroTag: 'profile_pick_photo',
                    onPressed: _uploadingAvatar ? null : _pickAndUploadAvatar,
                    child: const Icon(Icons.camera_alt_outlined, size: 20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _uploadingAvatar
                  ? null
                  : () {
                      setState(() => _avatarUrl = null);
                    },
              child: Text(context.tr('profileEditClearPhoto')),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('profilePhotoGalleryHint'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: _displayNameController,
            decoration: InputDecoration(
              labelText: context.tr('displayNameLabel'),
              hintText: context.tr('displayNameHint'),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _statusMessageController,
            decoration: InputDecoration(
              labelText: context.tr('profileStatusMessageLabel'),
              hintText: context.tr('profileStatusMessageHint'),
            ),
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 20),
          Text(
            '${context.tr('settingsEmail')}: ${profile.email ?? user.email ?? '—'}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
