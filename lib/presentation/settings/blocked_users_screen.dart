import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/ui/ui.dart';
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
    return AppPageScaffold(
      title: context.tr('blockedUsersTitle'),
      subtitle: context.tr('settingsBlockedUsersSubtitle'),
      transparentBackground: false,
      body: _loading
          ? const AppLoadingBody()
          : _error != null
              ? AppErrorBody(
                  message: _error!,
                  onRetry: _load,
                  retryLabel: context.tr('retry'),
                )
              : _list.isEmpty
                  ? AppEmptyState(
                      icon: Icons.block_outlined,
                      title: context.tr('blockedUsersEmpty'),
                      subtitle: context.tr('settingsBlockedUsersSubtitle'),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.pageH,
                          12,
                          AppSpacing.pageH,
                          AppSpacing.pageBottom,
                        ),
                        itemCount: _list.length,
                        itemBuilder: (ctx, i) {
                          final u = _list[i];
                          final initial = u.title.isNotEmpty ? u.title.substring(0, 1) : '?';
                          return AppListRow(
                            marginBottom: AppSpacing.listGap,
                            onTap: null,
                            leading: CircleAvatar(
                              radius: AppSizes.listAvatar,
                              foregroundImage: u.avatarUrl != null && u.avatarUrl!.trim().isNotEmpty
                                  ? NetworkImage(u.avatarUrl!.trim())
                                  : null,
                              child: u.avatarUrl == null || u.avatarUrl!.trim().isEmpty ? Text(initial) : null,
                            ),
                            title: u.title,
                            subtitle: u.userId,
                            subtitleMaxLines: 1,
                            trailing: TextButton(
                              onPressed: () => _unblock(u),
                              child: Text(context.tr('blockedUsersUnblock')),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
