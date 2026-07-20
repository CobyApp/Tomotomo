import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/on_app_resumed_mixin.dart';
import '../../../domain/entities/character.dart';
import '../../../domain/entities/character_record.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../../domain/repositories/ai_chat_repository.dart';
import '../../../domain/repositories/character_record_repository.dart';
import '../../../core/ui/ui.dart';
import '../../../core/ui/paper/paper_tokens.dart';
import '../../../core/ui/paper/paper_widgets.dart';
import '../../../core/ui/paper/paper_dialog.dart';
import '../../../core/ui/paper/paper_scaffold.dart';
import '../../../core/ui/paper/paper_status_views.dart';
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

  // ── avatar helper ─────────────────────────────────────────
  Widget _recordAvatar(String? url, String name, {double size = 60}) {
    final p = context.paper;
    Widget inner;
    if (url != null && url.isNotEmpty) {
      final ImageProvider provider = url.startsWith('http')
          ? NetworkImage(url)
          : url.startsWith('assets/')
          ? AssetImage(url)
          : FileImage(File(url));
      inner = Image(image: provider, fit: BoxFit.cover);
    } else {
      final initial = name.isNotEmpty ? name.substring(0, 1) : '?';
      inner = Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: size * 0.42,
            fontWeight: FontWeight.w800,
            color: p.coral,
          ),
        ),
      );
    }
    return PolaroidAvatar(size: size, child: inner);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    // Show every friend regardless of language (no language filter).
    final visibleRecords = _myCharacters;

    return PaperScaffold(
      title: 'トモトモ',
      useWordmark: true,
      actions: (_loading || _error != null)
          ? null
          : [
              IconButton(
                onPressed: _openCreateCharacter,
                icon: const Icon(Icons.person_add_alt_1_rounded),
                color: p.coral,
                tooltip: context.tr('charactersEmptyMyCta'),
              ),
            ],
      body: _loading
          ? const PaperLoadingBody()
          : _error != null
          ? PaperErrorBody(
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
                ...visibleRecords.map(
                  (record) => _recordTile(record, isMine: true),
                ),
                if (visibleRecords.isEmpty)
                  PaperEmptyHint(text: context.tr('charactersEmptyMyHint')),
              ],
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
    final p = context.paper;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.listGap),
      child: PaperCard(
        onTap: () => _pushChatWithRecord(r),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _recordAvatar(r.avatarUrl, r.name),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.name,
                    style: AppTextStyles.listTitle(context).copyWith(
                      color: p.ink,
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
                      style: AppTextStyles.listSubtitle(
                        context,
                      ).copyWith(color: p.coral, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    _recordBio(r),
                    style: AppTextStyles.listSubtitle(
                      context,
                    ).copyWith(color: p.inkSoft, height: 1.4),
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
                      final confirm = await showPaperConfirm(
                        context,
                        title: context.tr('charactersDeleteTitle'),
                        message: context.tr(
                          'charactersDeleteBody',
                          params: {'name': r.name},
                        ),
                        confirmLabel: context.tr('charactersDelete'),
                        destructive: true,
                      );
                      if (!confirm || !mounted) return;
                      try {
                        await context
                            .read<CharacterRecordRepository>()
                            .deleteCharacter(r.id);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.tr('charactersDeleted')),
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
                Icon(Icons.chevron_right_rounded, color: p.inkSoft),
              ],
            ),
          ],
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
    final p = context.paper;
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, color: p.inkSoft),
      color: p.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: p.cardEdge),
      ),
      onSelected: (v) {
        if (v == 'edit') onEdit();
        if (v == 'delete') onDelete();
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18, color: p.ink),
              const SizedBox(width: 10),
              Text(editLabel, style: TextStyle(color: p.ink)),
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
