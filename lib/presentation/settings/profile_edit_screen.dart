import 'dart:async';
import '../../core/ui/paper/paper_loading.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../core/ui/app_status_views.dart';
import '../../core/ui/app_tokens.dart';
import '../../core/ui/paper/paper_scaffold.dart';
import '../../core/ui/paper/paper_tokens.dart';
import '../../core/ui/paper/paper_widgets.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../locale/l10n_context.dart';

/// Single local user id (no auth).
const String _localUserId = 'local';

/// Quiet paper-card field decoration shared by every text input on this form.
InputDecoration _paperFieldDecoration(
  BuildContext context, {
  String? labelText,
  String? hintText,
}) {
  final p = context.paper;
  final radius = BorderRadius.circular(PaperRadii.button);
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    filled: true,
    fillColor: p.card,
    labelStyle: TextStyle(color: p.ink, fontWeight: FontWeight.w700),
    floatingLabelStyle: TextStyle(color: p.ink, fontWeight: FontWeight.w800),
    hintStyle: TextStyle(color: p.inkSoft),
    border: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: p.cardEdge),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: p.cardEdge),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: p.coral, width: 2),
    ),
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
  final dest =
      '${avatarsDir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
  await src.copy(dest);
  return dest;
}

/// Edit the local profile display name and gallery avatar.
class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _displayNameController = TextEditingController();

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
      // No server upload: copy the picked file into the app documents dir.
      final path = await _copyAvatarToAppDir(File(x.path));
      if (!mounted) return;
      setState(() {
        _avatarUrl = path;
        _uploadingAvatar = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.trRead('avatarUploadDone'))),
      );
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
      final avatar = _avatarUrl?.trim();
      final updated = Profile(
        id: profile.id,
        displayName: name,
        avatarUrl: avatar == null || avatar.isEmpty ? null : avatar,
        appLanguage: profile.appLanguage,
        learningLanguage: profile.learningLanguage,
        createdAt: profile.createdAt,
        updatedAt: profile.updatedAt,
      );
      await repo.updateProfile(updated);
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.trRead('profileEditSaved'))),
      );
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
    final p = context.paper;
    final Widget body;
    final List<Widget>? actions;

    if (_loading) {
      body = const AppLoadingBody();
      actions = null;
    } else if (_profile == null) {
      body = AppErrorBody(
        message: _error == 'missing'
            ? context.tr('profileEditLoadError')
            : (_error ?? context.tr('profileEditLoadError')),
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
              ? SizedBox(width: 20, height: 20, child: PaperLoading(size: 9))
              : PaperButton(
                  expand: false,
                  icon: Icons.check_rounded,
                  label: context.tr('save'),
                  onPressed: _save,
                ),
        ),
      ];
      body = ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageH,
          AppSpacing.pageTop,
          AppSpacing.pageH,
          AppSpacing.pageBottom,
        ),
        children: [
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: p.coral.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(PaperRadii.card),
                border: Border.all(
                  color: p.coral.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: Text(_error!, style: TextStyle(color: p.ink)),
            ),
            const SizedBox(height: 16),
          ],
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomRight,
              children: [
                GestureDetector(
                  onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
                  child: PolaroidAvatar(
                    size: 120,
                    rotate: -0.03,
                    child: _uploadingAvatar
                        ? SizedBox(
                            width: 28,
                            height: 28,
                            child: PaperLoading(size: 9),
                          )
                        : hasPhoto
                        ? (_isNetworkImagePath(_avatarUrl!.trim())
                              ? Image.network(
                                  _avatarUrl!.trim(),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Icon(
                                    Icons.broken_image_outlined,
                                    size: 40,
                                    color: p.inkSoft,
                                  ),
                                )
                              : Image.file(
                                  File(_avatarUrl!.trim()),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Icon(
                                    Icons.broken_image_outlined,
                                    size: 40,
                                    color: p.inkSoft,
                                  ),
                                ))
                        : Icon(Icons.person_outline, size: 48, color: p.coral),
                  ),
                ),
                Positioned(
                  right: 2,
                  bottom: 6,
                  child: GestureDetector(
                    onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p.coral,
                        border: Border.all(color: p.card, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: p.hardShadow,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
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
                style: TextStyle(color: p.inkSoft, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('profilePhotoGalleryHint'),
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: p.inkSoft),
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: _displayNameController,
            decoration: _paperFieldDecoration(
              context,
              labelText: context.tr('displayNameLabel'),
              hintText: context.tr('displayNameHint'),
            ),
            textCapitalization: TextCapitalization.words,
          ),
        ],
      );
    }

    return PaperScaffold(
      title: context.tr('profileEditTitle'),
      transparentBackground: false,
      actions: actions,
      body: body,
    );
  }
}
