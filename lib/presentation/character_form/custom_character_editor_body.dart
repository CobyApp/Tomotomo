import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/storage/character_storage.dart';
import '../../../core/supabase/app_supabase.dart';
import '../../../core/ui/ui.dart';
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
        padding: const EdgeInsets.fromLTRB(AppSpacing.pageH, 16, AppSpacing.pageH, AppSpacing.pageBottom),
        children: [
          // ── 에러 배너 ─────────────────────────────────────
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

          // ── 아바타 피커 (중앙, 큰 원) ─────────────────────
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
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [scheme.primaryContainer, scheme.tertiaryContainer],
                            )
                          : null,
                      image: (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                          ? DecorationImage(image: NetworkImage(_avatarUrl!), fit: BoxFit.cover)
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.18),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: _uploadingAvatar
                        ? Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: scheme.primary,
                              strokeCap: StrokeCap.round,
                            ),
                          )
                        : (_avatarUrl == null || _avatarUrl!.isEmpty)
                            ? Center(
                                child: Icon(Icons.face_rounded, size: 44, color: scheme.primary),
                              )
                            : null,
                  ),
                ),
                // 카메라 뱃지
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
                        color: scheme.primary,
                        border: Border.all(color: scheme.surface, width: 2.5),
                        boxShadow: [
                          BoxShadow(color: scheme.primary.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
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

          // ── 튜터 타입 ─────────────────────────────────────
          _SectionCard(
            emoji: '🌏',
            title: context.tr('characterTutorType'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _LangChip(
                      label: context.tr('characterTutorJaShort'),
                      emoji: '🇯🇵',
                      selected: _language == 'ja',
                      onTap: () => setState(() => _language = 'ja'),
                    ),
                    const SizedBox(width: 10),
                    _LangChip(
                      label: context.tr('characterTutorKoShort'),
                      emoji: '🇰🇷',
                      selected: _language == 'ko',
                      onTap: () => setState(() => _language = 'ko'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(AppRadii.cardSmall),
                  ),
                  child: Text(
                    _language == 'ja' ? context.tr('characterTutorJaHelp') : context.tr('characterTutorKoHelp'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onPrimaryContainer,
                          height: 1.4,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── 이름 & 메모 ───────────────────────────────────
          _SectionCard(
            emoji: '✏️',
            title: context.tr('createCharacterTitle'),
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: _labelDisplayName(context),
                    hintText: _hintDisplayName(context),
                    prefixIcon: Icon(Icons.badge_outlined, color: scheme.primary),
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
                    prefixIcon: Icon(Icons.translate_rounded, color: scheme.primary),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _memoController,
                  decoration: InputDecoration(
                    labelText: context.tr('characterMemo'),
                    hintText: context.tr('characterMemoHint'),
                    alignLabelWithHint: true,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(bottom: 56),
                      child: Icon(Icons.notes_rounded, color: scheme.primary),
                    ),
                  ),
                  maxLines: 4,
                  minLines: 3,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── 공개 설정 ─────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.25)),
            ),
            child: SwitchListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.card)),
              secondary: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isPublic
                      ? scheme.primaryContainer
                      : scheme.surfaceContainerHighest,
                ),
                child: Icon(
                  _isPublic ? Icons.public_rounded : Icons.lock_outline_rounded,
                  size: 20,
                  color: _isPublic ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ),
              title: Text(
                context.tr('publicSwitch'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                _isPublic ? '다른 사용자들도 이 캐릭터를 이용할 수 있어요' : '나만 볼 수 있어요',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              value: _isPublic,
              onChanged: (v) => setState(() => _isPublic = v),
            ),
          ),
          const SizedBox(height: 28),

          // ── 저장 버튼 ─────────────────────────────────────
          FilledButton(
            onPressed: _saving
                ? null
                : () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      await _save();
                    }
                  },
            child: _saving
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_existing == null ? Icons.add_rounded : Icons.check_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(context.tr(_existing == null ? 'create' : 'save')),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ── 섹션 카드 ────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.emoji, required this.title, required this.child});
  final String emoji;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 17)),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.sectionLabel(context)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ── 언어 선택 칩 ──────────────────────────────────────────────
class _LangChip extends StatelessWidget {
  const _LangChip({required this.label, required this.emoji, required this.selected, required this.onTap});
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          color: selected ? scheme.primary : scheme.surfaceContainerHighest,
          boxShadow: selected
              ? [BoxShadow(color: scheme.primary.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 3))]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: selected ? Colors.white : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
