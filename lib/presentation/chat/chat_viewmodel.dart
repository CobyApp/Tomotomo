import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/app_supabase.dart';
import '../../domain/entities/character.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/repositories/ai_chat_repository.dart';

/// Short assistant line matching the character’s main chat language (no stack traces or API text).
String _aiChatErrorBubbleText(Character character) {
  if (character.koreanNationalPersona) {
    return '앗, 오류가 났어… 미안.';
  }
  return 'あ、エラーが出ちゃった…ごめん。';
}

class ChatViewModel extends ChangeNotifier {
  final Character character;
  final ChatRepository chatRepository;
  final AiChatRepository aiChatRepository;
  final TextEditingController messageController = TextEditingController();

  List<ChatMessage> _messages = [];
  bool _isGenerating = false;
  String? _chatRoomId;
  RealtimeChannel? _messagesChannel;
  Timer? _reloadDebounce;
  Timer? _messagesResubscribeTimer;
  int _messagesSubscribeAttempts = 0;
  static const int _maxMessagesResubscribeAttempts = 6;
  bool _disposed = false;

  /// Character chat: skip realtime full reload while AI generation runs; flush once after.
  bool _pendingRealtimeReload = false;

  /// After AI error bubble failed to persist, skip server refetches so Realtime does not wipe the local bubble.
  bool _suppressMessageReloadFromServer = false;

  ChatViewModel({
    required this.character,
    required this.chatRepository,
    required this.aiChatRepository,
  }) {
    _loadMessages();
    aiChatRepository.initializeForCharacter(character);
  }

  List<ChatMessage> get messages => _messages;
  bool get isGenerating => _isGenerating;
  String? get chatRoomId => _chatRoomId;

  /// After app returns from background; same debounce/defer rules as Realtime reload.
  void onAppResumedSync() {
    if (_disposed) return;
    _scheduleReloadFromServer();
  }

  Future<void> _loadMessages() async {
    try {
      _messages = await chatRepository.getMessages(character);
      _chatRoomId = await chatRepository.getChatRoomId(character);
      _subscribeMessagesRealtime();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load messages: $e');
    }
  }

  /// Live updates for this room: inserts (incl. peer / other device), deletes (reset elsewhere).
  /// For AI chats, reload is deferred while [_isGenerating] to avoid wiping in-flight UI.
  void _subscribeMessagesRealtime() {
    if (_disposed) return;
    final roomId = _chatRoomId;
    if (roomId == null || roomId.isEmpty) return;

    unawaited(_messagesChannel != null ? AppSupabase.client.removeChannel(_messagesChannel!) : Future.value());
    _messagesChannel = null;

    final channel = AppSupabase.client.channel('public:chat_messages:room:$roomId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: (_) => _scheduleReloadFromServer(),
        )
        .subscribe(_onMessagesChannelSubscribeStatus);
    _messagesChannel = channel;
  }

  /// After the first persisted message, the room row exists; subscribe if we were not yet.
  Future<void> _ensureRealtimeSubscription() async {
    if (_disposed || character.isDirectMessage) return;
    final id = await chatRepository.getChatRoomId(character);
    if (id == null || id.isEmpty) return;
    _chatRoomId = id;
    if (_messagesChannel == null) {
      _subscribeMessagesRealtime();
    }
  }

  void _onMessagesChannelSubscribeStatus(RealtimeSubscribeStatus status, [Object? error]) {
    if (_disposed) return;
    switch (status) {
      case RealtimeSubscribeStatus.subscribed:
        _messagesSubscribeAttempts = 0;
        _scheduleReloadFromServer();
        break;
      case RealtimeSubscribeStatus.timedOut:
      case RealtimeSubscribeStatus.channelError:
        debugPrint('Chat messages realtime: $status ${error ?? ''}');
        _scheduleMessagesChannelResubscribe();
        break;
      case RealtimeSubscribeStatus.closed:
        break;
    }
  }

  void _scheduleMessagesChannelResubscribe() {
    if (_disposed) return;
    if (_messagesSubscribeAttempts >= _maxMessagesResubscribeAttempts) {
      debugPrint('Chat messages realtime: max resubscribe attempts reached');
      return;
    }
    _messagesSubscribeAttempts++;
    _messagesResubscribeTimer?.cancel();
    final seconds = (2 * _messagesSubscribeAttempts).clamp(2, 20);
    _messagesResubscribeTimer = Timer(Duration(seconds: seconds), () {
      if (_disposed) return;
      _subscribeMessagesRealtime();
    });
  }

  void _scheduleReloadFromServer() {
    _reloadDebounce?.cancel();
    _reloadDebounce = Timer(const Duration(milliseconds: 200), () {
      unawaited(_applyRealtimeReload());
    });
  }

  Future<void> _applyRealtimeReload() async {
    if (!character.isDirectMessage && _isGenerating) {
      _pendingRealtimeReload = true;
      return;
    }
    if (_suppressMessageReloadFromServer) {
      _pendingRealtimeReload = false;
      return;
    }
    await _reloadMessagesFromServer();
  }

  Future<void> _reloadMessagesFromServer() async {
    if (_suppressMessageReloadFromServer) return;
    try {
      final list = await chatRepository.getMessages(character);
      _messages = list;
      notifyListeners();
    } catch (e) {
      debugPrint('Realtime message reload failed: $e');
    }
  }

  void _flushPendingRealtimeReload() {
    if (!_pendingRealtimeReload) return;
    _pendingRealtimeReload = false;
    if (_suppressMessageReloadFromServer) return;
    unawaited(_reloadMessagesFromServer());
  }

  /// Sends [text] as the user message (same pipeline as typing in [messageController]).
  /// Does not read or clear the text field — use for voice / external input.
  Future<void> sendTextMessage(String text) async {
    final userMessage = text.trim();
    if (userMessage.isEmpty || _isGenerating) return;
    await _sendUserMessage(userMessage);
  }

  Future<void> sendMessage() async {
    final userMessage = messageController.text.trim();
    if (userMessage.isEmpty || _isGenerating) return;
    messageController.clear();
    await _sendUserMessage(userMessage);
  }

  /// Records a DM voice clip (file from [AudioRecorder]); uploads then reloads messages.
  Future<String?> sendDmVoiceFile(String localPath) async {
    if (!character.isDirectMessage || _disposed) return null;
    try {
      await chatRepository.sendDirectMessageVoiceNote(character, localPath);
      try {
        final f = File(localPath);
        if (await f.exists()) await f.delete();
      } catch (_) {}
      if (!_disposed) await _reloadMessagesFromServer();
      return null;
    } catch (e) {
      debugPrint('sendDmVoiceFile failed: $e');
      return e.toString();
    }
  }

  Future<void> _sendUserMessage(String userMessage) async {
    _suppressMessageReloadFromServer = false;

    final uid = AppSupabase.auth.currentUser?.id;
    final userChatMessage = ChatMessage(
      content: userMessage,
      role: 'user',
      timestamp: DateTime.now(),
      senderId: character.isDirectMessage ? uid : null,
    );

    _messages.add(userChatMessage);
    await chatRepository.saveMessage(character, userChatMessage);
    await _ensureRealtimeSubscription();
    notifyListeners();

    if (character.isDirectMessage) {
      return;
    }

    _isGenerating = true;
    notifyListeners();

    /// When false, a deferred realtime reload would replace [_messages] and drop the
    /// local-only AI error bubble (e.g. Supabase insert failed). Skip flush in that case.
    var allowPendingRealtimeFlush = true;

    try {
      final aiMessage = await aiChatRepository.generateResponse(userMessage);
      _messages.add(aiMessage);
      await chatRepository.saveMessage(character, aiMessage);
      await _ensureRealtimeSubscription();
    } catch (e) {
      debugPrint('AI chat failed: $e');
      final errorBubble = ChatMessage(
        content: _aiChatErrorBubbleText(character),
        role: 'assistant',
        timestamp: DateTime.now(),
      );
      _messages.add(errorBubble);
      notifyListeners();
      try {
        await chatRepository.saveMessage(character, errorBubble);
        await _ensureRealtimeSubscription();
      } catch (saveErr) {
        debugPrint('Failed to persist AI error message: $saveErr');
        allowPendingRealtimeFlush = false;
        _suppressMessageReloadFromServer = true;
      }
    } finally {
      _isGenerating = false;
      notifyListeners();
      if (allowPendingRealtimeFlush) {
        _flushPendingRealtimeReload();
      } else {
        _pendingRealtimeReload = false;
      }
    }
  }

  Future<void> resetChat() async {
    try {
      _suppressMessageReloadFromServer = false;
      _pendingRealtimeReload = false;
      await chatRepository.clearMessages(character);
      _messages.clear();
      messageController.clear();
      _isGenerating = false;

      if (!character.isDirectMessage) {
        aiChatRepository.resetChat();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to reset chat: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _reloadDebounce?.cancel();
    _messagesResubscribeTimer?.cancel();
    final ch = _messagesChannel;
    if (ch != null) {
      unawaited(AppSupabase.client.removeChannel(ch));
      _messagesChannel = null;
    }
    messageController.dispose();
    super.dispose();
  }
}
