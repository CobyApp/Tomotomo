import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/on_app_resumed_mixin.dart';
import '../../../core/locale/study_language.dart';
import '../../../domain/entities/character.dart';
import '../../../domain/entities/character_record.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../../domain/repositories/ai_chat_repository.dart';
import '../../../domain/repositories/character_record_repository.dart';
import '../../../core/ui/ui.dart';
import '../../../core/ui/holo/holo_tokens.dart';
import '../../../core/ui/holo/holo_widgets.dart';
import '../../../data/character/characters_data.dart';
import '../../chat/chat_screen.dart';
import '../../character_form/create_character_screen.dart';
import '../../character_form/edit_character_screen.dart';
import '../../locale/l10n_context.dart';

/// Language-filtered custom and built-in tutors in one messenger-style list.
class CharactersTab extends StatefulWidget {
  const CharactersTab({super.key});

  @override
  CharactersTabState createState() => CharactersTabState();
}

class CharactersTabState extends State<CharactersTab>
    with WidgetsBindingObserver, OnAppResumedMixin {
  /// Called when the bottom nav selects the Tutors / characters tab.
  void reloadFromTabSelection() {
    unawaited(_load(silent: true));
  }

  List<CharacterRecord> _myCharacters = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  @override
  void onAppResumed() => unawaited(_load(silent: true));

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final repo = context.read<CharacterRecordRepository>();
      final my = await repo.getMyCharacters();
      if (!mounted) return;
      setState(() {
        _myCharacters = my;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (!silent) _error = e.toString();
        _loading = false;
      });
    }
  }

  void _pushChatWithRecord(CharacterRecord r) {
    final character = Character.fromRecord(r);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          character: character,
          chatRepository: context.read<ChatRepository>(),
          aiChatRepository: context.read<AiChatRepository>(),
        ),
      ),
    );
  }

  Future<void> _openCreateCharacter() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateCharacterScreen()),
    );
    if (created == true) unawaited(_load());
  }

  // ── avatar helper ────────────────────────────────────────
  Widget _avatarWidget(String? url, String name, {double radius = 28}) {
    Widget inner;
    if (url != null && url.isNotEmpty) {
      inner = CircleAvatar(
        radius: radius,
        backgroundColor: Holo.surfaceCard,
        backgroundImage: url.startsWith('http')
            ? NetworkImage(url)
            : FileImage(File(url)) as ImageProvider,
      );
    } else {
      // Initial letter avatar on a holo card backdrop.
      final initial = name.isNotEmpty ? name.substring(0, 1) : '?';
      inner = CircleAvatar(
        radius: radius,
        backgroundColor: Holo.surfaceCard,
        child: Text(
          initial,
          style: TextStyle(
            fontSize: radius * 0.80,
            fontWeight: FontWeight.w800,
            color: Holo.inkPlum,
          ),
        ),
      );
    }
    return HoloGradientRing(size: radius * 2 + 4, child: inner);
  }

  @override
  Widget build(BuildContext context) {
    final targetLanguage = studyLanguageForApp(
      Localizations.localeOf(context).languageCode,
    );
    final visibleRecords = _myCharacters
        .where((record) => record.language == targetLanguage)
        .toList(growable: false);
    final visibleBuiltIns = characters
        .where(
          (character) =>
              (character.koreanNationalPersona ? 'ko' : 'ja') == targetLanguage,
        )
        .toList(growable: false);

    return AppPageScaffold(
      title: context.tr('charactersTitle'),
      actions: [
        IconButton(
          tooltip: context.tr('charactersEmptyMyCta'),
          onPressed: _loading || _error != null ? null : _openCreateCharacter,
          icon: const Icon(Icons.person_add_alt_1_rounded),
        ),
      ],
      body: _loading
          ? const AppLoadingBody()
          : _error != null
          ? AppErrorBody(
              message: _error!,
              onRetry: _load,
              retryLabel: context.tr('retry'),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageH,
                AppSpacing.pageTop,
                AppSpacing.pageH,
                100,
              ),
              children: [
                ...visibleBuiltIns.map(_builtInTile),
                ...visibleRecords.map(
                  (record) => _recordTile(record, isMine: true),
                ),
                if (visibleRecords.isEmpty)
                  _EmptyMyCharacterCard(onTap: _openCreateCharacter),
              ],
            ),
    );
  }

  Widget _builtInTile(Character c) {
    void openChat() => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          character: c,
          chatRepository: context.read<ChatRepository>(),
          aiChatRepository: context.read<AiChatRepository>(),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: HoloCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.card),
          onTap: openChat,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                HoloGradientRing(
                  size: 82,
                  child: CircleAvatar(
                    radius: 38,
                    backgroundColor: Holo.surfaceCard,
                    backgroundImage: c.imageProvider,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.displayNamePrimary,
                        style: AppTextStyles.listTitle(
                          context,
                        ).copyWith(fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        c.tagline.isNotEmpty ? c.tagline : c.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.listSubtitle(
                          context,
                        ).copyWith(height: 1.4, color: Holo.inkPlumSoft),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Holo.inkPlumSoft,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _recordSubtitle(BuildContext context, CharacterRecord r) {
    final line = r.listDetailLine;
    if (line.isNotEmpty) return line;
    return r.language == 'ja' ? context.tr('langJa') : context.tr('langKo');
  }

  String _recordBio(CharacterRecord r) {
    final memo = r.speechStyle?.trim() ?? '';
    if (memo.isEmpty) return _recordSubtitle(context, r);
    final lines = memo
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && !line.startsWith('【'));
    return lines.isEmpty ? _recordSubtitle(context, r) : lines.first;
  }

  Widget _recordTile(CharacterRecord r, {bool isMine = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.listGap),
      child: HoloCard(
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.card),
            onTap: () => _pushChatWithRecord(r),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  _avatarWidget(r.avatarUrl, r.name, radius: 38),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.name,
                          style: AppTextStyles.listTitle(context).copyWith(
                            color: Holo.inkPlum,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if ((r.tagline?.trim().isNotEmpty ?? false))
                          Text(
                            r.tagline!.trim(),
                            style: AppTextStyles.listSubtitle(context).copyWith(
                              color: Holo.inkPlum,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 4),
                        Text(
                          _recordBio(r),
                          style: AppTextStyles.listSubtitle(
                            context,
                          ).copyWith(color: Holo.inkPlumSoft, height: 1.4),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isMine)
                        _RecordMenu(
                          onEdit: () async {
                            final updated = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditCharacterScreen(record: r),
                              ),
                            );
                            if (updated == true) unawaited(_load());
                          },
                          onDelete: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(
                                  context.tr('charactersDeleteTitle'),
                                ),
                                content: Text(
                                  context.tr(
                                    'charactersDeleteBody',
                                    params: {'name': r.name},
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: Text(context.tr('cancel')),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: Text(context.tr('charactersDelete')),
                                  ),
                                ],
                              ),
                            );
                            if (confirm != true || !mounted) return;
                            try {
                              await context
                                  .read<CharacterRecordRepository>()
                                  .deleteCharacter(r.id);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    context.tr('charactersDeleted'),
                                  ),
                                ),
                              );
                              unawaited(_load());
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${context.tr('charactersDeleteFailed')}: $e',
                                  ),
                                ),
                              );
                            }
                          },
                          editLabel: context.tr('charactersEdit'),
                          deleteLabel: context.tr('charactersDelete'),
                        ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Holo.inkPlumSoft,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Empty "my character" card ────────────────────────────────
class _EmptyMyCharacterCard extends StatelessWidget {
  const _EmptyMyCharacterCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HoloCard(
      dashed: true,
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.card),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: Holo.holoGradient,
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.tr('charactersEmptyMyCta'),
                    style: const TextStyle(
                      color: Holo.inkPlum,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Popup menu ────────────────────────────────────────────────
class _RecordMenu extends StatelessWidget {
  const _RecordMenu({
    required this.onEdit,
    required this.onDelete,
    required this.editLabel,
    required this.deleteLabel,
  });
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String editLabel;
  final String deleteLabel;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: Holo.inkPlumSoft),
      color: Holo.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      onSelected: (v) {
        if (v == 'edit') onEdit();
        if (v == 'delete') onDelete();
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit_outlined, size: 18),
              const SizedBox(width: 10),
              Text(editLabel),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 10),
              Text(
                deleteLabel,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
