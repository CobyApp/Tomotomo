import 'dart:async';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/platform/ios_post_layout_frames.dart';
import '../../../core/ui/app_tokens.dart';
import '../../../core/ui/paper/paper_dialog.dart';
import '../../../core/ui/paper/paper_scaffold.dart';
import '../../../core/ui/paper/paper_status_views.dart';
import '../../../core/ui/paper/paper_tokens.dart';
import '../../../core/ui/paper/paper_widgets.dart';
import '../../../core/widgets/on_app_resumed_mixin.dart';
import '../../../data/character/characters_data.dart';
import '../../../domain/entities/character.dart';
import '../../../domain/entities/chat_room_summary.dart';
import '../../../domain/repositories/ai_chat_repository.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../../domain/repositories/character_record_repository.dart';
import '../../locale/l10n_context.dart';
import '../../chat/chat_screen.dart';

/// Resolves a [Character] from a local chat room (roomId == character id).
Future<Character?> _resolveCharacterForRoom(
  ChatRoomSummary room,
  CharacterRecordRepository charRepo,
) async {
  // Prefer the stored record (built-ins are seeded as editable records, so a
  // user's edits/deletions win).
  final r = await charRepo.getCharacter(room.roomId);
  if (r != null) return Character.fromRecord(r);
  // Fall back to the packaged persona for rooms opened before seeding.
  for (final c in characters) {
    if (c.id == room.roomId) return c;
  }
  return null;
}

/// Lists recent local chat rooms; tap opens [ChatScreen].
class ChatsTab extends StatefulWidget {
  const ChatsTab({super.key});

  @override
  ChatsTabState createState() => ChatsTabState();
}

class ChatsTabState extends State<ChatsTab>
    with WidgetsBindingObserver, OnAppResumedMixin {
  /// Bottom nav selected this tab — refresh room list.
  void reloadFromTabSelection() {
    unawaited(_load(silent: true));
  }

  List<ChatRoomSummary> _rooms = [];
  // Current character per room id, resolved fresh on each load so Friends-tab
  // edits (name / photo) reflect here immediately.
  Map<String, Character> _resolved = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(() async {
        await waitIosPostLayoutFrames(frames: 3);
        if (!mounted) return;
        unawaited(_load());
      }());
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
      final repo = context.read<ChatRepository>();
      final characterRepo = context.read<CharacterRecordRepository>();
      final list = await repo.getRecentRooms();
      // Resolve each room's CURRENT character so edits (name/photo/etc.) made in
      // the Friends tab show here immediately. Show every room (no language
      // filter) — consistent with the unfiltered friends list.
      final resolved = await Future.wait(
        list.map((room) => _resolveCharacterForRoom(room, characterRepo)),
      );
      final rooms = <ChatRoomSummary>[];
      final byRoom = <String, Character>{};
      for (var i = 0; i < list.length; i++) {
        rooms.add(list[i]);
        final character = resolved[i];
        if (character != null) byRoom[list[i].roomId] = character;
      }
      if (!mounted) return;
      setState(() {
        _rooms = rooms;
        _resolved = byRoom;
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

  Widget _roomLeading(ChatRoomSummary r, {double size = 52}) {
    // Prefer the freshly-resolved character's avatar so edits show immediately.
    final character = _resolved[r.roomId];
    Widget inner;
    if (character != null && character.hasAvatar) {
      inner = Image(image: character.imageProvider, fit: BoxFit.cover);
    } else {
      final net = r.avatarNetworkUrl?.trim();
      final asset = r.avatarAssetPath?.trim();
      if (character == null && net != null && net.isNotEmpty) {
        inner = Image(image: NetworkImage(net), fit: BoxFit.cover);
      } else if (character == null && asset != null && asset.isNotEmpty) {
        final provider = asset.startsWith('/')
            ? FileImage(File(asset)) as ImageProvider
            : AssetImage(asset) as ImageProvider;
        inner = Image(image: provider, fit: BoxFit.cover);
      } else {
        inner = PersonAvatarGlyph(size: size);
      }
    }
    return PolaroidAvatar(size: size, child: inner);
  }

  Widget _chatRoomCard(BuildContext context, ChatRoomSummary r) {
    final p = context.paper;
    final timeText = _listTimeLabel(context, r.lastMessageAt);
    return PaperCard(
      onTap: () => _openRoom(r),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _roomLeading(r),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _resolved[r.roomId]?.displayNamePrimary ?? r.title,
                        style: AppTextStyles.listTitle(
                          context,
                        ).copyWith(color: p.ink, fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (timeText.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        timeText,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: p.inkSoft,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _messagePreview(context, r),
                  style: AppTextStyles.listSubtitle(
                    context,
                  ).copyWith(color: p.inkSoft),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _messagePreview(BuildContext context, ChatRoomSummary r) {
    final raw = r.lastMessageContent;
    if (raw == null || raw.trim().isEmpty) {
      return context.tr('chatsListNoPreview');
    }
    final t = raw.trim();
    return t;
  }

  /// Kakao/iMessage-style relative time on the list row.
  String _listTimeLabel(BuildContext context, DateTime? t) {
    if (t == null) return '';
    final loc = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    final d = t.toLocal();
    final todayStart = DateTime(now.year, now.month, now.day);
    final msgStart = DateTime(d.year, d.month, d.day);
    final diffDays = todayStart.difference(msgStart).inDays;
    if (diffDays == 0) return DateFormat.Hm(loc).format(d);
    if (diffDays == 1) return context.tr('chatsTimeYesterday');
    if (diffDays < 7) return DateFormat.E(loc).format(d);
    if (d.year == now.year) return DateFormat.Md(loc).format(d);
    return DateFormat.yMd(loc).format(d);
  }

  Future<bool> _confirmDeleteRoom(BuildContext context, ChatRoomSummary r) {
    return showPaperConfirm(
      context,
      title: context.tr('chatsDeleteTitle'),
      message: context.tr(
        'chatsDeleteBodyCharacter',
        params: {'name': r.title},
      ),
      confirmLabel: context.tr('confirm'),
      destructive: true,
    );
  }

  Widget _dismissibleChatRoomRow(BuildContext context, ChatRoomSummary r) {
    final p = context.paper;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey<String>('chat_room_${r.roomId}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          final ok = await _confirmDeleteRoom(context, r);
          if (!context.mounted || ok != true) return false;
          final messenger = ScaffoldMessenger.of(context);
          final repo = context.read<ChatRepository>();
          try {
            await repo.deleteRoom(r.roomId);
            if (!context.mounted) return false;
            return true;
          } catch (_) {
            if (!context.mounted) return false;
            messenger.showSnackBar(
              SnackBar(content: Text(context.trRead('chatsRoomDeleteFailed'))),
            );
            return false;
          }
        },
        onDismissed: (_) {
          if (!mounted) return;
          setState(() {
            _rooms.removeWhere((x) => x.roomId == r.roomId);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.trRead('chatsRoomDeleted'))),
          );
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 22),
          decoration: BoxDecoration(
            color: p.coral.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(PaperRadii.card),
            border: Border.all(color: p.coral.withValues(alpha: 0.3)),
          ),
          child: Icon(
            Icons.delete_outline_rounded,
            color: p.coralDeep,
            size: 28,
          ),
        ),
        child: _chatRoomCard(context, r),
      ),
    );
  }

  Future<void> _openRoom(ChatRoomSummary room) async {
    final charRepo = context.read<CharacterRecordRepository>();
    final character = await _resolveCharacterForRoom(room, charRepo);
    if (!mounted) return;
    if (character == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.trRead('chatsLoadCharacterError'))),
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
    final p = context.paper;
    return PaperScaffold(
      title: context.tr('chatsTitle'),
      showBackground: false,
      body: _loading
          ? const PaperLoadingBody()
          : _error != null
          ? PaperErrorBody(
              message: _error!,
              onRetry: _load,
              retryLabel: context.tr('retry'),
            )
          : _rooms.isEmpty
          ? PaperEmptyState(
              icon: Icons.chat_bubble_outline_rounded,
              title: context.tr('chatsEmpty'),
              subtitle: context.tr('chatsEmptyHint'),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageH,
                12,
                AppSpacing.pageH,
                AppSpacing.pageBottom,
              ),
              itemCount: _rooms.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      context.tr('chatsDeleteSwipeHint'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: p.inkSoft,
                        height: 1.35,
                      ),
                    ),
                  );
                }
                return PaperEntrance(
                  index: i - 1,
                  child: _dismissibleChatRoomRow(context, _rooms[i - 1]),
                );
              },
            ),
    );
  }
}
