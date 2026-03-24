import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/app_supabase.dart';
import '../../core/ui/ui.dart';
import '../../core/tts/tts_language_resolver.dart';
import '../../core/theme/chat_theme_data.dart';
import '../../domain/entities/character.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/ai_chat_repository.dart';
import '../../domain/repositories/chat_repository.dart';
import '../locale/l10n_context.dart';
import '../locale/locale_notifier.dart';
import 'chat_expression_sheet.dart';
import 'chat_viewmodel.dart';
import 'widgets/chat_bubble.dart';

/// Voice conversation: hold mic to speak; transcript syncs to the same Supabase room as [ChatScreen].
/// AI rooms get TTS replies; DM uses realtime broadcast so only one side holds the mic while the peer speaks.
class VoiceCallScreen extends StatefulWidget {
  final Character character;
  final ChatRepository chatRepository;
  final AiChatRepository aiChatRepository;

  const VoiceCallScreen({
    super.key,
    required this.character,
    required this.chatRepository,
    required this.aiChatRepository,
  });

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> with WidgetsBindingObserver {
  late final ChatViewModel _viewModel;
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final ScrollController _scrollController = ScrollController();

  bool _speechReady = false;
  bool _speechInitDone = false;
  bool _listening = false;
  bool _holdActive = false;
  String _partialText = '';
  String _lastFinalText = '';
  String? _sttLocaleId;

  RealtimeChannel? _dmVoiceChannel;
  String? _dmVoiceRoomId;
  bool _dmVoiceSubscribed = false;
  bool _peerSpeaking = false;
  Timer? _peerSpeakingTimer;
  Future<void>? _dmEnsureFuture;

  @override
  void initState() {
    super.initState();
    _viewModel = ChatViewModel(
      character: widget.character,
      chatRepository: widget.chatRepository,
      aiChatRepository: widget.aiChatRepository,
    );
    _viewModel.addListener(_onViewModelChanged);
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initSpeechAndTts());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_ensureDmVoiceChannelSerialized());
    });
  }

  Future<void> _ensureDmVoiceChannelSerialized() {
    return _dmEnsureFuture ??= _ensureDmVoiceChannel().whenComplete(() => _dmEnsureFuture = null);
  }

  void _onViewModelChanged() {
    unawaited(_ensureDmVoiceChannelSerialized());
  }

  /// Unwrap broadcast payload (flat or nested `payload` from server).
  Map<String, dynamic> _broadcastPayloadMap(Map<String, dynamic> raw) {
    final inner = raw['payload'];
    if (inner is Map) {
      return Map<String, dynamic>.from(inner);
    }
    return raw;
  }

  void _onDmSpeakingBroadcast(Map<String, dynamic> raw) {
    if (!widget.character.isDirectMessage || !mounted) return;
    final p = _broadcastPayloadMap(raw);
    final uid = p['user_id']?.toString();
    final myId = AppSupabase.auth.currentUser?.id;
    if (uid == null || myId == null || uid == myId) return;

    final active = p['active'] == true || p['active'] == 'true';
    _peerSpeakingTimer?.cancel();
    if (active) {
      setState(() => _peerSpeaking = true);
      _peerSpeakingTimer = Timer(const Duration(seconds: 45), () {
        if (mounted) setState(() => _peerSpeaking = false);
      });
    } else {
      setState(() => _peerSpeaking = false);
    }
  }

  void _onDmVoiceSubscribeStatus(RealtimeSubscribeStatus status, [Object? error]) {
    if (!mounted) return;
    switch (status) {
      case RealtimeSubscribeStatus.subscribed:
        setState(() => _dmVoiceSubscribed = true);
        break;
      case RealtimeSubscribeStatus.timedOut:
      case RealtimeSubscribeStatus.channelError:
        setState(() => _dmVoiceSubscribed = false);
        break;
      case RealtimeSubscribeStatus.closed:
        setState(() => _dmVoiceSubscribed = false);
        break;
    }
  }

  Future<void> _ensureDmVoiceChannel() async {
    if (!widget.character.isDirectMessage) return;
    final roomId = _viewModel.chatRoomId;
    if (roomId == null || roomId.isEmpty) return;
    if (_dmVoiceRoomId == roomId && _dmVoiceChannel != null) return;

    await _teardownDmVoiceChannel(sendSpeakingFalse: true);

    _dmVoiceRoomId = roomId;
    _dmVoiceSubscribed = false;
    final ch = AppSupabase.client.channel('dm_voice:$roomId');
    ch
        .onBroadcast(
          event: 'speaking',
          callback: _onDmSpeakingBroadcast,
        )
        .subscribe(_onDmVoiceSubscribeStatus);
    _dmVoiceChannel = ch;
    if (mounted) setState(() {});
  }

  Future<void> _teardownDmVoiceChannel({required bool sendSpeakingFalse}) async {
    _peerSpeakingTimer?.cancel();
    _peerSpeakingTimer = null;
    final ch = _dmVoiceChannel;
    _dmVoiceChannel = null;
    _dmVoiceRoomId = null;
    _dmVoiceSubscribed = false;
    if (ch != null) {
      if (sendSpeakingFalse) {
        final uid = AppSupabase.auth.currentUser?.id;
        if (uid != null) {
          try {
            await ch.sendBroadcastMessage(
              event: 'speaking',
              payload: {'user_id': uid, 'active': false},
            );
          } catch (_) {}
        }
      }
      await AppSupabase.client.removeChannel(ch);
    }
    if (mounted) setState(() => _peerSpeaking = false);
  }

  Future<void> _sendDmSpeaking(bool active) async {
    if (!widget.character.isDirectMessage) return;
    final uid = AppSupabase.auth.currentUser?.id;
    final ch = _dmVoiceChannel;
    if (uid == null || ch == null) return;
    try {
      await ch.sendBroadcastMessage(
        event: 'speaking',
        payload: {'user_id': uid, 'active': active},
      );
    } catch (_) {}
  }

  bool _isFromCurrentUser(ChatMessage message) {
    if (!widget.character.isDirectMessage) {
      return message.role == 'user';
    }
    final uid = AppSupabase.auth.currentUser?.id;
    if (message.senderId != null && uid != null) return message.senderId == uid;
    return false;
  }

  bool get _micEnabled {
    if (!_speechReady || _viewModel.isGenerating) return false;
    if (widget.character.isDirectMessage) {
      if (_peerSpeaking || !_dmVoiceSubscribed) return false;
    }
    return true;
  }

  Future<void> _initSpeechAndTts() async {
    if (!widget.character.isDirectMessage) {
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1);
      await _tts.setPitch(1);
    }

    final ok = await _speech.initialize(
      onError: (_) {},
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') {
          if (mounted) setState(() => _listening = false);
        }
      },
    );

    if (!mounted) return;

    if (!ok) {
      setState(() {
        _speechInitDone = true;
        _speechReady = false;
      });
      return;
    }

    final locales = await _speech.locales();
    _sttLocaleId = _pickSttLocale(locales.map((e) => e.localeId).toList());

    setState(() {
      _speechInitDone = true;
      _speechReady = true;
    });
  }

  /// Prefer Japanese for practice, then Korean, then English.
  String? _pickSttLocale(List<String> available) {
    const preferred = ['ja_JP', 'ko_KR', 'en_US', 'en-GB', 'en_GB'];
    for (final p in preferred) {
      if (available.contains(p)) return p;
    }
    for (final a in available) {
      if (a.startsWith('ja')) return a;
    }
    for (final a in available) {
      if (a.startsWith('ko')) return a;
    }
    return available.isNotEmpty ? available.first : null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      unawaited(_speech.stop());
      if (!widget.character.isDirectMessage) {
        unawaited(_tts.stop());
      }
      if (_holdActive) {
        unawaited(_sendDmSpeaking(false));
      }
      if (mounted) {
        setState(() {
          _listening = false;
          _holdActive = false;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      _viewModel.onAppResumedSync();
    }
  }

  Future<void> _startListen() async {
    if (!_micEnabled || _listening || _viewModel.isGenerating) return;
    if (_sttLocaleId == null) return;

    setState(() {
      _listening = true;
      _partialText = '';
      _lastFinalText = '';
    });

    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _partialText = result.recognizedWords;
          if (result.finalResult) {
            _lastFinalText = result.recognizedWords;
          }
        });
      },
      localeId: _sttLocaleId,
      listenFor: const Duration(seconds: 45),
      pauseFor: const Duration(seconds: 3),
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        partialResults: true,
        cancelOnError: true,
      ),
    );
  }

  Future<void> _stopListen({required bool sendIfText}) async {
    await _speech.stop();
    if (!mounted) return;
    setState(() => _listening = false);

    final text = (_lastFinalText.trim().isNotEmpty ? _lastFinalText : _partialText).trim();
    _partialText = '';
    _lastFinalText = '';

    if (!sendIfText || text.isEmpty || _viewModel.isGenerating) return;

    await _viewModel.sendTextMessage(text);
    if (!mounted) return;

    _scrollToBottom();
    if (widget.character.isDirectMessage) return;

    final messages = _viewModel.messages;
    if (messages.isNotEmpty) {
      final last = messages.last;
      if (last.role == 'assistant') {
        await _speakAssistant(last);
      }
    }
  }

  Future<void> _speakAssistant(ChatMessage m) async {
    if (!mounted) return;
    final plain = m.content.trim();
    if (plain.isEmpty) return;
    final appLang = context.read<LocaleNotifier>().languageCode;
    final decision = resolveTtsLanguage(plain, appUiLanguage: appLang);
    if (decision.spokenText.isEmpty) return;
    await _tts.stop();
    await _tts.setLanguage(decision.engineLocaleId);
    await _tts.speak(decision.spokenText);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  bool _showExpressionForMessage(ChatMessage m) {
    return widget.character.isDirectMessage || m.role != 'user';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _viewModel.removeListener(_onViewModelChanged);
    unawaited(_speech.stop());
    if (!widget.character.isDirectMessage) {
      unawaited(_tts.stop());
    }
    unawaited(_teardownDmVoiceChannel(sendSpeakingFalse: true));
    _viewModel.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chatTheme = Theme.of(context).extension<ChatThemeData>();
    final chatBg =
        chatTheme?.chatBg ?? (Color.lerp(scheme.surfaceContainerLow, scheme.primary, 0.06) ?? scheme.surfaceContainerLow);

    final holdHint = widget.character.isDirectMessage
        ? context.tr('voiceCallHoldHintDm')
        : context.tr('voiceCallHoldHint');

    return Scaffold(
      backgroundColor: chatBg,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: scheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(context.tr('voiceCallTitle'), style: AppTextStyles.pageTitle(context)),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
          return Column(
            children: [
              if (_speechInitDone && !_speechReady)
                Material(
                  color: scheme.errorContainer.withValues(alpha: 0.35),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Text(
                      context.tr('voiceCallSttUnavailable'),
                      style: TextStyle(color: scheme.onErrorContainer, fontSize: 13),
                    ),
                  ),
                ),
              if (widget.character.isDirectMessage && _peerSpeaking)
                Material(
                  color: scheme.secondaryContainer.withValues(alpha: 0.5),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        Icon(Icons.record_voice_over_rounded, size: 20, color: scheme.onSecondaryContainer),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            context.tr('voiceCallPeerSpeaking'),
                            style: TextStyle(color: scheme.onSecondaryContainer, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
                  itemCount: _viewModel.messages.length + (_listening ? 1 : 0),
                  itemBuilder: (context, i) {
                    final list = _viewModel.messages;
                    if (i == list.length) {
                      return _liveSpeechBubble(context);
                    }
                    final m = list[i];
                    final isUser = _isFromCurrentUser(m);
                    final showExpr = _showExpressionForMessage(m);
                    return ChatBubble(
                      message: m,
                      character: widget.character,
                      isUser: isUser,
                      onExplanationTap: showExpr
                          ? () => showChatExpressionSheet(
                                context,
                                message: m,
                                character: widget.character,
                                chatRoomId: _viewModel.chatRoomId,
                              )
                          : null,
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.pageH, 8, AppSpacing.pageH, AppSpacing.pageBottom),
                child: Column(
                  children: [
                    Text(
                      holdHint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Listener(
                      onPointerDown: (_) {
                        if (!_micEnabled) return;
                        _holdActive = true;
                        if (widget.character.isDirectMessage) {
                          unawaited(_sendDmSpeaking(true));
                        }
                        unawaited(_startListen());
                      },
                      onPointerUp: (_) {
                        if (!_holdActive) return;
                        _holdActive = false;
                        if (widget.character.isDirectMessage) {
                          unawaited(_sendDmSpeaking(false));
                        }
                        unawaited(_stopListen(sendIfText: true));
                      },
                      onPointerCancel: (_) {
                        if (!_holdActive) return;
                        _holdActive = false;
                        if (widget.character.isDirectMessage) {
                          unawaited(_sendDmSpeaking(false));
                        }
                        unawaited(_stopListen(sendIfText: false));
                      },
                      child: Material(
                        color: _listening
                            ? scheme.primary
                            : _micEnabled
                                ? scheme.primaryContainer
                                : scheme.surfaceContainerHighest,
                        shape: const CircleBorder(),
                        elevation: _listening ? 8 : 2,
                        child: SizedBox(
                          width: 88,
                          height: 88,
                          child: Icon(
                            Icons.mic_rounded,
                            size: 44,
                            color: _listening
                                ? scheme.onPrimary
                                : _micEnabled
                                    ? scheme.onPrimaryContainer
                                    : scheme.onSurfaceVariant.withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_viewModel.isGenerating)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: scheme.primary),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            context.tr('voiceCallGenerating'),
                            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Provisional user bubble while STT streams partial text (same thread as saved messages).
  Widget _liveSpeechBubble(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shown = _partialText.trim().isEmpty ? context.tr('voiceCallListeningPlaceholder') : _partialText;
    final live = ChatMessage(
      content: shown,
      role: 'user',
      timestamp: DateTime.now(),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Opacity(
          opacity: 0.9,
          child: ChatBubble(
            message: live,
            character: widget.character,
            isUser: true,
            onExplanationTap: _showExpressionForMessage(live)
                ? () => showChatExpressionSheet(
                      context,
                      message: live,
                      character: widget.character,
                      chatRoomId: _viewModel.chatRoomId,
                    )
                : null,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 18, bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.mic, size: 14, color: scheme.primary.withValues(alpha: 0.85)),
              const SizedBox(width: 6),
              Text(
                context.tr('voiceCallLiveCaption'),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
