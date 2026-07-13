import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/ui/ui.dart';
import '../../core/ui/points_toolbar_chip.dart';
import '../../core/ui/holo/glitch_text.dart';
import '../../core/ui/holo/holo_tokens.dart';
import '../../domain/entities/block_relation.dart';
import '../../domain/entities/character.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/repositories/ai_chat_repository.dart';
import '../locale/l10n_context.dart';
import '../locale/locale_notifier.dart';
import '../points/points_topup_prompt.dart';
import 'chat_message_report.dart';
import 'chat_viewmodel.dart';
import 'widgets/chat_list.dart';
import 'widgets/chat_input.dart';

class ChatScreen extends StatefulWidget {
  final Character character;
  final ChatRepository chatRepository;
  final AiChatRepository aiChatRepository;

  const ChatScreen({
    super.key,
    required this.character,
    required this.chatRepository,
    required this.aiChatRepository,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _controller;
  final ScrollController _scrollController = ScrollController();
  late final ChatViewModel _viewModel;
  final bool _dmSocialLoaded = false;
  final bool _dmOutgoingFriend = false;
  final BlockRelation _dmBlock = BlockRelation.none;

  @override
  void initState() {
    super.initState();
    _viewModel = ChatViewModel(
      character: widget.character,
      chatRepository: widget.chatRepository,
      aiChatRepository: widget.aiChatRepository,
      insufficientPointsMessage: context.trRead('pointsInsufficient'),
      onInsufficientPoints: _onInsufficientPoints,
      appUiLanguageCode: context.read<LocaleNotifier>().languageCode,
    );
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      unawaited(_loadDmSocialState());
    });
    WidgetsBinding.instance.addObserver(this);
  }

  /// Human-to-human DM social state is not used in the local offline app
  /// (no DM characters exist). Kept as a no-op for app bar wiring.
  Future<void> _loadDmSocialState() async {
    return;
  }

  void _onInsufficientPoints() {
    if (!mounted) return;
    unawaited(showPointsTopUpPrompt(context));
  }

  Future<void> _dmAddFriend() async {
    return;
  }

  Future<void> _dmConfirmBlock() async {
    return;
  }

  Future<void> _dmUnblock() async {
    return;
  }

  @override
  void didChangeMetrics() {
    if (mounted) _scrollToBottom();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && mounted) {
      _viewModel.onAppResumedSync();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDm = widget.character.isDirectMessage;
    final showStrangerBanner =
        isDm && _dmSocialLoaded && !_dmBlock.anyBlock && !_dmOutgoingFriend;
    final showBlockedByMe = isDm && _dmSocialLoaded && _dmBlock.iBlockedThem;
    final showBlockedByThem = isDm && _dmSocialLoaded && _dmBlock.theyBlockedMe;
    final canSendDm = !isDm || !_dmBlock.anyBlock;

    return ChangeNotifierProvider<ChatViewModel>.value(
      value: _viewModel,
      child: Consumer<ChatViewModel>(
        builder: (context, viewModel, child) {
          return _ChatScreenContent(
            character: widget.character,
            scrollController: _scrollController,
            chatRoomId: viewModel.chatRoomId,
            onReportRoom: (ctx) => confirmAndReportChatRoom(
              ctx,
              character: widget.character,
              chatRoomId: viewModel.chatRoomId,
            ),
            onLeaveRoom: (ctx) => _confirmLeaveRoom(ctx, viewModel),
            showDmStrangerBanner: showStrangerBanner,
            showDmBlockedByMeBanner: showBlockedByMe,
            showDmBlockedByThemBanner: showBlockedByThem,
            dmShowBlockInMenu:
                isDm &&
                _dmSocialLoaded &&
                !_dmBlock.iBlockedThem &&
                !_dmBlock.theyBlockedMe,
            dmShowUnblockInMenu:
                isDm && _dmSocialLoaded && _dmBlock.iBlockedThem,
            onDmAddFriend: _dmAddFriend,
            onDmBlock: _dmConfirmBlock,
            onDmUnblock: _dmUnblock,
            canSendMessage: canSendDm,
            messageHintOverride: canSendDm
                ? null
                : context.trRead('dmInputBlockedHint'),
          );
        },
      ),
    );
  }

  Future<void> _confirmLeaveRoom(
    BuildContext context,
    ChatViewModel viewModel,
  ) async {
    final isDm = widget.character.isDirectMessage;
    final name = widget.character.displayNamePrimary;
    final bodyKey = isDm ? 'chatsDeleteBodyDm' : 'chatsDeleteBodyCharacter';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('chatsDeleteTitle')),
        content: Text(context.tr(bodyKey, params: {'name': name})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.tr('confirm')),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await viewModel.leaveRoom();
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('chatsRoomDeleted'))));
      Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('chatsRoomDeleteFailed'))),
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _controller.dispose();
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

class _ChatScreenContent extends StatelessWidget {
  final Character character;
  final ScrollController scrollController;
  final String? chatRoomId;
  final Future<void> Function(BuildContext context) onReportRoom;
  final Future<void> Function(BuildContext context) onLeaveRoom;
  final bool showDmStrangerBanner;
  final bool showDmBlockedByMeBanner;
  final bool showDmBlockedByThemBanner;
  final bool dmShowBlockInMenu;
  final bool dmShowUnblockInMenu;
  final Future<void> Function() onDmAddFriend;
  final Future<void> Function() onDmBlock;
  final Future<void> Function() onDmUnblock;
  final bool canSendMessage;
  final String? messageHintOverride;

  const _ChatScreenContent({
    required this.character,
    required this.scrollController,
    required this.chatRoomId,
    required this.onReportRoom,
    required this.onLeaveRoom,
    required this.showDmStrangerBanner,
    required this.showDmBlockedByMeBanner,
    required this.showDmBlockedByThemBanner,
    required this.dmShowBlockInMenu,
    required this.dmShowUnblockInMenu,
    required this.onDmAddFriend,
    required this.onDmBlock,
    required this.onDmUnblock,
    required this.canSendMessage,
    required this.messageHintOverride,
  });

  void _scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: Holo.pageGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: const Border(bottom: BorderSide(color: Holo.pink, width: 1.5)),
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Holo.inkPlum,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: Holo.holoGradient,
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Holo.surfaceCard,
                  backgroundImage: character.hasAvatar
                      ? character.imageProvider
                      : null,
                  child: !character.hasAvatar
                      ? Text(
                          character.displayNamePrimary.isNotEmpty
                              ? character.displayNamePrimary.substring(0, 1)
                              : '?',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Holo.inkPlum,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GlitchText(
                      character.displayNamePrimary,
                      style: AppTextStyles.listTitle(
                        context,
                      ).copyWith(fontSize: 18),
                    ),
                    if (character.displayNameSecondary.isNotEmpty)
                      Text(
                        character.displayNameSecondary,
                        style: AppTextStyles.listSubtitle(
                          context,
                        ).copyWith(color: Holo.inkPlumSoft),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            const PointsToolbarChip(),
            PopupMenuButton<String>(
              tooltip: context.tr('chatMoreMenuTooltip'),
              icon: const Icon(Icons.more_horiz_rounded, color: Holo.inkPlum),
              offset: const Offset(0, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.cardSmall),
                side: const BorderSide(color: Holo.cyan, width: 1.5),
              ),
              onSelected: (value) async {
                switch (value) {
                  case 'report':
                    await onReportRoom(context);
                    break;
                  case 'block':
                    await onDmBlock();
                    break;
                  case 'unblock':
                    await onDmUnblock();
                    break;
                  case 'leave':
                    await onLeaveRoom(context);
                    break;
                }
              },
              itemBuilder: (ctx) {
                final tr = ctx.tr;
                final isDm = character.isDirectMessage;
                return <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'report',
                    child: Row(
                      children: [
                        Icon(
                          Icons.flag_outlined,
                          size: 22,
                          color: scheme.onSurface,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(tr('chatMenuReport'))),
                      ],
                    ),
                  ),
                  if (isDm && dmShowBlockInMenu)
                    PopupMenuItem<String>(
                      value: 'block',
                      child: Row(
                        children: [
                          Icon(
                            Icons.block_rounded,
                            size: 22,
                            color: scheme.error,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              tr('chatMenuBlock'),
                              style: TextStyle(color: scheme.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (isDm && dmShowUnblockInMenu)
                    PopupMenuItem<String>(
                      value: 'unblock',
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock_open_rounded,
                            size: 22,
                            color: scheme.onSurface,
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(tr('chatMenuUnblock'))),
                        ],
                      ),
                    ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'leave',
                    child: Row(
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          size: 22,
                          color: scheme.onSurface,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(tr('chatMenuLeave'))),
                      ],
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              if (showDmStrangerBanner)
                _DmStrangerBanner(
                  onAddFriend: () => unawaited(onDmAddFriend()),
                  onBlock: () => unawaited(onDmBlock()),
                ),
              if (showDmBlockedByMeBanner)
                _DmBlockedByMeBanner(onUnblock: () => unawaited(onDmUnblock())),
              if (showDmBlockedByThemBanner) const _DmBlockedByThemBanner(),
              Expanded(
                child: Consumer<ChatViewModel>(
                  builder: (context, viewModel, child) {
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => _scrollToBottom(),
                    );
                    return ChatList(
                      messages: viewModel.messages,
                      character: character,
                      isGenerating: viewModel.isGenerating,
                      scrollController: scrollController,
                      chatRoomId: chatRoomId,
                    );
                  },
                ),
              ),
              Consumer<ChatViewModel>(
                builder: (context, viewModel, child) {
                  return ChatInput(
                    controller: viewModel.messageController,
                    onSend: () {
                      if (viewModel.messageController.text.trim().isNotEmpty) {
                        viewModel.sendMessage();
                      }
                    },
                    isGenerating: viewModel.isGenerating,
                    character: character,
                    canSendMessage: canSendMessage && !viewModel.isGenerating,
                    hintOverride: messageHintOverride,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DmStrangerBanner extends StatelessWidget {
  const _DmStrangerBanner({required this.onAddFriend, required this.onBlock});

  final VoidCallback onAddFriend;
  final VoidCallback onBlock;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.secondaryContainer.withValues(alpha: 0.7),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: scheme.onSecondaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr('dmStrangerBanner'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSecondaryContainer,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                TextButton(
                  onPressed: onBlock,
                  child: Text(context.tr('dmStrangerBlock')),
                ),
                FilledButton(
                  onPressed: onAddFriend,
                  child: Text(context.tr('dmStrangerAddFriend')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DmBlockedByMeBanner extends StatelessWidget {
  const _DmBlockedByMeBanner({required this.onUnblock});

  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.errorContainer.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            Icon(Icons.block, size: 20, color: scheme.onErrorContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.tr('dmBlockedByMeBanner'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onErrorContainer,
                  height: 1.35,
                ),
              ),
            ),
            TextButton(
              onPressed: onUnblock,
              child: Text(context.tr('dmUnblock')),
            ),
          ],
        ),
      ),
    );
  }
}

class _DmBlockedByThemBanner extends StatelessWidget {
  const _DmBlockedByThemBanner();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            Icon(
              Icons.shield_outlined,
              size: 20,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.tr('dmBlockedByThemBanner'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
