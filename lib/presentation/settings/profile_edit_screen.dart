import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../core/ui/holo/holo_tokens.dart';
import '../../core/ui/holo/holo_widgets.dart';
import '../../core/ui/ui.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../locale/l10n_context.dart';

/// Single local user id (no auth).
const String _localUserId = 'local';

/// Cyan-bordered holo field decoration shared by every text input on this form.
InputDecoration _holoFieldDecoration({String? labelText, String? hintText}) {
  const radius = BorderRadius.all(Radius.circular(18));
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    filled: true,
    fillColor: Holo.surfaceCard,
    labelStyle: const TextStyle(color: Holo.inkPlum, fontWeight: FontWeight.w700),
    floatingLabelStyle: const TextStyle(color: Holo.inkPlum, fontWeight: FontWeight.w800),
    border: const OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: Holo.cyan, width: 2)),
    enabledBorder: const OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: Holo.cyan, width: 2)),
    focusedBorder: const OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: Holo.pink, width: 2.5)),
  );
}

/// True if [value] looks like a remote http(s) URL rather than a local file path.
bool _isNetworkImagePath(String value) {
  final v = value.trim();
  return v.startsWith('http://') || v.startsWith('https://');
}

/// Copies a picked image [src] into the app documents dir, returns the stored path.
Future<String> _copyAvatarToAppDir(File src) async {
  final dir = await getApplicationDocumentsDirectory();
  final avatarsDir = Directory('${dir.path}/avatars');
  if (!await avatarsDir.exists()) {
    await avatarsDir.create(recursive: true);
  }
  final ext = src.path.contains('.') ? src.path.split('.').last : 'jpg';
  final dest = '${avatarsDir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
  await src.copy(dest);
  return dest;
}

/// Edit the local profile (display name, gallery avatar, status). App language: Settings.
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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = context.read<ProfileRepository>();
      final p = await repo.getProfile(_localUserId);
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
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 512, imageQuality: 85);
    if (x == null || !mounted) return;
    setState(() {
      _error = null;
      _uploadingAvatar = true;
    });
    try {
      // No server upload: copy the picked file into the app documents dir.
      final path = await _copyAvatarToAppDir(File(x.path));
      if (!mounted) return;
      setState(() {
        _avatarUrl = path;
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
    if (profile == null) return;
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
        pointBalance: profile.pointBalance,
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
    final Widget body;
    final List<Widget>? actions;

    if (_loading) {
      body = const AppLoadingBody();
      actions = null;
    } else if (_profile == null) {
      body = AppErrorBody(
        message: _error == 'missing' ? context.tr('profileEditLoadError') : (_error ?? context.tr('profileEditLoadError')),
        onRetry: () => unawaited(_load()),
        retryLabel: context.tr('retry'),
      );
      actions = null;
    } else {
      final hasPhoto = _avatarUrl != null && _avatarUrl!.trim().isNotEmpty;
      actions = [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Holo.pink),
                )
              : HoloButton(
                  icon: Icons.check_rounded,
                  label: context.tr('save'),
                  onPressed: _save,
                ),
        ),
      ];
      body = ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.pageH, 16, AppSpacing.pageH, AppSpacing.pageBottom),
        children: [
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Holo.pink.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadii.cardSmall),
                border: Border.all(color: Holo.pink.withValues(alpha: 0.4), width: 2),
              ),
              child: Text(_error!, style: const TextStyle(color: Holo.inkPlum)),
            ),
            const SizedBox(height: 16),
          ],
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                HoloGradientRing(
                  size: 112,
                  child: Material(
                    color: Holo.surfaceCard,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
                      child: SizedBox(
                        width: 112,
                        height: 112,
                        child: _uploadingAvatar
                            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Holo.pink))
                            : hasPhoto
                                ? (_isNetworkImagePath(_avatarUrl!.trim())
                                    ? Image.network(
                                        _avatarUrl!.trim(),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => const Icon(
                                          Icons.broken_image_outlined,
                                          size: 40,
                                          color: Holo.inkPlumSoft,
                                        ),
                                      )
                                    : Image.file(
                                        File(_avatarUrl!.trim()),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => const Icon(
                                          Icons.broken_image_outlined,
                                          size: 40,
                                          color: Holo.inkPlumSoft,
                                        ),
                                      ))
                                : const Icon(Icons.person_outline, size: 48, color: Holo.inkPlumSoft),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Holo.pink,
                        border: Border.all(color: Holo.surface, width: 2.5),
                        boxShadow: Holo.cardShadow,
                      ),
                      child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                    ),
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
              child: Text(
                context.tr('profileEditClearPhoto'),
                style: const TextStyle(color: Holo.inkPlumSoft, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('profilePhotoGalleryHint'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Holo.inkPlumSoft),
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: _displayNameController,
            decoration: _holoFieldDecoration(
              labelText: context.tr('displayNameLabel'),
              hintText: context.tr('displayNameHint'),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _statusMessageController,
            decoration: _holoFieldDecoration(
              labelText: context.tr('profileStatusMessageLabel'),
              hintText: context.tr('profileStatusMessageHint'),
            ),
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      );
    }

    return AppPageScaffold(
      title: context.tr('profileEditTitle'),
      subtitle: context.tr('profileEditSubtitle'),
      transparentBackground: false,
      actions: actions,
      body: body,
    );
  }
}
