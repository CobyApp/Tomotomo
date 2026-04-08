import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/supabase/app_supabase.dart';
import '../../../core/ui/ui.dart';
import '../../../domain/entities/character_record.dart';
import '../../../domain/entities/character.dart';
import '../../../domain/entities/user_profile_search_result.dart';
import '../../../domain/repositories/character_record_repository.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../../domain/repositories/friends_repository.dart';
import '../../../domain/repositories/ai_chat_repository.dart';
import '../../../domain/repositories/points_repository.dart';
import '../../chat/chat_screen.dart';
import '../../points/points_balance_notifier.dart';
import '../../locale/l10n_context.dart';

/// Third bottom-nav tab: search users (add friend) or characters (open AI chat).
class AddFriendTab extends StatefulWidget {
  const AddFriendTab({super.key});

  @override
  State<AddFriendTab> createState() => _AddFriendTabState();
}

class _AddFriendTabState extends State<AddFriendTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Set<String> _existingFriendIds = {};
  bool _loadingIds = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_loadExistingFriendIds()));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingFriendIds() async {
    try {
      final list = await context.read<FriendsRepository>().listFriends();
      if (!mounted) return;
      setState(() {
        _existingFriendIds = list.map((f) => f.friendId).toSet();
        _loadingIds = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _existingFriendIds = {};
        _loadingIds = false;
      });
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

  /// Copy a shared (non-owned) character into the current user's list.
  Future<void> _addSharedCharacterToLocal(CharacterRecord r) async {
    final user = AppSupabase.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.trRead('loginRequired'))));
      return;
    }
    if (r.ownerId == user.id) return;
    try {
      final spend = await context.read<PointsRepository>().spendPoints(10, 'public_character_download');
      if (!spend.ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.trRead('pointsInsufficient'))));
        return;
      }
      if (!mounted) return;
      context.read<PointsBalanceNotifier>().setBalance(spend.balance);
      final repo = context.read<CharacterRecordRepository>();
      final copy = CharacterRecord.draft(
        ownerId: user.id,
        name: r.name,
        nameSecondary: r.nameSecondary,
        avatarUrl: r.avatarUrl,
        speechStyle: r.speechStyle,
        language: r.language,
        isPublic: false,
      );
      await repo.createCharacter(copy);
      await repo.incrementDownloadCount(r.id);
      if (!mounted) return;
      final msg = context.trRead('charactersAdded', params: {'name': r.name});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      final prefix = context.trRead('charactersAddFailed');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$prefix: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = AppSupabase.auth.currentUser?.id ?? '';
    final friendsRepo = context.read<FriendsRepository>();
    final charRepo = context.read<CharacterRecordRepository>();

    return AppPageScaffold(
      title: context.tr('tabAddFriend'),
      showPointsChip: true,
      bottom: TabBar(
        controller: _tabController,
        tabs: [
          Tab(text: context.tr('friendsSearchTabPeople'), icon: const Icon(Icons.person_outlined, size: 20)),
          Tab(text: context.tr('friendsSearchTabCharacters'), icon: const Icon(Icons.face_outlined, size: 20)),
        ],
      ),
      body: _loadingIds
          ? const AppLoadingBody()
          : TabBarView(
              controller: _tabController,
              children: <Widget>[
                AddFriendPeoplePanel(
                  myUserId: myId,
                  existingFriendIds: _existingFriendIds,
                  friendsRepository: friendsRepo,
                  reloadFriendIds: _loadExistingFriendIds,
                ),
                AddFriendCharacterPanel(
                  myUserId: myId,
                  characterRecordRepository: charRepo,
                  onPickCharacter: _openCharacterChat,
                  onAddSharedToLocal: _addSharedCharacterToLocal,
                ),
              ],
            ),
    );
  }
}

class AddFriendPeoplePanel extends StatefulWidget {
  const AddFriendPeoplePanel({
    super.key,
    required this.myUserId,
    required this.existingFriendIds,
    required this.friendsRepository,
    required this.reloadFriendIds,
  });

  final String myUserId;
  final Set<String> existingFriendIds;
  final FriendsRepository friendsRepository;
  final Future<void> Function() reloadFriendIds;

  @override
  State<AddFriendPeoplePanel> createState() => _AddFriendPeoplePanelState();
}

class _AddFriendPeoplePanelState extends State<AddFriendPeoplePanel> {
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
        _results = raw.where((r) => r.userId != widget.myUserId).toList();
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

  Future<void> _addFriend(UserProfileSearchResult profile) async {
    try {
      await widget.friendsRepository.addFriendById(profile.userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.trRead('friendsAdded'))));
      await widget.reloadFriendIds();
      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  void _openProfileSheet(UserProfileSearchResult profile) {
    final isFriend = widget.existingFriendIds.contains(profile.userId);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: FriendSearchUserProfileSheet(
          profile: profile,
          initialIsFriend: isFriend,
          reloadFriendIds: widget.reloadFriendIds,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _queryController,
                  decoration: InputDecoration(
                    labelText: context.tr('friendsSearchNicknameLabel'),
                    hintText: context.tr('friendsSearchNicknameHint'),
                    prefixIcon: Icon(Icons.person_search_rounded, color: scheme.primary),
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
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                        ),
                      )
                    : _results.isEmpty
                        ? Center(
                            child: Text(
                              context.tr('friendsSearchEmpty'),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    height: 1.4,
                                  ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _results.length,
                            itemBuilder: (ctx, i) {
                              final r = _results[i];
                              final initial = r.title.isNotEmpty ? r.title.substring(0, 1) : '?';
                              final isFriend = widget.existingFriendIds.contains(r.userId);
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
                                        isFriend
                                            ? context.tr('friendsAlreadyFriend')
                                            : context.tr('friendsSearchUserSubtitle'),
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                                      ),
                                trailing: isFriend
                                    ? Icon(Icons.check_circle, color: scheme.primary)
                                    : IconButton(
                                        icon: Icon(Icons.person_add_alt_1_outlined, color: scheme.primary),
                                        tooltip: context.tr('friendsAdd'),
                                        onPressed: () => _addFriend(r),
                                      ),
                                onTap: () => _openProfileSheet(r),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

/// Minimal sheet: avatar, display name, status, add-friend (or “already friend”).
class FriendSearchUserProfileSheet extends StatefulWidget {
  const FriendSearchUserProfileSheet({
    super.key,
    required this.profile,
    required this.initialIsFriend,
    required this.reloadFriendIds,
  });

  final UserProfileSearchResult profile;
  final bool initialIsFriend;
  final Future<void> Function() reloadFriendIds;

  @override
  State<FriendSearchUserProfileSheet> createState() => _FriendSearchUserProfileSheetState();
}

class _FriendSearchUserProfileSheetState extends State<FriendSearchUserProfileSheet> {
  late bool _isFriend;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _isFriend = widget.initialIsFriend;
  }

  Future<void> _add() async {
    setState(() => _busy = true);
    try {
      await context.read<FriendsRepository>().addFriendById(widget.profile.userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.trRead('friendsAdded'))));
      await widget.reloadFriendIds();
      if (mounted) setState(() => _isFriend = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final p = widget.profile;
    final initial = p.title.isNotEmpty ? p.title.substring(0, 1) : '?';
    final status = p.statusMessage?.trim();
    final statusText = status != null && status.isNotEmpty ? status : context.tr('friendsSheetStatusEmpty');

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: CircleAvatar(
              radius: 44,
              foregroundImage: p.avatarUrl != null && p.avatarUrl!.trim().isNotEmpty
                  ? NetworkImage(p.avatarUrl!.trim())
                  : null,
              child: p.avatarUrl == null || p.avatarUrl!.trim().isEmpty ? Text(initial, style: const TextStyle(fontSize: 30)) : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            p.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            statusText,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, height: 1.35),
          ),
          const SizedBox(height: 28),
          if (!_isFriend)
            FilledButton(
              onPressed: _busy ? null : _add,
              child: _busy
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(context.tr('friendsAdd')),
            )
          else
            Text(
              context.tr('friendsAlreadyFriend'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
        ],
      ),
    );
  }
}

class AddFriendCharacterPanel extends StatefulWidget {
  const AddFriendCharacterPanel({
    super.key,
    required this.myUserId,
    required this.characterRecordRepository,
    required this.onPickCharacter,
    required this.onAddSharedToLocal,
  });

  final String myUserId;
  final CharacterRecordRepository characterRecordRepository;
  final void Function(CharacterRecord record) onPickCharacter;
  final Future<void> Function(CharacterRecord record) onAddSharedToLocal;

  @override
  State<AddFriendCharacterPanel> createState() => _AddFriendCharacterPanelState();
}

class _AddFriendCharacterPanelState extends State<AddFriendCharacterPanel> {
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
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _queryController,
                  decoration: InputDecoration(
                    labelText: context.tr('friendsSearchCharacterLabel'),
                    hintText: context.tr('friendsSearchCharacterHint'),
                    prefixIcon: Icon(Icons.face_retouching_natural_rounded, color: scheme.primary),
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
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                        ),
                      )
                    : _results.isEmpty
                        ? Center(
                            child: Text(
                              context.tr('friendsSearchEmpty'),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    height: 1.4,
                                  ),
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
                              final detail = r.listDetailLine;
                              return ListTile(
                                leading: CircleAvatar(
                                  foregroundImage: r.avatarUrl != null && r.avatarUrl!.trim().isNotEmpty
                                      ? NetworkImage(r.avatarUrl!.trim())
                                      : null,
                                  child: r.avatarUrl == null || r.avatarUrl!.trim().isEmpty ? Text(initial) : null,
                                ),
                                title: Text(r.name),
                                subtitle: Text(
                                  detail.isNotEmpty ? '$badge · $detail' : badge,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!isMine)
                                      IconButton(
                                        icon: const Icon(Icons.download_outlined),
                                        tooltip: context.tr('charactersAddToMine'),
                                        onPressed: () => widget.onAddSharedToLocal(r),
                                      ),
                                    Icon(Icons.smart_toy_outlined, color: Theme.of(context).colorScheme.tertiary),
                                  ],
                                ),
                                onTap: () => widget.onPickCharacter(r),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
