import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/supabase/app_supabase.dart';
import '../../../core/widgets/on_app_resumed_mixin.dart';
import '../../../domain/entities/character_record.dart';
import '../../../domain/entities/friend_search_pick.dart';
import '../../../domain/entities/friend_summary.dart';
import '../../../domain/entities/user_profile_search_result.dart';
import '../../../domain/entities/character.dart';
import '../../../domain/repositories/character_record_repository.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../../domain/repositories/friends_repository.dart';
import '../../../domain/repositories/profile_repository.dart';
import '../../locale/l10n_context.dart';
import '../../chat/chat_screen.dart';
import '../../../domain/repositories/ai_chat_repository.dart';
import 'characters_tab.dart';

class FriendsTab extends StatefulWidget {
  const FriendsTab({super.key});

  @override
  State<FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends State<FriendsTab> with WidgetsBindingObserver, OnAppResumedMixin {
  List<FriendSummary> _friends = [];
  bool _loading = true;
  String? _error;

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
      final list = await context.read<FriendsRepository>().listFriends();
      if (!mounted) return;
      setState(() {
        _friends = list;
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

  Future<void> _showAddDialog() async {
    final myId = AppSupabase.auth.currentUser?.id ?? '';
    final existing = _friends.map((f) => f.friendId).toSet();
    final picked = await showDialog<FriendSearchPick?>(
      context: context,
      builder: (ctx) => _FriendSearchDialog(
        myUserId: myId,
        existingFriendIds: existing,
        friendsRepository: context.read<FriendsRepository>(),
        characterRecordRepository: context.read<CharacterRecordRepository>(),
      ),
    );
    if (picked == null || !mounted) return;
    if (picked is FriendSearchPickUser) {
      try {
        await context.read<FriendsRepository>().addFriendById(picked.profile.userId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('friendsAdded'))));
        _load();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
      return;
    }
    if (picked is FriendSearchPickCharacter) {
      await _openCharacterChat(picked.record);
    }
  }

  Future<void> _openCharacterChat(CharacterRecord r) async {
    final chatRepo = context.read<ChatRepository>();
    final aiRepo = context.read<AiChatRepository>();
    final character = Character.fromRecord(r);
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

  Future<void> _openFriendChat(FriendSummary f) async {
    final chatRepo = context.read<ChatRepository>();
    final aiRepo = context.read<AiChatRepository>();
    try {
      final roomId = await chatRepo.ensureDmRoom(f.friendId);
      if (!mounted) return;
      final profile = await context.read<ProfileRepository>().getProfile(f.friendId);
      if (!mounted) return;
      final name = profile?.displayName?.trim().isNotEmpty == true
          ? profile!.displayName!
          : f.title;
      final character = Character.forDirectMessage(
        peerUserId: f.friendId,
        roomId: roomId,
        displayName: name,
        email: profile?.email ?? f.email,
        avatarUrl: profile?.avatarUrl ?? f.avatarUrl,
      );
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.tr('friendsDmOpenFailed')}: $e')),
      );
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.face_outlined),
            tooltip: context.tr('friendsToolbarCharacters'),
            onPressed: () async {
              await Navigator.push<void>(
                context,
                MaterialPageRoute(builder: (_) => const CharactersTab()),
              );
              if (mounted) unawaited(_load(silent: true));
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loading ? null : _load),
        ],
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
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 12),
                        child: Text(
                          context.tr('friendsSectionPeople'),
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                        ),
                      ),
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
                      _characterHintBanner(context),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.person_add),
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
          onTap: () => _openFriendChat(f),
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
                  IconButton(
                    icon: Icon(Icons.person_remove_outlined, color: scheme.onSurfaceVariant),
                    onPressed: () => _confirmRemove(f),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _characterHintBanner(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.primaryContainer.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scheme.primary.withValues(alpha: 0.12)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.face_outlined, color: scheme.primary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.tr('friendsTabCharacterHint'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface,
                      height: 1.4,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendSearchDialog extends StatefulWidget {
  const _FriendSearchDialog({
    required this.myUserId,
    required this.existingFriendIds,
    required this.friendsRepository,
    required this.characterRecordRepository,
  });

  final String myUserId;
  final Set<String> existingFriendIds;
  final FriendsRepository friendsRepository;
  final CharacterRecordRepository characterRecordRepository;

  @override
  State<_FriendSearchDialog> createState() => _FriendSearchDialogState();
}

class _FriendSearchDialogState extends State<_FriendSearchDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.tr('friendsAddTitle')),
      content: SizedBox(
        width: double.maxFinite,
        height: 420,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: context.tr('friendsSearchTabPeople'), icon: const Icon(Icons.person_outlined, size: 20)),
                Tab(text: context.tr('friendsSearchTabCharacters'), icon: const Icon(Icons.face_outlined, size: 20)),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _PeopleSearchPanel(
                    dialogContext: context,
                    myUserId: widget.myUserId,
                    existingFriendIds: widget.existingFriendIds,
                    friendsRepository: widget.friendsRepository,
                  ),
                  _CharacterSearchPanel(
                    dialogContext: context,
                    myUserId: widget.myUserId,
                    characterRecordRepository: widget.characterRecordRepository,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('cancel'))),
      ],
    );
  }
}

class _PeopleSearchPanel extends StatefulWidget {
  const _PeopleSearchPanel({
    required this.dialogContext,
    required this.myUserId,
    required this.existingFriendIds,
    required this.friendsRepository,
  });

  final BuildContext dialogContext;
  final String myUserId;
  final Set<String> existingFriendIds;
  final FriendsRepository friendsRepository;

  @override
  State<_PeopleSearchPanel> createState() => _PeopleSearchPanelState();
}

class _PeopleSearchPanelState extends State<_PeopleSearchPanel> {
  final _queryController = TextEditingController();
  List<UserProfileSearchResult> _results = [];
  bool _searching = false;
  bool _hasSearched = false;
  String? _error;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    final q = _queryController.text.trim();
    if (q.length < 2) {
      setState(() {
        _error = context.tr('friendsSearchMinChars');
        _results = [];
      });
      return;
    }
    setState(() {
      _error = null;
      _searching = true;
      _hasSearched = true;
      _results = [];
    });
    try {
      final raw = await widget.friendsRepository.searchProfilesByNickname(q);
      if (!mounted) return;
      setState(() {
        _results = raw
            .where((r) => r.userId != widget.myUserId && !widget.existingFriendIds.contains(r.userId))
            .toList();
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _searching = false;
        _results = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _queryController,
                decoration: InputDecoration(
                  labelText: context.tr('friendsSearchNicknameLabel'),
                  hintText: context.tr('friendsSearchNicknameHint'),
                  border: const OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                onSubmitted: (_) => _runSearch(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _searching ? null : _runSearch,
              child: _searching
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(context.tr('friendsSearch')),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
        ],
        const SizedBox(height: 8),
        Expanded(
          child: _searching
              ? const Center(child: CircularProgressIndicator())
              : !_hasSearched
                  ? Center(
                      child: Text(
                        context.tr('friendsSearchPrompt'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                      ),
                    )
                  : _results.isEmpty
                      ? Center(
                          child: Text(
                            context.tr('friendsSearchEmpty'),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _results.length,
                          itemBuilder: (ctx, i) {
                            final r = _results[i];
                            final initial = r.title.isNotEmpty ? r.title.substring(0, 1) : '?';
                            return ListTile(
                              leading: CircleAvatar(
                                foregroundImage: r.avatarUrl != null && r.avatarUrl!.trim().isNotEmpty
                                    ? NetworkImage(r.avatarUrl!.trim())
                                    : null,
                                child: r.avatarUrl == null || r.avatarUrl!.trim().isEmpty ? Text(initial) : null,
                              ),
                              title: Text(r.title),
                              subtitle: r.statusMessage != null && r.statusMessage!.trim().isNotEmpty
                                  ? Text(r.statusMessage!, maxLines: 2, overflow: TextOverflow.ellipsis)
                                  : Text(
                                      context.tr('friendsSearchUserSubtitle'),
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                                    ),
                              trailing: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                              onTap: () => Navigator.pop(widget.dialogContext, FriendSearchPickUser(r)),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}

class _CharacterSearchPanel extends StatefulWidget {
  const _CharacterSearchPanel({
    required this.dialogContext,
    required this.myUserId,
    required this.characterRecordRepository,
  });

  final BuildContext dialogContext;
  final String myUserId;
  final CharacterRecordRepository characterRecordRepository;

  @override
  State<_CharacterSearchPanel> createState() => _CharacterSearchPanelState();
}

class _CharacterSearchPanelState extends State<_CharacterSearchPanel> {
  final _queryController = TextEditingController();
  List<CharacterRecord> _results = [];
  bool _searching = false;
  bool _hasSearched = false;
  String? _error;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    final q = _queryController.text.trim();
    if (q.length < 2) {
      setState(() {
        _error = context.tr('friendsSearchMinChars');
        _results = [];
      });
      return;
    }
    setState(() {
      _error = null;
      _searching = true;
      _hasSearched = true;
      _results = [];
    });
    try {
      final raw = await widget.characterRecordRepository.searchAccessibleCharacters(q);
      if (!mounted) return;
      setState(() {
        _results = raw;
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _searching = false;
        _results = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _queryController,
                decoration: InputDecoration(
                  labelText: context.tr('friendsSearchCharacterLabel'),
                  hintText: context.tr('friendsSearchCharacterHint'),
                  border: const OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                onSubmitted: (_) => _runSearch(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _searching ? null : _runSearch,
              child: _searching
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(context.tr('friendsSearch')),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
        ],
        const SizedBox(height: 8),
        Expanded(
          child: _searching
              ? const Center(child: CircularProgressIndicator())
              : !_hasSearched
                  ? Center(
                      child: Text(
                        context.tr('friendsSearchCharacterPrompt'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                      ),
                    )
                  : _results.isEmpty
                      ? Center(
                          child: Text(
                            context.tr('friendsSearchEmpty'),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _results.length,
                          itemBuilder: (ctx, i) {
                            final r = _results[i];
                            final initial = r.name.isNotEmpty ? r.name.substring(0, 1) : '?';
                            final isMine = r.ownerId == widget.myUserId;
                            final badge =
                                isMine ? context.tr('friendsCharacterBadgeMine') : context.tr('friendsCharacterBadgePublic');
                            final tag = r.tagline?.trim();
                            return ListTile(
                              leading: CircleAvatar(
                                foregroundImage: r.avatarUrl != null && r.avatarUrl!.trim().isNotEmpty
                                    ? NetworkImage(r.avatarUrl!.trim())
                                    : null,
                                child: r.avatarUrl == null || r.avatarUrl!.trim().isEmpty ? Text(initial) : null,
                              ),
                              title: Text(r.name),
                              subtitle: Text(
                                tag != null && tag.isNotEmpty ? '$badge · $tag' : badge,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              trailing: Icon(Icons.smart_toy_outlined, color: Theme.of(context).colorScheme.tertiary),
                              onTap: () => Navigator.pop(widget.dialogContext, FriendSearchPickCharacter(r)),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}
