import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/app_supabase.dart';
import '../../../core/widgets/on_app_resumed_mixin.dart';
import '../../../domain/entities/chat_room_summary.dart';
import '../../../domain/repositories/ai_chat_repository.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../../domain/repositories/character_record_repository.dart';
import '../../../domain/repositories/profile_repository.dart';
import '../../locale/l10n_context.dart';
import '../character_room_resolver.dart';
import '../../chat/chat_screen.dart';

/// Lists recent Supabase chat rooms; tap opens [ChatScreen].
class ChatsTab extends StatefulWidget {
  const ChatsTab({super.key});

  @override
  State<ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends State<ChatsTab> with WidgetsBindingObserver, OnAppResumedMixin {
  List<ChatRoomSummary> _rooms = [];
  bool _loading = true;
  String? _error;
  RealtimeChannel? _roomsChannel;
  Timer? _roomsDebounce;
  Timer? _roomsResubscribeTimer;
  int _roomsSubscribeAttempts = 0;
  static const int _maxRoomsResubscribeAttempts = 6;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _subscribeChatRoomsRealtime();
    });
    _load();
  }

  @override
  void onAppResumed() => unawaited(_load(silent: true));

  void _subscribeChatRoomsRealtime() {
    if (AppSupabase.auth.currentUser == null) return;

    final old = _roomsChannel;
    if (old != null) {
      unawaited(AppSupabase.client.removeChannel(old));
      _roomsChannel = null;
    }

    final uid = AppSupabase.auth.currentUser!.id;
    final channel = AppSupabase.client.channel('public:chat_rooms:list:$uid');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_rooms',
          callback: (_) {
            if (!mounted) return;
            _scheduleRoomsReload();
          },
        )
        .subscribe(_onRoomsChannelSubscribeStatus);
    _roomsChannel = channel;
  }

  void _onRoomsChannelSubscribeStatus(RealtimeSubscribeStatus status, [Object? error]) {
    if (!mounted) return;
    switch (status) {
      case RealtimeSubscribeStatus.subscribed:
        _roomsSubscribeAttempts = 0;
        _scheduleRoomsReload();
        break;
      case RealtimeSubscribeStatus.timedOut:
      case RealtimeSubscribeStatus.channelError:
        debugPrint('Chat rooms realtime: $status ${error ?? ''}');
        _scheduleRoomsChannelResubscribe();
        break;
      case RealtimeSubscribeStatus.closed:
        break;
    }
  }

  void _scheduleRoomsChannelResubscribe() {
    if (!mounted) return;
    if (_roomsSubscribeAttempts >= _maxRoomsResubscribeAttempts) {
      debugPrint('Chat rooms realtime: max resubscribe attempts reached');
      return;
    }
    _roomsSubscribeAttempts++;
    _roomsResubscribeTimer?.cancel();
    final seconds = (2 * _roomsSubscribeAttempts).clamp(2, 20);
    _roomsResubscribeTimer = Timer(Duration(seconds: seconds), () {
      if (!mounted) return;
      _subscribeChatRoomsRealtime();
    });
  }

  void _scheduleRoomsReload() {
    _roomsDebounce?.cancel();
    _roomsDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) unawaited(_load(silent: true));
    });
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final repo = context.read<ChatRepository>();
      final list = await repo.getRecentRooms();
      if (!mounted) return;
      setState(() {
        _rooms = list;
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

  @override
  void dispose() {
    _roomsDebounce?.cancel();
    _roomsResubscribeTimer?.cancel();
    final ch = _roomsChannel;
    if (ch != null) {
      unawaited(AppSupabase.client.removeChannel(ch));
      _roomsChannel = null;
    }
    super.dispose();
  }

  String _subtitle(BuildContext context, ChatRoomSummary r) {
    final t = r.lastMessageAt;
    if (t == null) return context.tr('chatsNewChat');
    final loc = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(loc).add_jm().format(t.toLocal());
  }

  Future<void> _openRoom(ChatRoomSummary room) async {
    final charRepo = context.read<CharacterRecordRepository>();
    final character = await resolveCharacterForRoom(
      room,
      charRepo,
      context.read<ProfileRepository>(),
    );
    if (!mounted) return;
    if (character == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('chatsLoadCharacterError'))),
      );
      return;
    }
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          character: character,
          chatRepository: context.read<ChatRepository>(),
          aiChatRepository: context.read<AiChatRepository>(),
        ),
      ),
    );
    if (mounted) unawaited(_load(silent: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('chatsTitle')),
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
                        FilledButton(onPressed: _load, child: Text(context.tr('retry'))),
                      ],
                    ),
                  ),
                )
              : _rooms.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            context.tr('chatsEmpty'),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.tr('chatsEmptyHint'),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _rooms.length,
                        itemBuilder: (context, i) {
                          final r = _rooms[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  r.title.isNotEmpty ? r.title.substring(0, 1) : '?',
                                ),
                              ),
                              title: Text(r.title),
                              subtitle: Text(_subtitle(context, r)),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _openRoom(r),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
