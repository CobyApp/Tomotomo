import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/locale/languages.dart';
import '../../../core/widgets/on_app_resumed_mixin.dart';
import '../../../data/chat_background/chat_background_store.dart';
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
      debugPrint('characters_tab failed: $e');
      if (!mounted) return;
      setState(() {
        if (!silent) _error = context.trRead('commonLoadFailed');
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
    Widget inner;
    if (url != null && url.isNotEmpty) {
      final ImageProvider provider = url.startsWith('http')
          ? NetworkImage(url)
          : url.startsWith('assets/')
          ? AssetImage(url)
          : FileImage(File(url));
      inner = Image(image: provider, fit: BoxFit.cover);
    } else {
      inner = PersonAvatarGlyph(size: size);
    }
    return PolaroidAvatar(size: size, child: inner);
  }

  @override
  Widget build(BuildContext context) {
    // Show every friend regardless of language (no language filter).
    final visibleRecords = _myCharacters;

    return PaperScaffold(
      title: 'トモトモ',
      useWordmark: true,
      showBackground: false,
      actions: (_loading || _error != null)
          ? null
          : [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: PaperRoundButton(
                  icon: Icons.add_rounded,
                  onPressed: _openCreateCharacter,
                  tooltip: context.tr('charactersEmptyMyCta'),
                ),
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
                ...visibleRecords.indexed.map(
                  (e) => PaperEntrance(
                    index: e.$1,
                    child: _recordTile(e.$2, isMine: true),
                  ),
                ),
                if (visibleRecords.isEmpty)
                  PaperEmptyHint(text: context.tr('charactersEmptyMyHint')),
              ],
            ),
    );
  }


  String _levelLabel(String level) => switch (level) {
    'beginner' => context.tr('levelBeginner'),
    'advanced' => context.tr('levelAdvanced'),
    'business' => context.tr('levelBusiness'),
    _ => context.tr('levelIntermediate'),
  };

  Widget _recordTile(CharacterRecord r, {bool isMine = false}) {
    final p = context.paper;
    final tagline = r.tagline?.trim() ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.listGap),
      child: PaperCard(
        onTap: () => _pushChatWithRecord(r),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _recordAvatar(r.avatarUrl, r.name, size: 62),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.name,
                        style: AppTextStyles.listTitle(
                          context,
                          language: r.language,
                        ).copyWith(
                          color: p.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _MiniBadge(
                            label: languageEndonym(r.language),
                            fill: p.stampBlue,
                          ),
                          _MiniBadge(
                            label: _levelLabel(r.level),
                            fill: p.coral,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
                        final chats = context.read<ChatRepository>();
                        final backgrounds = context
                            .read<ChatBackgroundStore>();
                        await context
                            .read<CharacterRecordRepository>()
                            .deleteCharacter(r.id);
                        // The conversation is keyed by the same id. Leaving it
                        // behind left an un-openable row in the Chats tab: the
                        // friend can no longer be resolved, so tapping it only
                        // showed a load error.
                        await chats.deleteRoom(r.id);
                        // And the room's background, whose entry would keep the
                        // picked photo alive on disk.
                        await backgrounds.remove(r.id);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.tr('charactersDeleted')),
                          ),
                        );
                        unawaited(_load());
                      } catch (e) {
                        // The localized message only: appending the exception
                        // put untranslated internals on screen in every
                        // language.
                        debugPrint('Deleting a friend failed: $e');
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              context.tr('charactersDeleteFailed'),
                            ),
                          ),
                        );
                      }
                    },
                    editLabel: context.tr('charactersEdit'),
                    deleteLabel: context.tr('charactersDelete'),
                  ),
              ],
            ),
            if (tagline.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                tagline,
                style: AppTextStyles.listSubtitle(context).copyWith(
                  color: p.coral,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Small filled sticker "badge" (reference style): colored fill, ink border,
/// hard shadow, white text — used for the friend's language and level.
class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label, required this.fill});

  final String label;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: p.ink, width: 1.5),
        boxShadow: [
          BoxShadow(color: p.hardShadow, offset: const Offset(1, 1)),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 11.5,
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
