import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/ui/ui.dart';
import '../../core/ui/points_toolbar_chip.dart';
import '../../core/ui/holo/glitch_text.dart';
import '../../core/ui/holo/holo_tokens.dart';
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
    });
    WidgetsBinding.instance.addObserver(this);
  }

  void _onInsufficientPoints() {
    if (!mounted) return;
    unawaited(showPointsTopUpPrompt(context));
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
          );
        },
      ),
    );
  }

  Future<void> _confirmLeaveRoom(
    BuildContext context,
    ChatViewModel viewModel,
  ) async {
    final name = widget.character.displayNamePrimary;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('chatsDeleteTitle')),
        content: Text(
          context.tr('chatsDeleteBodyCharacter', params: {'name': name}),
        ),
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

  const _ChatScreenContent({
    required this.character,
    required this.scrollController,
    required this.chatRoomId,
    required this.onReportRoom,
    required this.onLeaveRoom,
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
                  case 'leave':
                    await onLeaveRoom(context);
                    break;
                }
              },
              itemBuilder: (ctx) {
                final tr = ctx.tr;
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
                    canSendMessage: !viewModel.isGenerating,
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
