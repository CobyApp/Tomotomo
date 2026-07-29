import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/image/image_crop.dart';
import '../../core/locale/languages.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../../core/ui/app_tokens.dart';
import '../../../core/ui/paper/paper_theme.dart';
import '../../../core/ui/paper/paper_tokens.dart';
import '../../../core/ui/paper/paper_loading.dart';
import '../../../core/ui/paper/paper_widgets.dart';
import '../../../data/celebrity_persona/celebrity_persona_suggester.dart';
import '../../../domain/entities/character_record.dart';
import '../../../domain/repositories/character_record_repository.dart';
import '../../../domain/repositories/points_repository.dart';
import '../locale/friend_language_notifier.dart';
import '../locale/l10n_context.dart';
import '../locale/locale_notifier.dart';
import '../points/points_balance_notifier.dart';
import '../points/points_topup_prompt.dart';

/// Single local user id (no auth).
/// Quiet paper-card field decoration shared by every text input on this form.
InputDecoration _paperFieldDecoration(
  BuildContext context, {
  String? labelText,
  String? hintText,
  Widget? prefixIcon,
  bool alignLabelWithHint = false,
}) {
  final p = context.paper;
  final radius = BorderRadius.circular(PaperRadii.button);
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    prefixIcon: prefixIcon,
    alignLabelWithHint: alignLabelWithHint,
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

/// Image provider for either a remote http(s) URL or a local file path.
ImageProvider _avatarImageProvider(String value) {
  if (_isNetworkImagePath(value)) return NetworkImage(value);
  // Built-in friends carry a bundled asset path.
  if (value.startsWith('assets/')) return AssetImage(value);
  return FileImage(File(value));
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

/// Which surface the new-friend create flow is showing:
/// [xImport] is the default (scrape an X profile to build a friend),
/// [summary] reviews the auto-filled result before saving, and
/// [manual] is the de-emphasized "type everything myself" path.
enum _CreatePhase { xImport, summary, manual }

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

  String _language = 'ja';
  String _level = 'intermediate';
  bool _languageInitialized = false;
  bool _saving = false;
  bool _uploadingAvatar = false;
  bool _importUrlBusy = false;
  String? _error;
  String? _avatarUrl;
  _CreatePhase _phase = _CreatePhase.xImport;

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
      _level = r.level;
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
    _language = context.read<FriendLanguageNotifier>().resolve(
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
    super.dispose();
  }

  Future<void> _applyPersonaSuggestion(CelebrityPersonaSuggestion s) async {
    final remoteAvatar = s.avatarUrl?.trim();
    setState(() {
      _nameController.text = s.name;
      _taglineController.text = s.tagline?.trim() ?? '';
      _memoController.text = s.speechStyle ?? '';
      // Pre-select the auto-detected language + level; the summary shows both
      // so the user can still adjust.
      _language = s.language;
      _level = s.level;
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
      10,
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
      // Auto-filled everything: move to the review/summary surface.
      setState(() => _phase = _CreatePhase.summary);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.trRead('characterImportFromXDone'))),
      );
    } catch (e) {
      if (!mounted) return;
      // Localized message only: the underlying exceptions carry hardcoded
      // Korean/English text that would otherwise leak into every language.
      debugPrint('X profile import failed: $e');
      setState(() => _error = context.trRead('characterImportFromXError'));
    } finally {
      if (mounted) setState(() => _importUrlBusy = false);
    }
  }

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
          tagline: tagline.isEmpty ? null : tagline,
          speechStyle: memo.isEmpty ? null : memo,
          avatarUrl: _avatarUrl,
          language: _language,
          level: _level,
        );
        await repo.createCharacter(record);
      } else {
        final updated = CharacterRecord(
          id: existing.id,
          name: name,
          tagline: tagline.isEmpty ? null : tagline,
          speechStyle: memo.isEmpty ? null : memo,
          avatarUrl: _avatarUrl,
          language: _language,
          level: _level,
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
    // Let the user crop/resize (square for avatars). Cancel aborts the change.
    final cropped = await cropImagePath(x.path, square: true);
    if (cropped == null || !mounted) return;
    setState(() {
      _error = null;
      _uploadingAvatar = true;
    });
    try {
      // No server upload: copy the picked file into the app documents dir.
      final path = await _copyAvatarToAppDir(File(cropped));
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
    // Editing an existing friend always uses the manual editable form.
    if (_existing != null) {
      return _buildManualForm(context, isEdit: true);
    }
    switch (_phase) {
      case _CreatePhase.xImport:
        return _buildXImport(context);
      case _CreatePhase.summary:
        return _buildSummary(context);
      case _CreatePhase.manual:
        return _buildManualForm(context, isEdit: false);
    }
  }

  EdgeInsets get _pagePadding => const EdgeInsets.fromLTRB(
    AppSpacing.pageH,
    10,
    AppSpacing.pageH,
    AppSpacing.pageBottom,
  );

  // ── Error banner ─────────────────────────────────────────────
  Widget _errorBanner(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
    );
  }

  // ── Primary CTA that swaps to a spinner while saving ──────────
  Widget _primaryButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    int? costPoints,
  }) {
    return PaperButton(
      icon: icon,
      label: label,
      onPressed: onPressed,
      busy: _saving,
      costPoints: costPoints,
    );
  }

  /// Step back to the X-import step. Lives BELOW the primary action: a
  /// step-back control in the header competes with the screen's own nav bar.
  Widget _stepBackButton(BuildContext context) {
    return Align(
      child: TextButton.icon(
        onPressed: _saving
            ? null
            : () => setState(() {
                _error = null;
                _phase = _CreatePhase.xImport;
              }),
        icon: const Icon(Icons.arrow_back_rounded, size: 18),
        label: Text(context.tr('characterStepBack')),
        style: TextButton.styleFrom(foregroundColor: context.paper.inkSoft),
      ),
    );
  }

  // ── PHASE 1: X import (default entry for a new friend) ────────
  Widget _buildXImport(BuildContext context) {
    final p = context.paper;
    return ListView(
      padding: _pagePadding,
      children: [
        if (_error != null) _errorBanner(context),
        Text(
          context.tr('characterImportFromXLead'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: p.ink,
            fontWeight: FontWeight.w800,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          icon: Icons.link_rounded,
          title: context.tr('characterImportFromXTitle'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr('characterImportFromXLegal'),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: p.inkSoft, height: 1.35),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _xUrlController,
                enabled: !_importUrlBusy,
                decoration: _paperFieldDecoration(
                  context,
                  labelText: context.tr('characterImportFromXHint'),
                  prefixIcon: Icon(Icons.tag_rounded, color: p.coral),
                ),
                keyboardType: TextInputType.url,
                autocorrect: false,
              ),
              const SizedBox(height: 14),
              PaperButton(
                icon: Icons.auto_fix_high_rounded,
                label: context.tr('characterImportFromXButton'),
                onPressed: _importPersonaFromXUrl,
                busy: _importUrlBusy,
                costPoints: 10,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        // De-emphasized secondary path: type everything by hand.
        Center(
          child: TextButton(
            onPressed: _importUrlBusy
                ? null
                : () => setState(() {
                    _error = null;
                    _phase = _CreatePhase.manual;
                  }),
            style: TextButton.styleFrom(foregroundColor: p.inkSoft),
            child: Text(
              context.tr('createManualLink'),
              style: TextStyle(
                color: p.inkSoft,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: p.inkSoft,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // ── PHASE 2: review the auto-filled friend, then save ─────────
  Widget _buildSummary(BuildContext context) {
    final p = context.paper;
    final name = _nameController.text.trim();
    final tagline = _taglineController.text.trim();
    final speech = _memoController.text.trim();
    final hasAvatar = _avatarUrl != null && _avatarUrl!.isNotEmpty;
    return ListView(
      padding: _pagePadding,
      children: [
        if (_error != null) _errorBanner(context),
        Text(
          context.tr('createSummaryTitle'),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: p.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 20),
        if (hasAvatar) ...[
          Center(
            child: PolaroidAvatar(
              size: 132,
              child: Image(
                image: _avatarImageProvider(_avatarUrl!),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 18),
        ],
        Center(
          child: Text(
            name,
            textAlign: TextAlign.center,
            style: cuteDisplay(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: p.ink,
              language: _language,
            ),
          ),
        ),
        if (tagline.isNotEmpty) ...[
          const SizedBox(height: 6),
          Center(
            child: Text(
              tagline,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: p.inkSoft, height: 1.4),
            ),
          ),
        ],
        const SizedBox(height: 22),
        if (speech.isNotEmpty)
          _SectionCard(
            icon: Icons.auto_awesome_rounded,
            title: context.tr('createSummarySpeechLabel'),
            child: Text(
              speech,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: p.ink, height: 1.5),
            ),
          ),
        const SizedBox(height: 16),
        _languageSection(context),
        const SizedBox(height: 16),
        _levelSection(context),
        const SizedBox(height: 28),
        _primaryButton(
          context,
          icon: Icons.check_rounded,
          label: context.tr('createSummarySave'),
          costPoints: 10,
          onPressed: _save,
        ),
        _stepBackButton(context),
        const SizedBox(height: 12),
      ],
    );
  }

  // ── Speaking-level selector (register + difficulty) ───────────
  Widget _levelSection(BuildContext context) {
    final p = context.paper;
    const levels = [
      ('beginner', 'levelBeginner'),
      ('intermediate', 'levelIntermediate'),
      ('advanced', 'levelAdvanced'),
      ('business', 'levelBusiness'),
    ];
    return _SectionCard(
      icon: Icons.school_outlined,
      title: context.tr('levelSectionTitle'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('levelSectionHint'),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: p.inkSoft, height: 1.4),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (value, key) in levels)
                PaperChip(
                  label: context.tr(key),
                  selected: _level == value,
                  onTap: () => setState(() => _level = value),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Friend language selector ──────────────────────────────────
  Widget _languageSection(BuildContext context) {
    final p = context.paper;
    const languages = kSupportedLanguageList;
    return _SectionCard(
      icon: Icons.translate_rounded,
      title: context.tr('friendLangSectionTitle'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('friendLangSectionHint'),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: p.inkSoft, height: 1.4),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in languages)
                PaperChip(
                  label: languageEndonym(value),
                  selected: _language == value,
                  onTap: () => setState(() => _language = value),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Manual editable form (secondary create path + editing) ────
  Widget _buildManualForm(BuildContext context, {required bool isEdit}) {
    final p = context.paper;
    return Form(
      key: _formKey,
      child: ListView(
        padding: _pagePadding,
        children: [
          if (_error != null) _errorBanner(context),
          _buildAvatarPicker(context),
          _SectionCard(
            icon: Icons.person_outline_rounded,
            title: context.tr('characterEditorProfileSection'),
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: _paperFieldDecoration(
                    context,
                    labelText: context.tr('name'),
                    hintText: context.tr('characterNameHint'),
                    prefixIcon: Icon(Icons.badge_outlined, color: p.coral),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? context.tr('nameRequired')
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _taglineController,
                  decoration: _paperFieldDecoration(
                    context,
                    labelText: context.tr('characterTaglineLabel'),
                    hintText: context.tr('characterTaglineHint'),
                    prefixIcon: Icon(
                      Icons.format_quote_rounded,
                      color: p.coral,
                    ),
                  ),
                  maxLength: kTaglineMaxChars,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            icon: Icons.auto_awesome_rounded,
            title: context.tr('characterStepPersonalityTitle'),
            child: Column(
              children: [
                Text(
                  context.tr('characterPersonalityGuide'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: p.inkSoft,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _memoController,
                  decoration: _paperFieldDecoration(
                    context,
                    labelText: context.tr('characterMemo'),
                    hintText: context.tr('characterMemoHint'),
                    alignLabelWithHint: true,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(bottom: 56),
                      child: Icon(Icons.notes_rounded, color: p.coral),
                    ),
                  ),
                  maxLines: 4,
                  minLines: 3,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _languageSection(context),
          const SizedBox(height: 16),
          _levelSection(context),
          const SizedBox(height: 28),
          _primaryButton(
            context,
            icon: Icons.check_rounded,
            label: context.tr(isEdit ? 'save' : 'create'),
            costPoints: isEdit ? null : 10,
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                await _save();
              }
            },
          ),
          if (!isEdit) _stepBackButton(context),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ── Avatar picker (centered, large circle) ────────────────────
  Widget _buildAvatarPicker(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final p = context.paper;
    return Column(
      children: [
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
                    color: (_avatarUrl == null || _avatarUrl!.isEmpty)
                        ? p.paperBg
                        : null,
                    border: (_avatarUrl == null || _avatarUrl!.isEmpty)
                        ? Border.all(color: p.ink, width: 2.5)
                        : null,
                    image: (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                        ? DecorationImage(
                            image: _avatarImageProvider(_avatarUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: p.hardShadow,
                        offset: const Offset(3, 3),
                      ),
                    ],
                  ),
                  child: _uploadingAvatar
                      ? const Center(
                          child: PaperLoading(size: 9, color: Colors.white),
                        )
                      : (_avatarUrl == null || _avatarUrl!.isEmpty)
                      ? Center(
                          child: Icon(
                            Icons.person_rounded,
                            size: 52,
                            color: p.inkSoft.withValues(alpha: 0.75),
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
    );
  }
}

// ── Section card ────────────────────────────────────────────────
/// A selectable pill for the speaking-level choice (coral when selected).

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
    final p = context.paper;
    return PaperCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: p.coral),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.sectionLabel(
                    context,
                  ).copyWith(color: p.ink),
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
