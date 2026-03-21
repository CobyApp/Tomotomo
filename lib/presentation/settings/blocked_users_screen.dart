import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/blocked_user_summary.dart';
import '../../domain/repositories/friends_repository.dart';
import '../locale/l10n_context.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  List<BlockedUserSummary> _list = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await context.read<FriendsRepository>().listBlockedUsers();
      if (!mounted) return;
      setState(() {
        _list = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _unblock(BlockedUserSummary u) async {
    try {
      await context.read<FriendsRepository>().unblockUser(u.userId);
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.trRead('dmUnblock'))));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('blockedUsersTitle')),
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
              : _list.isEmpty
                  ? Center(child: Text(context.tr('blockedUsersEmpty')))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        itemCount: _list.length,
                        itemBuilder: (ctx, i) {
                          final u = _list[i];
                          final initial = u.title.isNotEmpty ? u.title.substring(0, 1) : '?';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: CircleAvatar(
                                foregroundImage: u.avatarUrl != null && u.avatarUrl!.trim().isNotEmpty
                                    ? NetworkImage(u.avatarUrl!.trim())
                                    : null,
                                child: u.avatarUrl == null || u.avatarUrl!.trim().isEmpty ? Text(initial) : null,
                              ),
                              title: Text(u.title),
                              subtitle: Text(
                                u.userId,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              trailing: TextButton(
                                onPressed: () => _unblock(u),
                                child: Text(context.tr('blockedUsersUnblock')),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
