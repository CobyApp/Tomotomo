import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/supabase/app_supabase.dart';
import '../../../domain/entities/block_relation.dart';
import '../../../domain/entities/character_record.dart';
import '../../../domain/entities/character.dart';
import '../../../domain/entities/user_profile_search_result.dart';
import '../../../domain/repositories/character_record_repository.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../../domain/repositories/friends_repository.dart';
import '../../../domain/repositories/ai_chat_repository.dart';
import '../../../domain/repositories/profile_repository.dart';
import '../../chat/chat_screen.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('tabAddFriend')),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: context.tr('friendsSearchTabPeople'), icon: const Icon(Icons.person_outlined, size: 20)),
            Tab(text: context.tr('friendsSearchTabCharacters'), icon: const Icon(Icons.face_outlined, size: 20)),
          ],
        ),
      ),
      body: _loadingIds
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
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
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
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

/// Bottom sheet: user info + chat / add / remove / copy ID.
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
  BlockRelation _block = BlockRelation.none;
  bool _blockLoaded = false;

  @override
  void initState() {
    super.initState();
    _isFriend = widget.initialIsFriend;
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_loadBlockRelation()));
  }

  Future<void> _loadBlockRelation() async {
    try {
      final rel = await context.read<FriendsRepository>().blockRelationWith(widget.profile.userId);
      if (!mounted) return;
      setState(() {
        _block = rel;
        _blockLoaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _blockLoaded = true);
    }
  }

  Future<void> _confirmBlock() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('dmBlockConfirmTitle')),
        content: Text(context.tr('dmBlockConfirmBody')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('dmStrangerBlock'))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await context.read<FriendsRepository>().blockUser(widget.profile.userId);
      if (!mounted) return;
      setState(() {
        _block = const BlockRelation(anyBlock: true, iBlockedThem: true, theyBlockedMe: false);
        _busy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.trRead('friendsSearchBlockedDone'))));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _unblockFromSheet() async {
    setState(() => _busy = true);
    try {
      await context.read<FriendsRepository>().unblockUser(widget.profile.userId);
      if (!mounted) return;
      setState(() {
        _block = BlockRelation.none;
        _busy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.trRead('dmUnblock'))));
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
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

  Future<void> _remove() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('friendsRemoveConfirm')),
        content: Text(widget.profile.title),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('friendsSearchRemoveFriend'))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await context.read<FriendsRepository>().removeFriend(widget.profile.userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.trRead('friendsRemoved'))));
      await widget.reloadFriendIds();
      if (mounted) setState(() => _isFriend = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openChat() async {
    final rootCtx = context;
    final chatRepo = rootCtx.read<ChatRepository>();
    final aiRepo = rootCtx.read<AiChatRepository>();
    final r = widget.profile;
    try {
      final roomId = await chatRepo.ensureDmRoom(r.userId);
      if (!rootCtx.mounted) return;
      final fetched = await rootCtx.read<ProfileRepository>().getProfile(r.userId);
      if (!rootCtx.mounted) return;
      final name = fetched?.displayName?.trim().isNotEmpty == true ? fetched!.displayName! : r.title;
      final character = Character.forDirectMessage(
        peerUserId: r.userId,
        roomId: roomId,
        displayName: name,
        email: fetched?.email,
        avatarUrl: fetched?.avatarUrl ?? r.avatarUrl,
      );
      Navigator.pop(rootCtx);
      await Navigator.push<void>(
        rootCtx,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            character: character,
            chatRepository: chatRepo,
            aiChatRepository: aiRepo,
          ),
        ),
      );
    } catch (e) {
      if (!rootCtx.mounted) return;
      ScaffoldMessenger.of(rootCtx).showSnackBar(
        SnackBar(content: Text('${rootCtx.trRead('friendsDmOpenFailed')}: $e')),
      );
    }
  }

  void _copyId() {
    Clipboard.setData(ClipboardData(text: widget.profile.userId));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.trRead('friendsIdCopied'))));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final p = widget.profile;
    final initial = p.title.isNotEmpty ? p.title.substring(0, 1) : '?';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              foregroundImage: p.avatarUrl != null && p.avatarUrl!.trim().isNotEmpty
                  ? NetworkImage(p.avatarUrl!.trim())
                  : null,
              child: p.avatarUrl == null || p.avatarUrl!.trim().isEmpty ? Text(initial, style: const TextStyle(fontSize: 28)) : null,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            p.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (_isFriend) ...[
            const SizedBox(height: 8),
            Align(
              child: Chip(
                avatar: Icon(Icons.check_circle, size: 18, color: scheme.primary),
                label: Text(context.tr('friendsAlreadyFriend')),
              ),
            ),
          ],
          if (p.statusMessage != null && p.statusMessage!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              p.statusMessage!.trim(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            context.tr('friendsSearchUserId'),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          SelectableText(
            p.userId,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : _copyId,
            icon: const Icon(Icons.copy_rounded, size: 20),
            label: Text(context.tr('friendsCopyId')),
          ),
          const SizedBox(height: 20),
          if (!_blockLoaded)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else ...[
            if (_block.theyBlockedMe && !_block.iBlockedThem)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  context.tr('dmBlockedByThemBanner'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, height: 1.35),
                ),
              ),
            if (_block.iBlockedThem) ...[
              Text(
                context.tr('dmBlockedByMeBanner'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.error, height: 1.35),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _busy ? null : _unblockFromSheet,
                icon: const Icon(Icons.block_outlined),
                label: Text(context.tr('dmUnblock')),
              ),
            ] else ...[
              if (_isFriend) ...[
                FilledButton.icon(
                  onPressed: _busy ? null : _openChat,
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: Text(context.tr('friendsSearchChat')),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _remove,
                  icon: const Icon(Icons.person_remove_outlined),
                  label: Text(context.tr('friendsSearchRemoveFriend')),
                ),
              ] else
                FilledButton.icon(
                  onPressed: _busy ? null : _add,
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: Text(context.tr('friendsAdd')),
                ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _busy ? null : _confirmBlock,
                icon: const Icon(Icons.block_outlined),
                label: Text(context.tr('dmStrangerBlock')),
              ),
            ],
          ],
          const SizedBox(height: 12),
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: Text(context.tr('friendsSearchClose')),
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
