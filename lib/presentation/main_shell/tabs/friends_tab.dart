import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/supabase/app_supabase.dart';
import '../../../core/widgets/on_app_resumed_mixin.dart';
import '../../../domain/entities/friend_summary.dart';
import '../../../domain/entities/character.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../../domain/repositories/friends_repository.dart';
import '../../../domain/repositories/profile_repository.dart';
import '../../locale/l10n_context.dart';
import '../../chat/chat_screen.dart';
import '../../../domain/repositories/ai_chat_repository.dart';

class FriendsTab extends StatefulWidget {
  const FriendsTab({super.key});

  @override
  State<FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends State<FriendsTab> with WidgetsBindingObserver, OnAppResumedMixin {
  static final _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

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

  bool _isValidUuid(String s) => _uuid.hasMatch(s.trim());

  Future<void> _showAddDialog() async {
    final controller = TextEditingController();
    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final myId = AppSupabase.auth.currentUser?.id ?? '';
        return AlertDialog(
          title: Text(context.tr('friendsAddTitle')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (myId.isNotEmpty) ...[
                  Text(context.tr('friendsMyUserId'), style: Theme.of(ctx).textTheme.labelMedium),
                  const SizedBox(height: 4),
                  SelectableText(myId, style: const TextStyle(fontSize: 12)),
                  TextButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: myId));
                      if (!ctx.mounted) return;
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text(ctx.tr('friendsIdCopied'))),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: Text(context.tr('friendsCopyId')),
                  ),
                  const Divider(),
                ],
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: context.tr('friendsUuidHint'),
                    border: const OutlineInputBorder(),
                  ),
                  autocorrect: false,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('cancel'))),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(context.tr('friendsAdd')),
            ),
          ],
        );
      },
    );
    final raw = controller.text.trim();
    controller.dispose();
    if (added != true || !mounted) return;
    if (!_isValidUuid(raw)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('friendsInvalidUuid'))));
      return;
    }
    try {
      await context.read<FriendsRepository>().addFriendById(raw);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('friendsAdded'))));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
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
        avatarUrl: profile?.avatarUrl,
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
              : _friends.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(context.tr('friendsEmpty'), style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 8),
                            Text(
                              context.tr('friendsEmptyHint'),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _friends.length,
                        itemBuilder: (context, i) {
                          final f = _friends[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(f.title.isNotEmpty ? f.title.substring(0, 1) : '?'),
                              ),
                              title: Text(f.title),
                              subtitle: Text(f.email ?? f.friendId, maxLines: 1, overflow: TextOverflow.ellipsis),
                              trailing: IconButton(
                                icon: const Icon(Icons.person_remove_outlined),
                                onPressed: () => _confirmRemove(f),
                              ),
                              onTap: () => _openFriendChat(f),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
