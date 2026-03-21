import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/supabase/app_supabase.dart';
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
import '../../chat/chat_screen.dart';
import '../../locale/l10n_context.dart';

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
    _load();
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

  void _showFriendQuickSheet(FriendSummary f) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                f.title,
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
                      onPressed: () {
                        Navigator.pop(sheetCtx);
                        unawaited(_openFriendChat(f));
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
                      onPressed: () {
                        Navigator.pop(sheetCtx);
                        unawaited(_confirmRemove(f));
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
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('tabFriends')),
        centerTitle: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: _load, child: Text(context.tr('retry'))),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      _collapsibleSectionHeader(
                        context,
                        title: context.tr('friendsSectionLocalCharacters'),
                        expanded: _localCharactersExpanded,
                        onToggle: () => setState(() => _localCharactersExpanded = !_localCharactersExpanded),
                      ),
                      if (_localCharactersExpanded) ...[
                        ...characters.map((c) => _builtInCharacterRow(c)),
                        ..._myCharacters.map(_myCharacterRow),
                      ],
                      const SizedBox(height: 8),
                      _collapsibleSectionHeader(
                        context,
                        title: context.tr('friendsSectionPeople'),
                        expanded: _peopleExpanded,
                        onToggle: () => setState(() => _peopleExpanded = !_peopleExpanded),
                      ),
                      if (_peopleExpanded) ...[
                        if (_friends.isEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
                            child: Text(
                              context.tr('friendsSectionPeopleEmpty'),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          )
                        else
                          ..._friends.map(_friendTile),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _collapsibleSectionHeader(
    BuildContext context, {
    required String title,
    required bool expanded,
    required VoidCallback onToggle,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 0, right: 0, bottom: 12, top: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                  ),
                ),
                Icon(
                  expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  color: scheme.onSurfaceVariant,
                  size: 26,
                ),
                const SizedBox(width: 4),
                Text(
                  expanded ? context.tr('friendsSectionCollapse') : context.tr('friendsSectionExpand'),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _builtInCharacterRow(Character c) {
    final scheme = Theme.of(context).colorScheme;
    final subtitle = c.displayNameSecondary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: scheme.surface,
        elevation: 0,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openAiCharacterChat(c),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(radius: 26, backgroundImage: c.imageProvider),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.displayNamePrimary,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(Icons.smart_toy_outlined, color: scheme.tertiary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _myCharacterRow(CharacterRecord r) {
    final scheme = Theme.of(context).colorScheme;
    final initial = r.name.isNotEmpty ? r.name.substring(0, 1) : '?';
    final sub = r.listDetailLine.isNotEmpty
        ? r.listDetailLine
        : (r.language == 'ja' ? context.tr('langJa') : context.tr('langKo'));
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: scheme.surface,
        elevation: 0,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openRecordChat(r),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    foregroundImage: r.avatarUrl != null && r.avatarUrl!.trim().isNotEmpty
                        ? NetworkImage(r.avatarUrl!.trim())
                        : null,
                    child: r.avatarUrl == null || r.avatarUrl!.trim().isEmpty ? Text(initial, style: const TextStyle(fontSize: 18)) : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          sub,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.smart_toy_outlined, color: scheme.tertiary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _friendTile(FriendSummary f) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: scheme.surface,
        elevation: 0,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showFriendQuickSheet(f),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    foregroundImage: f.avatarUrl != null && f.avatarUrl!.trim().isNotEmpty
                        ? NetworkImage(f.avatarUrl!.trim())
                        : null,
                    child: f.avatarUrl == null || f.avatarUrl!.trim().isEmpty
                        ? Text(f.title.isNotEmpty ? f.title.substring(0, 1) : '?', style: const TextStyle(fontSize: 18))
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          f.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          f.subtitleLine,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
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
