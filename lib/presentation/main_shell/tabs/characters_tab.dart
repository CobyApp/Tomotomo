import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/supabase/app_supabase.dart';
import '../../../core/widgets/on_app_resumed_mixin.dart';
import '../../../domain/entities/character.dart';
import '../../../domain/entities/character_record.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../../domain/repositories/ai_chat_repository.dart';
import '../../../domain/repositories/character_record_repository.dart';
import '../../../domain/repositories/points_repository.dart';
import '../../../core/ui/ui.dart';
import '../../points/points_balance_notifier.dart';
import '../../../data/character/characters_data.dart';
import '../../chat/chat_screen.dart';
import '../../character_form/create_character_screen.dart';
import '../../character_form/edit_character_screen.dart';
import '../../locale/l10n_context.dart';
import '../../tutor_studio/public_character_sheet.dart';

/// My characters (Supabase) + Discover (public) + Built-in characters.
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
  List<CharacterRecord> _publicCharactersRaw = [];
  /// `all` | `ja` | `ko` — filters [discover] list client-side.
  String _publicFilter = 'all';
  bool _loading = true;
  String? _error;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
    final user = AppSupabase.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _myCharacters = [];
        _publicCharactersRaw = [];
      });
      return;
    }
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final repo = context.read<CharacterRecordRepository>();
      final my = await repo.getMyCharacters(user.id);
      final public = await repo.getPublicCharacters();
      if (!mounted) return;
      setState(() {
        _myCharacters = my;
        _publicCharactersRaw = public;
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

  List<CharacterRecord> _visiblePublicList() {
    final uid = AppSupabase.auth.currentUser?.id;
    var list = _publicCharactersRaw.where((r) => uid == null || r.ownerId != uid).toList();
    if (_publicFilter == 'ja') {
      list = list.where((r) => r.language == 'ja').toList();
    } else if (_publicFilter == 'ko') {
      list = list.where((r) => r.language == 'ko').toList();
    }
    return list;
  }

  String _publicDiscoverSubtitle(CharacterRecord r) {
    final tag = r.tagline?.trim();
    final base = (tag != null && tag.isNotEmpty) ? tag : _recordSubtitle(context, r);
    final dl = context.tr('charactersDownloadsLabel', params: {'count': '${r.downloadCount}'});
    return '$base · $dl';
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

  void _openPublicCharacterSheet(CharacterRecord r) {
    unawaited(
      showPublicCharacterSheet(
        context,
        record: r,
        subtitleLine: _publicDiscoverSubtitle(r),
        onStartChat: () => _startChatFromPublic(r),
        onAddToMine: () => _addPublicCharacterToMine(r),
      ),
    );
  }

  /// Own library row forked from [public]; creates one (10P) if missing. Chat always uses this id, not [public.id].
  Future<CharacterRecord?> _ensureMyForkOfPublic(CharacterRecord public) async {
    final user = AppSupabase.auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('loginRequired'))));
      }
      return null;
    }
    final repo = context.read<CharacterRecordRepository>();
    final pointsRepo = context.read<PointsRepository>();
    final pointsNotifier = context.read<PointsBalanceNotifier>();
    final existing = await repo.getMyCloneOfSource(public.id, user.id);
    if (existing != null) return existing;

    final spend = await pointsRepo.spendPoints(10, 'public_character_download');
    if (!spend.ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('pointsInsufficient'))));
      }
      return null;
    }
    if (!mounted) return null;
    pointsNotifier.setBalance(spend.balance);

    final copy = CharacterRecord.draft(
      ownerId: user.id,
      name: public.name,
      nameSecondary: public.nameSecondary,
      avatarUrl: public.avatarUrl,
      tagline: public.tagline,
      speechStyle: public.speechStyle,
      language: public.language,
      isPublic: false,
      clonedFromId: public.id,
    );
    try {
      final created = await repo.createCharacter(copy);
      await repo.incrementDownloadCount(public.id);
      return created;
    } catch (e) {
      final again = await repo.getMyCloneOfSource(public.id, user.id);
      if (again != null) return again;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('charactersAddFailed')}: $e')),
        );
      }
      return null;
    }
  }

  Future<void> _startChatFromPublic(CharacterRecord public) async {
    final mine = await _ensureMyForkOfPublic(public);
    if (!mounted || mine == null) return;
    _pushChatWithRecord(mine);
  }

  /// Adds a fork of [public] to the library (10P once per source); no-op if already forked.
  Future<void> _addPublicCharacterToMine(CharacterRecord public) async {
    final user = AppSupabase.auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('loginRequired'))));
      }
      return;
    }
    final repo = context.read<CharacterRecordRepository>();
    final existing = await repo.getMyCloneOfSource(public.id, user.id);
    if (existing != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('charactersAlreadyForked'))));
      }
      return;
    }
    final created = await _ensureMyForkOfPublic(public);
    if (!mounted || created == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('charactersAdded', params: {'name': public.name}))),
    );
    unawaited(_load());
  }

  // ── avatar 헬퍼 ────────────────────────────────────────────
  Widget _avatarWidget(String? url, String name, {double radius = 28}) {
    final scheme = Theme.of(context).colorScheme;
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(radius: radius, backgroundImage: NetworkImage(url));
    }
    // 이름 첫 글자 + 그라디언트 아바타
    final initial = name.isNotEmpty ? name.substring(0, 1) : '?';
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.tertiary],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: radius * 0.80,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppPageScaffold(
      title: context.tr('charactersTitle'),
      showPointsChip: true,
      bottom: _loading || _error != null
          ? null
          : TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: context.tr('charactersMy')),
                Tab(text: context.tr('charactersDiscover')),
                Tab(text: context.tr('charactersBuiltin')),
              ],
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
          : FloatingActionButton.extended(
              onPressed: () async {
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateCharacterScreen()),
                );
                if (created == true) unawaited(_load());
              },
              icon: const Icon(Icons.add_rounded),
              label: Text(context.tr('create')),
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
                          Text(
                            context.tr('charactersDiscoverHint'),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  height: 1.35,
                                ),
                          ),
                          const SizedBox(height: 12),
                          SegmentedButton<String>(
                            segments: [
                              ButtonSegment<String>(
                                value: 'all',
                                label: Text(context.tr('charactersFilterAll')),
                              ),
                              ButtonSegment<String>(
                                value: 'ja',
                                label: Text(context.tr('langJa')),
                              ),
                              ButtonSegment<String>(
                                value: 'ko',
                                label: Text(context.tr('langKo')),
                              ),
                            ],
                            selected: {_publicFilter},
                            onSelectionChanged: (s) {
                              if (s.isEmpty) return;
                              setState(() => _publicFilter = s.first);
                            },
                          ),
                          const SizedBox(height: 12),
                          if (_visiblePublicList().isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 24, bottom: 20),
                              child: AppEmptyHint(text: context.tr('charactersDiscoverEmpty')),
                            )
                          else
                            ..._visiblePublicList().map((r) => _recordTile(r, isMine: false, isPublicDiscover: true)),
                        ],
                      ),
                    ),
                    RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.pageH, 12, AppSpacing.pageH, 100),
                        children: [
                          Text(
                            context.tr('charactersBuiltin'),
                            style: AppTextStyles.sectionLabel(context),
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

  /// 빌트인 캐릭터 — 2열 그리드 카드
  Widget _builtInGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.78,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: characters.length,
      itemBuilder: (_, i) => _builtInCard(characters[i]),
    );
  }

  Widget _builtInCard(Character c) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            character: c,
            chatRepository: context.read<ChatRepository>(),
            aiChatRepository: context.read<AiChatRepository>(),
          ),
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.card),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.07),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.card),
          child: Material(
            color: scheme.surfaceContainerLow,
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    character: c,
                    chatRepository: context.read<ChatRepository>(),
                    aiChatRepository: context.read<AiChatRepository>(),
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundImage: c.imageProvider,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      c.displayNamePrimary,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (c.displayNameSecondary.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        c.displayNameSecondary,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (c.tagline.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        c.tagline,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.25,
                              fontWeight: FontWeight.w500,
                            ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                      child: Text(
                        context.tr('tabChats'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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

  Widget _recordTile(CharacterRecord r, {bool isMine = false, bool isPublicDiscover = false}) {
    final scheme = Theme.of(context).colorScheme;
    return AppListRow(
      leading: _avatarWidget(r.avatarUrl, r.name, radius: AppSizes.listAvatarLg),
      title: r.name,
      subtitle: isPublicDiscover ? _publicDiscoverSubtitle(r) : _recordSubtitle(context, r),
      subtitleMaxLines: 2,
      trailing: Row(
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
                  await context.read<CharacterRecordRepository>().deleteCharacter(r.id, r.ownerId);
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
          Icon(Icons.chevron_right_rounded, color: scheme.outlineVariant),
        ],
      ),
      onTap: () {
        if (isPublicDiscover) {
          _openPublicCharacterSheet(r);
        } else {
          _pushChatWithRecord(r);
        }
      },
    );
  }
}

// ── 빈 내 캐릭터 카드 ────────────────────────────────────────
class _EmptyMyCharacterCard extends StatelessWidget {
  const _EmptyMyCharacterCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(
            color: scheme.primary.withValues(alpha: 0.30),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          color: scheme.primaryContainer.withValues(alpha: 0.18),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primaryContainer,
              ),
              child: Icon(Icons.add_rounded, color: scheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.tr('charactersEmptyMyCta'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 팝업 메뉴 ────────────────────────────────────────────────
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
      icon: const Icon(Icons.more_vert_rounded),
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
