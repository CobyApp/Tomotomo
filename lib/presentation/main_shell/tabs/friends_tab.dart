import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/supabase/app_supabase.dart';
import '../../../core/ui/ui.dart';
import '../../../core/widgets/on_app_resumed_mixin.dart';
import '../../../data/character/characters_data.dart';
import '../../../domain/entities/character.dart';
import '../../../domain/entities/character_record.dart';
import '../../../domain/entities/friend_summary.dart';
import '../../../domain/repositories/ai_chat_repository.dart';
import '../../../domain/repositories/character_record_repository.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../../domain/repositories/friends_repository.dart';
import '../../../domain/repositories/profile_repository.dart';
import '../../character_form/create_character_screen.dart';
import '../../chat/chat_screen.dart';
import '../../locale/l10n_context.dart';
import 'add_friend_tab.dart';
import 'characters_tab.dart';

class FriendsTab extends StatefulWidget {
  const FriendsTab({super.key});

  @override
  FriendsTabState createState() => FriendsTabState();
}

class FriendsTabState extends State<FriendsTab> with WidgetsBindingObserver, OnAppResumedMixin {
  /// Called when the bottom nav selects the Friends tab (refresh lists).
  void reloadFromTabSelection() {
    unawaited(_load(silent: true));
  }

  List<FriendSummary> _friends = [];
  List<CharacterRecord> _myCharacters = [];
  bool _loading = true;
  String? _error;
  bool _localCharactersExpanded = true;
  bool _peopleExpanded = true;

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
      final friendsRepo = context.read<FriendsRepository>();
      final charRepo = context.read<CharacterRecordRepository>();
      final user = AppSupabase.auth.currentUser;
      final list = await friendsRepo.listFriends();
      var myChars = <CharacterRecord>[];
      if (user != null) {
        myChars = await charRepo.getMyCharacters(user.id);
      }
      if (!mounted) return;
      setState(() {
        _friends = list;
        _myCharacters = myChars;
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

  Future<Character?> _dmCharacterForFriend(FriendSummary f) async {
    final chatRepo = context.read<ChatRepository>();
    try {
      final roomId = await chatRepo.ensureDmRoom(f.friendId);
      if (!mounted) return null;
      final profile = await context.read<ProfileRepository>().getProfile(f.friendId);
      if (!mounted) return null;
      final name = profile?.displayName?.trim().isNotEmpty == true
          ? profile!.displayName!
          : f.title;
      return Character.forDirectMessage(
        peerUserId: f.friendId,
        roomId: roomId,
        displayName: name,
        email: profile?.email ?? f.email,
        avatarUrl: profile?.avatarUrl ?? f.avatarUrl,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('friendsDmOpenFailed')}: $e')),
        );
      }
      return null;
    }
  }

  Future<void> _openFriendChat(FriendSummary f) async {
    final character = await _dmCharacterForFriend(f);
    if (!mounted || character == null) return;
    final chatRepo = context.read<ChatRepository>();
    final aiRepo = context.read<AiChatRepository>();
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          character: character,
          chatRepository: chatRepo,
          aiChatRepository: aiRepo,
        ),
      ),
    );
  }

  /// Same bottom sheet for people, built-in AI, and my characters: chat + remove (friend / character / info).
  void _showFriendsTabActionSheet({
    required String title,
    required Future<void> Function() openChat,
    required Future<void> Function() removeAction,
  }) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.pageH, 8, AppSpacing.pageH, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(sheetCtx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(sheetCtx);
                        await openChat();
                      },
                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                      label: Text(sheetCtx.tr('friendsSheetOpenChat')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(sheetCtx).colorScheme.errorContainer,
                        foregroundColor: Theme.of(sheetCtx).colorScheme.onErrorContainer,
                      ),
                      onPressed: () async {
                        Navigator.pop(sheetCtx);
                        await removeAction();
                      },
                      icon: const Icon(Icons.person_remove_outlined),
                      label: Text(sheetCtx.tr('friendsSearchRemoveFriend')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showBuiltinCannotRemoveDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('friendsBuiltinCannotRemoveTitle')),
        content: Text(context.tr('friendsBuiltinCannotRemoveBody')),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr('confirm'))),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteMyCharacter(CharacterRecord r) async {
    final ok = await showDialog<bool>(
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
    if (ok != true || !mounted) return;
    final user = AppSupabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('loginRequired'))));
      return;
    }
    try {
      await context.read<CharacterRecordRepository>().deleteCharacter(r.id, r.ownerId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('charactersDeleted'))));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.tr('charactersDeleteFailed')}: $e')),
      );
    }
  }

  Future<void> _openAiCharacterChat(Character character) async {
    final chatRepo = context.read<ChatRepository>();
    final aiRepo = context.read<AiChatRepository>();
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          character: character,
          chatRepository: chatRepo,
          aiChatRepository: aiRepo,
        ),
      ),
    );
  }

  Future<void> _openRecordChat(CharacterRecord r) async {
    await _openAiCharacterChat(Character.fromRecord(r));
  }

  Future<void> _confirmRemove(FriendSummary f) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('friendsRemoveConfirm')),
        content: Text(f.title),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('charactersDelete'))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<FriendsRepository>().removeFriend(f.friendId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('friendsRemoved'))));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: context.tr('tabFriends'),
      actions: [
        IconButton(
          icon: const Icon(Icons.person_search_rounded),
          tooltip: context.tr('tabAddFriend'),
          onPressed: () {
            Navigator.of(context).push<void>(
              MaterialPageRoute<void>(builder: (_) => const AddFriendTab()),
            );
          },
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
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pageH,
                      12,
                      AppSpacing.pageH,
                      AppSpacing.pageBottom,
                    ),
                    children: [
                      _TutorStudioEntryCard(
                        onOpenStudio: () {
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(builder: (_) => const CharactersTab()),
                          );
                        },
                        onCreateDirect: () async {
                          final created = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(builder: (_) => const CreateCharacterScreen()),
                          );
                          if (created == true && mounted) unawaited(_load(silent: true));
                        },
                      ),
                      const SizedBox(height: 4),
                      AppSectionHeader(
                        title: context.tr('friendsSectionLocalCharacters'),
                        expanded: _localCharactersExpanded,
                        expandLabel: context.tr('friendsSectionExpand'),
                        collapseLabel: context.tr('friendsSectionCollapse'),
                        onToggle: () => setState(() => _localCharactersExpanded = !_localCharactersExpanded),
                      ),
                      if (_localCharactersExpanded) ...[
                        ...characters.map(_builtInCharacterRow),
                        ..._myCharacters.map(_myCharacterRow),
                      ],
                      SizedBox(height: AppSpacing.sectionAfter),
                      AppSectionHeader(
                        title: context.tr('friendsSectionPeople'),
                        expanded: _peopleExpanded,
                        expandLabel: context.tr('friendsSectionExpand'),
                        collapseLabel: context.tr('friendsSectionCollapse'),
                        onToggle: () => setState(() => _peopleExpanded = !_peopleExpanded),
                      ),
                      if (_peopleExpanded) ...[
                        if (_friends.isEmpty)
                          AppEmptyHint(text: context.tr('friendsSectionPeopleEmpty'))
                        else
                          ..._friends.map(_friendTile),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _builtInCharacterRow(Character c) {
    final subtitle = c.displayNameSecondary;
    return AppListRow(
      leading: CircleAvatar(radius: AppSizes.listAvatar, backgroundImage: c.imageProvider),
      title: c.displayNamePrimary,
      subtitle: subtitle.isNotEmpty ? subtitle : null,
      subtitleMaxLines: 1,
      trailing: Icon(Icons.smart_toy_outlined, color: Theme.of(context).colorScheme.tertiary),
      onTap: () => _showFriendsTabActionSheet(
            title: c.displayNamePrimary,
            openChat: () => _openAiCharacterChat(c),
            removeAction: _showBuiltinCannotRemoveDialog,
          ),
    );
  }

  Widget _myCharacterRow(CharacterRecord r) {
    final initial = r.name.isNotEmpty ? r.name.substring(0, 1) : '?';
    final sub = r.listDetailLine.isNotEmpty
        ? r.listDetailLine
        : (r.language == 'ja' ? context.tr('langJa') : context.tr('langKo'));
    return AppListRow(
      leading: CircleAvatar(
        radius: AppSizes.listAvatar,
        foregroundImage: r.avatarUrl != null && r.avatarUrl!.trim().isNotEmpty ? NetworkImage(r.avatarUrl!.trim()) : null,
        child: r.avatarUrl == null || r.avatarUrl!.trim().isEmpty ? Text(initial, style: const TextStyle(fontSize: 18)) : null,
      ),
      title: r.name,
      subtitle: sub,
      trailing: Icon(Icons.smart_toy_outlined, color: Theme.of(context).colorScheme.tertiary),
      onTap: () => _showFriendsTabActionSheet(
            title: r.name,
            openChat: () => _openRecordChat(r),
            removeAction: () => _confirmDeleteMyCharacter(r),
          ),
    );
  }

  Widget _friendTile(FriendSummary f) {
    return AppListRow(
      leading: CircleAvatar(
        radius: AppSizes.listAvatar,
        foregroundImage: f.avatarUrl != null && f.avatarUrl!.trim().isNotEmpty ? NetworkImage(f.avatarUrl!.trim()) : null,
        child: f.avatarUrl == null || f.avatarUrl!.trim().isEmpty
            ? Text(f.title.isNotEmpty ? f.title.substring(0, 1) : '?', style: const TextStyle(fontSize: 18))
            : null,
      ),
      title: f.title,
      subtitle: f.subtitleLine,
      onTap: () => _showFriendsTabActionSheet(
            title: f.title,
            openChat: () => _openFriendChat(f),
            removeAction: () => _confirmRemove(f),
          ),
    );
  }
}

class _TutorStudioEntryCard extends StatelessWidget {
  const _TutorStudioEntryCard({
    required this.onOpenStudio,
    required this.onCreateDirect,
  });

  final VoidCallback onOpenStudio;
  final VoidCallback onCreateDirect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadii.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpenStudio,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.22)),
          ),
          padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.auto_awesome_rounded, color: scheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('friendsTutorStudioBannerTitle'),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('friendsTutorStudioBannerSubtitle'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, height: 1.35),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.fromLTRB(0, 4, 8, 0),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: onCreateDirect,
                        child: Text(context.tr('friendsTutorStudioCreateShortcut')),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(Icons.chevron_right_rounded, color: scheme.outlineVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
