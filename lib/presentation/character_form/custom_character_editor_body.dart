import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../../core/ui/ui.dart';
import '../../../core/ui/holo/holo_tokens.dart';
import '../../../core/ui/holo/holo_widgets.dart';
import '../../../data/celebrity_persona/celebrity_persona_suggester.dart';
import '../../../domain/entities/character_record.dart';
import '../../../domain/repositories/character_record_repository.dart';
import '../../../domain/repositories/points_repository.dart';
import '../locale/l10n_context.dart';
import '../points/points_balance_notifier.dart';
import '../points/points_topup_prompt.dart';

/// Single local user id (no auth).
const String _localUserId = 'local';

/// Cyan-bordered holo field decoration shared by every text input on this form.
InputDecoration _holoFieldDecoration({
  String? labelText,
  String? hintText,
  Widget? prefixIcon,
  bool alignLabelWithHint = false,
}) {
  const radius = BorderRadius.all(Radius.circular(18));
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    prefixIcon: prefixIcon,
    alignLabelWithHint: alignLabelWithHint,
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

/// Image provider for either a remote http(s) URL or a local file path.
ImageProvider _avatarImageProvider(String value) {
  return _isNetworkImagePath(value) ? NetworkImage(value) : FileImage(File(value));
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
  final _taglineController = TextEditingController();
  final _memoController = TextEditingController();
  final _xUrlController = TextEditingController();
  final _xPasteController = TextEditingController();

  String _language = 'ja';
  bool _isPublic = false;
  bool _saving = false;
  bool _uploadingAvatar = false;
  bool _importUrlBusy = false;
  bool _importPasteBusy = false;
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
      _taglineController.text = r.tagline?.trim() ?? '';
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
    _taglineController.dispose();
    _memoController.dispose();
    _xUrlController.dispose();
    _xPasteController.dispose();
    super.dispose();
  }

  void _applyPersonaSuggestion(CelebrityPersonaSuggestion s) {
    setState(() {
      _nameController.text = s.name;
      _nameSecondaryController.text = s.nameSecondary ?? '';
      _taglineController.text = s.tagline?.trim() ?? '';
      _memoController.text = s.speechStyle ?? '';
      _language = s.language == 'ko' ? 'ko' : 'ja';
      final u = s.avatarUrl?.trim();
      if (u != null && u.isNotEmpty) {
        _avatarUrl = u;
      }
    });
  }

  Future<bool> _spendPointsForXProfileImport() async {
    final spend = await context.read<PointsRepository>().spendPoints(5, 'x_profile_import');
    if (!spend.ok) {
      if (mounted) {
        setState(() => _error = context.tr('pointsInsufficient'));
        await showPointsTopUpPrompt(context);
      }
      return false;
    }
    if (mounted) context.read<PointsBalanceNotifier>().setBalance(spend.balance);
    return true;
  }

  Future<void> _importPersonaFromXUrl() async {
    final url = _xUrlController.text.trim();
    if (url.isEmpty) {
      setState(() => _error = context.trRead('characterImportFromXUrlRequired'));
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
      final s = await suggester.suggestFromXProfileUrl(url);
      if (!mounted) return;
      _applyPersonaSuggestion(s);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.trRead('characterImportFromXDone'))));
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
      final s = await suggester.suggestFromProfileText(raw);
      if (!mounted) return;
      _applyPersonaSuggestion(s);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.trRead('characterImportFromXDone'))));
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
    final secondary = _nameSecondaryController.text.trim();
    try {
      final repo = context.read<CharacterRecordRepository>();
      if (existing == null) {
        final spend = await context.read<PointsRepository>().spendPoints(10, 'custom_character_create');
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
          ownerId: _localUserId,
          name: name,
          nameSecondary: secondary.isEmpty ? null : secondary,
          tagline: tagline.isEmpty ? null : tagline,
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
          tagline: tagline.isEmpty ? null : tagline,
          speechStyle: memo.isEmpty ? null : memo,
          avatarUrl: _avatarUrl,
          language: _language,
          isPublic: _isPublic,
          clonedFromId: existing.clonedFromId,
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
        padding: const EdgeInsets.fromLTRB(AppSpacing.pageH, 16, AppSpacing.pageH, AppSpacing.pageBottom),
        children: [
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
                  Icon(Icons.error_outline_rounded, color: scheme.onErrorContainer, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_error!, style: TextStyle(color: scheme.onErrorContainer, fontWeight: FontWeight.w600))),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Avatar picker (centered, large circle) ─────────────────────
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
                      gradient: (_avatarUrl == null || _avatarUrl!.isEmpty) ? Holo.holoGradient : null,
                      image: (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                          ? DecorationImage(image: _avatarImageProvider(_avatarUrl!), fit: BoxFit.cover)
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
                                child: Icon(Icons.face_rounded, size: 44, color: Colors.white),
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
                      child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
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

          if (_existing == null) ...[
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
                      prefixIcon: const Icon(Icons.tag_rounded, color: Holo.pink),
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
                            child: CircularProgressIndicator(strokeWidth: 2, color: Holo.pink),
                          ),
                          const SizedBox(width: 10),
                        ],
                        HoloButton(
                          icon: Icons.auto_fix_high_rounded,
                          label: _importUrlBusy
                              ? context.tr('characterImportFromXBusy')
                              : context.tr('characterImportFromXButton'),
                          onPressed: _anyPersonaImportBusy ? null : _importPersonaFromXUrl,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    context.tr('characterImportFromXPaste'),
                    style: AppTextStyles.sectionLabel(context).copyWith(fontSize: 13, color: Holo.inkPlum),
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
                            child: CircularProgressIndicator(strokeWidth: 2, color: Holo.pink),
                          ),
                          const SizedBox(width: 10),
                        ],
                        HoloButton(
                          icon: Icons.content_paste_rounded,
                          label: _importPasteBusy
                              ? context.tr('characterImportFromXBusy')
                              : context.tr('characterImportFromXManualButton'),
                          onPressed: _anyPersonaImportBusy ? null : _importPersonaFromPaste,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Tutor type ─────────────────────────────────────
          _SectionCard(
            icon: Icons.translate_rounded,
            title: context.tr('characterTutorType'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _LangChip(
                      codeLabel: 'JA',
                      label: context.tr('characterTutorJaShort'),
                      selected: _language == 'ja',
                      onTap: () => setState(() => _language = 'ja'),
                    ),
                    const SizedBox(width: 10),
                    _LangChip(
                      codeLabel: 'KO',
                      label: context.tr('characterTutorKoShort'),
                      selected: _language == 'ko',
                      onTap: () => setState(() => _language = 'ko'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Holo.lilac.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(AppRadii.cardSmall),
                  ),
                  child: Text(
                    _language == 'ja' ? context.tr('characterTutorJaHelp') : context.tr('characterTutorKoHelp'),
                    style: const TextStyle(
                      color: Holo.inkPlum,
                      height: 1.4,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Name & memo ───────────────────────────────────
          _SectionCard(
            icon: Icons.person_outline_rounded,
            title: context.tr('characterEditorProfileSection'),
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: _holoFieldDecoration(
                    labelText: _labelDisplayName(context),
                    hintText: _hintDisplayName(context),
                    prefixIcon: const Icon(Icons.badge_outlined, color: Holo.pink),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => (v == null || v.trim().isEmpty) ? context.tr('nameRequired') : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameSecondaryController,
                  decoration: _holoFieldDecoration(
                    labelText: _labelAltName(context),
                    hintText: _hintAltName(context),
                    prefixIcon: const Icon(Icons.translate_rounded, color: Holo.pink),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _taglineController,
                  decoration: _holoFieldDecoration(
                    labelText: context.tr('characterTaglineLabel'),
                    hintText: context.tr('characterTaglineHint'),
                    prefixIcon: const Icon(Icons.format_quote_rounded, color: Holo.pink),
                  ),
                  maxLength: 40,
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
            ),
          ),
          const SizedBox(height: 16),

          // ── Public visibility toggle ───────────────────────────────────
          HoloCard(
            padding: EdgeInsets.zero,
            child: SwitchListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              secondary: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _isPublic ? Holo.holoGradient : null,
                  color: _isPublic ? null : Holo.surfaceCard,
                  border: _isPublic ? null : Border.all(color: Holo.cyan, width: 2),
                ),
                child: Icon(
                  _isPublic ? Icons.public_rounded : Icons.lock_outline_rounded,
                  size: 20,
                  color: _isPublic ? Colors.white : Holo.inkPlumSoft,
                ),
              ),
              title: Text(
                context.tr('publicSwitch'),
                style: const TextStyle(fontWeight: FontWeight.w700, color: Holo.inkPlum),
              ),
              subtitle: Text(
                _isPublic ? context.tr('characterPublicOnSubtitle') : context.tr('characterPublicOffSubtitle'),
                style: const TextStyle(color: Holo.inkPlumSoft),
              ),
              value: _isPublic,
              activeThumbColor: Holo.pink,
              onChanged: (v) => setState(() => _isPublic = v),
            ),
          ),
          const SizedBox(height: 28),

          // ── Save button ───────────────────────────────────
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_saving) ...[
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Holo.pink),
                  ),
                  const SizedBox(width: 10),
                ],
                HoloButton(
                  icon: _existing == null ? Icons.add_rounded : Icons.check_rounded,
                  label: context.tr(_existing == null ? 'create' : 'save'),
                  onPressed: _saving
                      ? null
                      : () async {
                          if (_formKey.currentState?.validate() ?? false) {
                            await _save();
                          }
                        },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ── Section card ────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.icon, required this.title, required this.child});

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
              Expanded(child: Text(title, style: AppTextStyles.sectionLabel(context).copyWith(color: Holo.inkPlum))),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ── Language selector chip ──────────────────────────────────────────────
class _LangChip extends StatelessWidget {
  const _LangChip({
    required this.codeLabel,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String codeLabel;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          gradient: selected ? Holo.holoGradient : null,
          color: selected ? null : Holo.surfaceCard,
          border: selected ? null : Border.all(color: Holo.cyan, width: 2),
          boxShadow: selected ? Holo.cardShadow : const [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: selected ? Colors.white.withValues(alpha: 0.22) : Holo.lilac.withValues(alpha: 0.20),
              ),
              child: Text(
                codeLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 0.4,
                  color: selected ? Colors.white : Holo.inkPlumSoft,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: selected ? Colors.white : Holo.inkPlumSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
