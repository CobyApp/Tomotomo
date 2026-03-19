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
import '../../../data/character/characters_data.dart';
import '../../chat/chat_screen.dart';
import '../../character_form/create_character_screen.dart';
import '../../character_form/edit_character_screen.dart';
import '../../locale/l10n_context.dart';

/// My characters (Supabase) + Discover (public) + Built-in characters.
class CharactersTab extends StatefulWidget {
  const CharactersTab({super.key});

  @override
  State<CharactersTab> createState() => _CharactersTabState();
}

class _CharactersTabState extends State<CharactersTab> with WidgetsBindingObserver, OnAppResumedMixin {
  List<CharacterRecord> _myCharacters = [];
  List<CharacterRecord> _publicCharacters = [];
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
    final user = AppSupabase.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _myCharacters = [];
        _publicCharacters = [];
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
        _publicCharacters = public;
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

  /// Copies a public character to the current user's list (and increments download count).
  Future<void> _addPublicCharacterToMine(CharacterRecord r) async {
    final user = AppSupabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('loginRequired'))));
      return;
    }
    try {
      final repo = context.read<CharacterRecordRepository>();
      final copy = CharacterRecord.draft(
        ownerId: user.id,
        name: r.name,
        nameSecondary: r.nameSecondary,
        avatarUrl: r.avatarUrl,
        backgroundUrl: r.backgroundUrl,
        speechStyle: r.speechStyle,
        tagline: r.tagline,
        language: r.language,
        isPublic: false,
      );
      await repo.createCharacter(copy);
      await repo.incrementDownloadCount(r.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('charactersAdded', params: {'name': r.name}))),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.tr('charactersAddFailed')}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('charactersTitle')),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
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
                        FilledButton(
                          onPressed: _load,
                          child: Text(context.tr('retry')),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    children: [
                      _recordsSection(context.tr('charactersMy'), _myCharacters, isMine: true),
                      _recordsSection(context.tr('charactersDiscover'), _publicCharacters, isMine: false),
                      _builtInSection(context.tr('charactersBuiltin'), characters),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateCharacterScreen(),
            ),
          );
          if (created == true) _load();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _recordsSection(String title, List<CharacterRecord> records, {bool isMine = false}) {
    if (records.isEmpty && !isMine) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
          ),
        ),
        ...records.map((r) => _recordTile(r, isMine: isMine)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _builtInSection(String title, List<Character> builtIn) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
          ),
        ),
        ...builtIn.map((c) => _builtInTile(c)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _recordTile(CharacterRecord r, {bool isMine = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: r.avatarUrl != null && r.avatarUrl!.isNotEmpty
              ? NetworkImage(r.avatarUrl!)
              : null,
          child: r.avatarUrl == null || r.avatarUrl!.isEmpty
              ? const Icon(Icons.face)
              : null,
        ),
        title: Text(r.name),
        subtitle: Text(
          r.tagline != null && r.tagline!.trim().isNotEmpty
              ? r.tagline!.trim()
              : (r.nameSecondary ?? (r.language == 'ja' ? context.tr('langJa') : context.tr('langKo'))),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isMine)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) async {
                  if (value == 'edit') {
                    final updated = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditCharacterScreen(record: r),
                      ),
                    );
                    if (updated == true) _load();
                  } else if (value == 'delete') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(context.tr('charactersDeleteTitle')),
                        content: Text(context.tr('charactersDeleteBody', params: {'name': r.name})),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(context.tr('cancel')),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(context.tr('charactersDelete')),
                          ),
                        ],
                      ),
                    );
                    if (confirm != true || !mounted) return;
                    try {
                      await context.read<CharacterRecordRepository>().deleteCharacter(r.id, r.ownerId);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('charactersDeleted'))));
                      _load();
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${context.tr('charactersDeleteFailed')}: $e')),
                      );
                    }
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(value: 'edit', child: Text(context.tr('charactersEdit'))),
                  PopupMenuItem(value: 'delete', child: Text(context.tr('charactersDelete'))),
                ],
              )
            else
              PopupMenuButton<String>(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: context.tr('charactersAddToMine'),
                onSelected: (value) async {
                  if (value == 'add') await _addPublicCharacterToMine(r);
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(value: 'add', child: Text(context.tr('charactersAddToMine'))),
                ],
              ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () {
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
        },
      ),
    );
  }

  Widget _builtInTile(Character c) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: c.imageProvider,
        ),
        title: Text(c.name),
        subtitle: Text(c.nameJp),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                character: c,
                chatRepository: context.read<ChatRepository>(),
                aiChatRepository: context.read<AiChatRepository>(),
              ),
            ),
          );
        },
      ),
    );
  }
}
