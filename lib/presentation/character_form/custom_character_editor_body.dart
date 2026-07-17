import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../../core/ui/ui.dart';
import '../../../core/locale/study_language.dart';
import '../../../core/ui/holo/holo_tokens.dart';
import '../../../core/ui/holo/holo_widgets.dart';
import '../../../data/celebrity_persona/celebrity_persona_suggester.dart';
import '../../../domain/entities/character_record.dart';
import '../../../domain/repositories/character_record_repository.dart';
import '../../../domain/repositories/points_repository.dart';
import '../locale/l10n_context.dart';
import '../locale/locale_notifier.dart';
import '../points/points_balance_notifier.dart';
import '../points/points_topup_prompt.dart';

/// Single local user id (no auth).
/// Quiet card field decoration shared by every text input on this form.
InputDecoration _holoFieldDecoration({
  String? labelText,
  String? hintText,
  Widget? prefixIcon,
  bool alignLabelWithHint = false,
}) {
  const radius = BorderRadius.all(Radius.circular(16));
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    prefixIcon: prefixIcon,
    alignLabelWithHint: alignLabelWithHint,
    filled: true,
    fillColor: Holo.surfaceCard,
    labelStyle: const TextStyle(
      color: Holo.inkPlum,
      fontWeight: FontWeight.w700,
    ),
    floatingLabelStyle: const TextStyle(
      color: Holo.inkPlum,
      fontWeight: FontWeight.w800,
    ),
    border: const OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: Holo.border),
    ),
    enabledBorder: const OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: Holo.border),
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: Holo.pink, width: 1.5),
    ),
  );
}

/// True if [value] looks like a remote http(s) URL rather than a local file path.
bool _isNetworkImagePath(String value) {
  final v = value.trim();
  return v.startsWith('http://') || v.startsWith('https://');
}

/// Image provider for either a remote http(s) URL or a local file path.
ImageProvider _avatarImageProvider(String value) {
  return _isNetworkImagePath(value)
      ? NetworkImage(value)
      : FileImage(File(value));
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

Future<String> _cacheRemoteAvatarToAppDir(String url) async {
  final uri = Uri.parse(url);
  final response = await http.get(uri).timeout(const Duration(seconds: 20));
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw HttpException('Avatar HTTP ${response.statusCode}', uri: uri);
  }
  if (response.bodyBytes.isEmpty ||
      response.bodyBytes.length > 8 * 1024 * 1024) {
    throw const FormatException('Invalid avatar image size');
  }
  final contentType = response.headers['content-type']?.toLowerCase() ?? '';
  final ext = contentType.contains('png')
      ? 'png'
      : contentType.contains('webp')
      ? 'webp'
      : 'jpg';
  final dir = await getApplicationDocumentsDirectory();
  final avatarsDir = Directory('${dir.path}/avatars');
  if (!await avatarsDir.exists()) {
    await avatarsDir.create(recursive: true);
  }
  final file = File(
    '${avatarsDir.path}/x_avatar_${DateTime.now().millisecondsSinceEpoch}.$ext',
  );
  await file.writeAsBytes(response.bodyBytes, flush: true);
  return file.path;
}

/// Shared form for [CreateCharacterScreen] and [EditCharacterScreen].
class CustomCharacterEditorBody extends StatefulWidget {
  const CustomCharacterEditorBody({super.key, this.existing});

  /// `null` creates a character; otherwise edits the local record.
  final CharacterRecord? existing;

  @override
  State<CustomCharacterEditorBody> createState() =>
      _CustomCharacterEditorBodyState();
}

class _CustomCharacterEditorBodyState extends State<CustomCharacterEditorBody> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _taglineController = TextEditingController();
  final _memoController = TextEditingController();
  final _xUrlController = TextEditingController();
  final _xPasteController = TextEditingController();

  String _language = 'ja';
  bool _languageInitialized = false;
  bool _saving = false;
  bool _uploadingAvatar = false;
  bool _importUrlBusy = false;
  bool _importPasteBusy = false;
  String? _error;
  String? _avatarUrl;
  int _step = 0;

  CharacterRecord? get _existing => widget.existing;

  @override
  void initState() {
    super.initState();
    final r = _existing;
    if (r != null) {
      _nameController.text = r.name;
      _taglineController.text = r.tagline?.trim() ?? '';
      _memoController.text = r.speechStyle?.trim() ?? '';
      _language = r.language;
      _languageInitialized = true;
      _avatarUrl = (r.avatarUrl != null && r.avatarUrl!.trim().isNotEmpty)
          ? r.avatarUrl
          : null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_languageInitialized) return;
    _language = studyLanguageForApp(
      context.read<LocaleNotifier>().languageCode,
    );
    _languageInitialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taglineController.dispose();
    _memoController.dispose();
    _xUrlController.dispose();
    _xPasteController.dispose();
    super.dispose();
  }

  Future<void> _applyPersonaSuggestion(CelebrityPersonaSuggestion s) async {
    final remoteAvatar = s.avatarUrl?.trim();
    setState(() {
      _nameController.text = s.name;
      _taglineController.text = s.tagline?.trim() ?? '';
      _memoController.text = s.speechStyle ?? '';
      if (remoteAvatar != null && remoteAvatar.isNotEmpty) {
        _avatarUrl = remoteAvatar;
      }
    });
    if (remoteAvatar == null || remoteAvatar.isEmpty) return;
    try {
      final localAvatar = await _cacheRemoteAvatarToAppDir(remoteAvatar);
      if (!mounted || _avatarUrl != remoteAvatar) return;
      setState(() => _avatarUrl = localAvatar);
    } catch (_) {
      // Keep the remote image as a usable fallback if local caching fails.
    }
  }

  Future<bool> _spendPointsForXProfileImport() async {
    final spend = await context.read<PointsRepository>().spendPoints(
      5,
      'x_profile_import',
    );
    if (!spend.ok) {
      if (mounted) {
        setState(() => _error = context.tr('pointsInsufficient'));
        await showPointsTopUpPrompt(context);
      }
      return false;
    }
    if (mounted) {
      context.read<PointsBalanceNotifier>().setBalance(spend.balance);
    }
    return true;
  }

  Future<void> _importPersonaFromXUrl() async {
    final url = _xUrlController.text.trim();
    if (url.isEmpty) {
      setState(
        () => _error = context.trRead('characterImportFromXUrlRequired'),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      _importUrlBusy = true;
    });
    try {
      final okSpend = await _spendPointsForXProfileImport();
      if (!okSpend) return;
      if (!mounted) return;
      final suggester = context.read<CelebrityPersonaSuggester>();
      final s = await suggester.suggestFromXProfileUrl(
        url,
        targetLanguage: _language,
      );
      if (!mounted) return;
      await _applyPersonaSuggestion(s);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.trRead('characterImportFromXDone'))),
      );
    } catch (e) {
      if (!mounted) return;
      final message = '${context.trRead('characterImportFromXError')} $e';
      setState(() => _error = message);
    } finally {
      if (mounted) setState(() => _importUrlBusy = false);
    }
  }

  Future<void> _importPersonaFromPaste() async {
    final raw = _xPasteController.text.trim();
    if (raw.length < 20) {
      setState(() => _error = context.trRead('characterImportFromXPasteHint'));
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      _importPasteBusy = true;
    });
    try {
      final okSpend = await _spendPointsForXProfileImport();
      if (!okSpend) return;
      if (!mounted) return;
      final suggester = context.read<CelebrityPersonaSuggester>();
      final s = await suggester.suggestFromProfileText(
        raw,
        targetLanguage: _language,
      );
      if (!mounted) return;
      await _applyPersonaSuggestion(s);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.trRead('characterImportFromXDone'))),
      );
    } catch (e) {
      if (!mounted) return;
      final message = '${context.trRead('characterImportFromXError')} $e';
      setState(() => _error = message);
    } finally {
      if (mounted) setState(() => _importPasteBusy = false);
    }
  }

  bool get _anyPersonaImportBusy => _importUrlBusy || _importPasteBusy;

  Future<void> _save() async {
    if (_saving) return;
    final existing = _existing;
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
    final tagline = _taglineController.text.trim();
    try {
      final repo = context.read<CharacterRecordRepository>();
      if (existing == null) {
        final spend = await context.read<PointsRepository>().spendPoints(
          10,
          'custom_character_create',
        );
        if (!spend.ok) {
          if (!mounted) return;
          setState(() {
            _error = context.tr('pointsInsufficient');
            _saving = false;
          });
          await showPointsTopUpPrompt(context);
          return;
        }
        if (!mounted) return;
        context.read<PointsBalanceNotifier>().setBalance(spend.balance);
        final record = CharacterRecord.draft(
          name: name,
          nameSecondary: null,
          tagline: tagline.isEmpty ? null : tagline,
          speechStyle: memo.isEmpty ? null : memo,
          avatarUrl: _avatarUrl,
          language: _language,
        );
        await repo.createCharacter(record);
      } else {
        final updated = CharacterRecord(
          id: existing.id,
          name: name,
          nameSecondary: null,
          tagline: tagline.isEmpty ? null : tagline,
          speechStyle: memo.isEmpty ? null : memo,
          avatarUrl: _avatarUrl,
          language: _language,
          createdAt: existing.createdAt,
          updatedAt: DateTime.now(),
        );
        await repo.updateCharacter(updated);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              existing == null ? 'characterCreated' : 'characterUpdated',
            ),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('avatarUploadDone'))));
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stepCount = _existing == null ? 3 : 2;
    final logicalStep = _existing == null ? _step : _step + 1;
    final isLastStep = _step == stepCount - 1;
    final stepTitle = switch (logicalStep) {
      0 => context.tr('characterStepImportTitle'),
      1 => context.tr('characterStepProfileTitle'),
      _ => context.tr('characterStepPersonalityTitle'),
    };

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageH,
          16,
          AppSpacing.pageH,
          AppSpacing.pageBottom,
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(
                        'characterStepProgress',
                        params: {
                          'current': '${_step + 1}',
                          'total': '$stepCount',
                        },
                      ),
                      style: const TextStyle(
                        color: Holo.pink,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      stepTitle,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Holo.inkPlum,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: (_step + 1) / stepCount,
              minHeight: 7,
              backgroundColor: Holo.lilac.withValues(alpha: 0.16),
              valueColor: const AlwaysStoppedAnimation(Holo.pink),
            ),
          ),
          const SizedBox(height: 24),
          // ── Error banner ─────────────────────────────────────
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: BorderRadius.circular(AppRadii.card),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: scheme.onErrorContainer,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: scheme.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Avatar picker (centered, large circle) ─────────────────────
          if (logicalStep == 1) ...[
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: _uploadingAvatar ? null : _pickAvatar,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: (_avatarUrl == null || _avatarUrl!.isEmpty)
                            ? Holo.holoGradient
                            : null,
                        image: (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                            ? DecorationImage(
                                image: _avatarImageProvider(_avatarUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                        boxShadow: Holo.cardShadow,
                      ),
                      child: _uploadingAvatar
                          ? const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
                                strokeCap: StrokeCap.round,
                              ),
                            )
                          : (_avatarUrl == null || _avatarUrl!.isEmpty)
                          ? const Center(
                              child: Icon(
                                Icons.face_rounded,
                                size: 44,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                  ),
                  // Camera badge to re-open the picker.
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: _uploadingAvatar ? null : _pickAvatar,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Holo.pink,
                          border: Border.all(color: Holo.surface, width: 2.5),
                          boxShadow: Holo.cardShadow,
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
            if (_avatarUrl != null && _avatarUrl!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _clearAvatar,
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: Text(context.tr('characterRemoveAvatar')),
                  style: TextButton.styleFrom(foregroundColor: scheme.error),
                ),
              ),
            ],
            const SizedBox(height: 28),
          ],

          if (_existing == null && logicalStep == 0) ...[
            _SectionCard(
              icon: Icons.link_rounded,
              title: context.tr('characterImportFromXTitle'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.tr('characterImportFromXLegal'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Holo.inkPlumSoft,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _xUrlController,
                    enabled: !_anyPersonaImportBusy,
                    decoration: _holoFieldDecoration(
                      labelText: context.tr('characterImportFromXHint'),
                      prefixIcon: const Icon(
                        Icons.tag_rounded,
                        color: Holo.pink,
                      ),
                    ),
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_importUrlBusy) ...[
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Holo.pink,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        HoloButton(
                          icon: Icons.auto_fix_high_rounded,
                          label: _importUrlBusy
                              ? context.tr('characterImportFromXBusy')
                              : context.tr('characterImportFromXButton'),
                          onPressed: _anyPersonaImportBusy
                              ? null
                              : _importPersonaFromXUrl,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    context.tr('characterImportFromXPaste'),
                    style: AppTextStyles.sectionLabel(
                      context,
                    ).copyWith(fontSize: 13, color: Holo.inkPlum),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _xPasteController,
                    enabled: !_anyPersonaImportBusy,
                    maxLines: 5,
                    minLines: 3,
                    decoration: _holoFieldDecoration(
                      hintText: context.tr('characterImportFromXPasteHint'),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_importPasteBusy) ...[
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Holo.pink,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        HoloButton(
                          icon: Icons.content_paste_rounded,
                          label: _importPasteBusy
                              ? context.tr('characterImportFromXBusy')
                              : context.tr('characterImportFromXManualButton'),
                          onPressed: _anyPersonaImportBusy
                              ? null
                              : _importPersonaFromPaste,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Name & memo ───────────────────────────────────
          if (logicalStep > 0)
            _SectionCard(
              icon: logicalStep == 1
                  ? Icons.person_outline_rounded
                  : Icons.auto_awesome_rounded,
              title: logicalStep == 1
                  ? context.tr('characterEditorProfileSection')
                  : context.tr('characterStepPersonalityTitle'),
              child: Column(
                children: [
                  if (logicalStep == 1) ...[
                    TextFormField(
                      controller: _nameController,
                      decoration: _holoFieldDecoration(
                        labelText: context.tr('name'),
                        hintText: context.tr('characterNameHint'),
                        prefixIcon: const Icon(
                          Icons.badge_outlined,
                          color: Holo.pink,
                        ),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? context.tr('nameRequired')
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _taglineController,
                      decoration: _holoFieldDecoration(
                        labelText: context.tr('characterTaglineLabel'),
                        hintText: context.tr('characterTaglineHint'),
                        prefixIcon: const Icon(
                          Icons.format_quote_rounded,
                          color: Holo.pink,
                        ),
                      ),
                      maxLength: 40,
                    ),
                  ],
                  if (logicalStep == 2) ...[
                    Text(
                      context.tr('characterPersonalityGuide'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Holo.inkPlumSoft,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _memoController,
                      decoration: _holoFieldDecoration(
                        labelText: context.tr('characterMemo'),
                        hintText: context.tr('characterMemoHint'),
                        alignLabelWithHint: true,
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 56),
                          child: Icon(Icons.notes_rounded, color: Holo.pink),
                        ),
                      ),
                      maxLines: 4,
                      minLines: 3,
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 28),

          // ── Save button ───────────────────────────────────
          Row(
            children: [
              if (_step > 0) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : () => setState(() => _step--),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: Text(context.tr('characterStepBack')),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _saving
                      ? null
                      : () async {
                          if (!isLastStep) {
                            if (logicalStep == 1 &&
                                !(_formKey.currentState?.validate() ?? false)) {
                              return;
                            }
                            setState(() => _step++);
                            return;
                          }
                          if (_formKey.currentState?.validate() ?? false) {
                            await _save();
                          }
                        },
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          isLastStep
                              ? Icons.check_rounded
                              : Icons.arrow_forward_rounded,
                        ),
                  label: Text(
                    context.tr(
                      isLastStep
                          ? (_existing == null ? 'create' : 'save')
                          : 'characterStepNext',
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Holo.pink,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ── Section card ────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return HoloCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: Holo.pink),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.sectionLabel(
                    context,
                  ).copyWith(color: Holo.inkPlum),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
