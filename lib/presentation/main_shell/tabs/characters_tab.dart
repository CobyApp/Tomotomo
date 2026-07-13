import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/on_app_resumed_mixin.dart';
import '../../../domain/entities/character.dart';
import '../../../domain/entities/character_record.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../../domain/repositories/ai_chat_repository.dart';
import '../../../domain/repositories/character_record_repository.dart';
import '../../../core/ui/ui.dart';
import '../../../core/ui/holo/glitch_text.dart';
import '../../../core/ui/holo/holo_tokens.dart';
import '../../../core/ui/holo/holo_widgets.dart';
import '../../../data/character/characters_data.dart';
import '../../chat/chat_screen.dart';
import '../../character_form/create_character_screen.dart';
import '../../character_form/edit_character_screen.dart';
import '../../locale/l10n_context.dart';

/// L10n key for a built-in tutor's one-line blurb (~20 chars, per app language).
String? _builtinCharacterShortKey(String characterId) {
  switch (characterId) {
    case 'yuna':
      return 'friendsBuiltinShortYuna';
    case 'junho':
      return 'friendsBuiltinShortJunho';
    default:
      return null;
  }
}

/// My characters (local) + Built-in characters.
class CharactersTab extends StatefulWidget {
  const CharactersTab({super.key});

  @override
  CharactersTabState createState() => CharactersTabState();
}

class CharactersTabState extends State<CharactersTab>
    with WidgetsBindingObserver, OnAppResumedMixin, SingleTickerProviderStateMixin {
  /// Called when the bottom nav selects the Tutors / characters tab.
  void reloadFromTabSelection() {
    unawaited(_load(silent: true));
  }

  List<CharacterRecord> _myCharacters = [];
  bool _loading = true;
  String? _error;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  // ── avatar helper ────────────────────────────────────────
  Widget _avatarWidget(String? url, String name, {double radius = 28}) {
    Widget inner;
    if (url != null && url.isNotEmpty) {
      inner = CircleAvatar(radius: radius, backgroundColor: Holo.surfaceCard, backgroundImage: NetworkImage(url));
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
    final scheme = Theme.of(context).colorScheme;
    return AppPageScaffold(
      title: context.tr('charactersTitle'),
      showPointsChip: true,
      bottom: _loading || _error != null
          ? null
          : PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.pageH, 0, AppSpacing.pageH, 10),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Holo.surfaceCard,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    border: Border.all(color: Holo.pink.withValues(alpha: 0.25), width: 1.5),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    splashBorderRadius: BorderRadius.circular(AppRadii.pill),
                    indicator: BoxDecoration(
                      gradient: Holo.holoGradient,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Holo.inkPlumSoft,
                    tabs: [
                      Tab(text: context.tr('charactersMy')),
                      Tab(text: context.tr('charactersBuiltin')),
                    ],
                  ),
                ),
              ),
            ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: context.tr('retry'),
          onPressed: _loading ? null : () => unawaited(_load()),
        ),
      ],
      floatingActionButton: _loading || _error != null || _tabController.index != 0
          ? null
          : HoloButton(
              icon: Icons.add_rounded,
              label: context.tr('create'),
              onPressed: () async {
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateCharacterScreen()),
                );
                if (created == true) unawaited(_load());
              },
            ),
      body: _loading
          ? const AppLoadingBody()
          : _error != null
              ? AppErrorBody(message: _error!, onRetry: _load, retryLabel: context.tr('retry'))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.pageH, 12, AppSpacing.pageH, 100),
                        children: [_mySection(scheme)],
                      ),
                    ),
                    RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.pageH, 12, AppSpacing.pageH, 100),
                        children: [
                          GlitchText(
                            context.tr('charactersBuiltin'),
                            style: AppTextStyles.sectionLabel(context),
                            offset: 1.5,
                          ),
                          const SizedBox(height: 12),
                          _builtInGrid(),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _mySection(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        if (_myCharacters.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _EmptyMyCharacterCard(
              onTap: () async {
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateCharacterScreen()),
                );
                if (created == true) unawaited(_load());
              },
            ),
          )
        else ...[
          ..._myCharacters.map((r) => _recordTile(r, isMine: true)),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  /// Built-in characters — 2-column grid cards.
  Widget _builtInGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.62,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: characters.length,
      itemBuilder: (_, i) => _builtInCard(characters[i]),
    );
  }

  Widget _builtInCard(Character c) {
    final builtinShortKey = _builtinCharacterShortKey(c.id);
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
    return HoloCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: openChat,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HoloGradientRing(
                  size: 76,
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: Holo.surfaceCard,
                    backgroundImage: c.imageProvider,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  c.displayNamePrimary,
                  style: const TextStyle(fontWeight: FontWeight.w800, color: Holo.inkPlum),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (c.displayNameSecondary.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    c.displayNameSecondary,
                    style: const TextStyle(color: Holo.inkPlumSoft),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (c.tagline.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    c.tagline,
                    style: const TextStyle(
                      color: Holo.inkPlumSoft,
                      height: 1.25,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (builtinShortKey != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    context.tr(builtinShortKey),
                    style: TextStyle(
                      color: Holo.inkPlumSoft.withValues(alpha: 0.95),
                      height: 1.3,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 10),
                HoloChip(child: Text(context.tr('tabChats'))),
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

  Widget _recordTile(CharacterRecord r, {bool isMine = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.listGap),
      child: HoloCard(
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _pushChatWithRecord(r),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  _avatarWidget(r.avatarUrl, r.name, radius: AppSizes.listAvatarLg),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.name,
                          style: AppTextStyles.listTitle(context).copyWith(color: Holo.inkPlum, fontWeight: FontWeight.w800),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _recordSubtitle(context, r),
                          style: AppTextStyles.listSubtitle(context).copyWith(color: Holo.inkPlumSoft),
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
                              MaterialPageRoute(builder: (_) => EditCharacterScreen(record: r)),
                            );
                            if (updated == true) unawaited(_load());
                          },
                          onDelete: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(context.tr('charactersDeleteTitle')),
                                content: Text(context.tr('charactersDeleteBody', params: {'name': r.name})),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('cancel'))),
                                  FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('charactersDelete'))),
                                ],
                              ),
                            );
                            if (confirm != true || !mounted) return;
                            try {
                              await context.read<CharacterRecordRepository>().deleteCharacter(r.id);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('charactersDeleted'))));
                              unawaited(_load());
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${context.tr('charactersDeleteFailed')}: $e')));
                            }
                          },
                          editLabel: context.tr('charactersEdit'),
                          deleteLabel: context.tr('charactersDelete'),
                        ),
                      Icon(Icons.chevron_right_rounded, color: Holo.inkPlumSoft),
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
          borderRadius: BorderRadius.circular(18),
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
        PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Icons.edit_outlined, size: 18), const SizedBox(width: 10), Text(editLabel)])),
        PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline_rounded, size: 18, color: Theme.of(context).colorScheme.error), const SizedBox(width: 10), Text(deleteLabel, style: TextStyle(color: Theme.of(context).colorScheme.error))])),
      ],
    );
  }
}
