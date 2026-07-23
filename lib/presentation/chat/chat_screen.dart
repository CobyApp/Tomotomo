import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/ui/ui.dart';
import '../../core/ui/points_toolbar_chip.dart';
import '../../core/ui/paper/paper_tokens.dart';
import '../../core/ui/paper/paper_theme.dart';
import '../../core/ui/paper/paper_widgets.dart';
import '../../core/ui/paper/paper_loading.dart';
import '../../core/ui/paper/paper_dialog.dart';
import '../../domain/entities/character.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/repositories/ai_chat_repository.dart';
import '../../data/chat_background/chat_background.dart';
import '../../data/chat_background/chat_background_presets.dart';
import '../../data/chat_background/chat_background_store.dart';
import '../../data/on_device/on_device_model_manager.dart';
import '../../domain/on_device/on_device_model_snapshot.dart';
import '../on_device/on_device_model_setup_screen.dart';
import '../locale/l10n_context.dart';
import '../locale/locale_notifier.dart';
import '../points/points_topup_prompt.dart';
import 'chat_message_report.dart';
import 'chat_background_picker.dart';
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
  late final ChatBackgroundStore _bgStore;
  late ChatBackground _background;

  @override
  void initState() {
    super.initState();
    _bgStore = context.read<ChatBackgroundStore>();
    _background = _bgStore.get(widget.character.id);
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
            background: _background,
            onReportRoom: (ctx) => confirmAndReportChatRoom(
              ctx,
              character: widget.character,
              chatRoomId: viewModel.chatRoomId,
            ),
            onLeaveRoom: (ctx) => _confirmLeaveRoom(ctx, viewModel),
            onOpenBackground: _openBackgroundPicker,
          );
        },
      ),
    );
  }

  Future<void> _openBackgroundPicker(BuildContext context) async {
    final result = await openChatBackgroundPicker(
      context,
      characterId: widget.character.id,
      current: _background,
      store: _bgStore,
    );
    if (result != null && mounted) {
      setState(() => _background = result);
    }
  }

  Future<void> _confirmLeaveRoom(
    BuildContext context,
    ChatViewModel viewModel,
  ) async {
    final name = widget.character.displayNamePrimary;
    final ok = await showPaperConfirm(
      context,
      title: context.tr('chatsDeleteTitle'),
      message: context.tr('chatsDeleteBodyCharacter', params: {'name': name}),
      confirmLabel: context.tr('confirm'),
    );
    if (!ok || !mounted) return;
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
  final ChatBackground background;
  final Future<void> Function(BuildContext context) onReportRoom;
  final Future<void> Function(BuildContext context) onLeaveRoom;
  final Future<void> Function(BuildContext context) onOpenBackground;

  const _ChatScreenContent({
    required this.character,
    required this.scrollController,
    required this.chatRoomId,
    required this.background,
    required this.onReportRoom,
    required this.onLeaveRoom,
    required this.onOpenBackground,
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
    final p = context.paper;

    return buildChatBackground(
      context,
      background,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shadowColor: Colors.transparent,
          toolbarHeight: 64,
          shape: Border(bottom: BorderSide(color: p.cardEdge)),
          centerTitle: false,
          foregroundColor: p.ink,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: p.ink,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              PolaroidAvatar(
                size: 44,
                child: character.hasAvatar
                    ? Image(image: character.imageProvider, fit: BoxFit.cover)
                    : const PersonAvatarGlyph(size: 44),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      character.displayNamePrimary,
                      style: cuteDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: p.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (character.displayNameSecondary.isNotEmpty)
                      Text(
                        character.displayNameSecondary,
                        style: AppTextStyles.listSubtitle(
                          context,
                        ).copyWith(color: p.inkSoft),
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
              icon: Icon(Icons.more_horiz_rounded, color: p.ink),
              offset: const Offset(0, 40),
              color: p.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(PaperRadii.button),
                side: BorderSide(color: p.cardEdge),
              ),
              onSelected: (value) async {
                switch (value) {
                  case 'background':
                    await onOpenBackground(context);
                    break;
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
                    value: 'background',
                    child: Row(
                      children: [
                        Icon(
                          Icons.wallpaper_rounded,
                          size: 22,
                          color: p.ink,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            tr('chatMenuBackground'),
                            style: TextStyle(color: p.ink),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'report',
                    child: Row(
                      children: [
                        Icon(Icons.flag_outlined, size: 22, color: p.ink),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            tr('chatMenuReport'),
                            style: TextStyle(color: p.ink),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'leave',
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded, size: 22, color: p.ink),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            tr('chatMenuLeave'),
                            style: TextStyle(color: p.ink),
                          ),
                        ),
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
              Consumer<OnDeviceModelManager>(
                builder: (context, manager, _) {
                  // Until the on-device model is ready, replace the input with
                  // a friendly "preparing" bar so chat never silently fails.
                  if (!manager.isReady) {
                    return _ModelGateBar(snapshot: manager.snapshot);
                  }
                  return Consumer<ChatViewModel>(
                    builder: (context, viewModel, child) {
                      return ChatInput(
                        controller: viewModel.messageController,
                        onSend: () {
                          if (viewModel.messageController.text
                              .trim()
                              .isNotEmpty) {
                            viewModel.sendMessage();
                          }
                        },
                        isGenerating: viewModel.isGenerating,
                        character: character,
                        canSendMessage: !viewModel.isGenerating,
                      );
                    },
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

/// Shown in place of the chat input while the on-device model is downloading
/// or missing, so the user knows chat will unlock shortly.
class _ModelGateBar extends StatelessWidget {
  const _ModelGateBar({required this.snapshot});

  final OnDeviceModelSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    final downloading =
        snapshot.phase == OnDeviceModelPhase.downloading ||
        snapshot.phase == OnDeviceModelPhase.finalizing;
    final pct = (snapshot.progress.clamp(0.0, 1.0) * 100).round();
    final label = downloading
        ? context.tr(
            'chatModelPreparing',
            params: {'progress': '$pct'},
          )
        : context.tr('chatModelNotReady');

    return SafeArea(
      top: false,
      child: InkWell(
        onTap: downloading
            ? null
            : () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const OnDeviceModelSetupScreen(),
                ),
              ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: p.card,
            border: Border(top: BorderSide(color: p.cardEdge)),
          ),
          child: Row(
            children: [
              if (downloading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: PaperLoading(size: 6),
                )
              else
                Icon(Icons.download_rounded, size: 18, color: p.coral),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: p.inkSoft,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ),
              if (!downloading)
                Icon(Icons.chevron_right_rounded, color: p.inkSoft),
            ],
          ),
        ),
      ),
    );
  }
}
