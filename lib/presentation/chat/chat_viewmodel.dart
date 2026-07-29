import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/di/injection.dart';
import '../../core/locale/languages.dart';
import '../../core/notifications/local_notifications.dart';
import '../../domain/entities/character.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/repositories/ai_chat_repository.dart';
import 'chat_generation_registry.dart';

/// Local single-user id (no auth).
const String _localUserId = 'local';

/// Points a single successful reply costs. The pre-send balance check and the
/// actual charge must always use this same number.
const int kChatReplyPointCost = 5;

/// Short assistant line in the FRIEND's own language (no stack traces or API
/// text). This is the friend speaking, so it follows [Character.friendLanguage]
/// — branching on the Korean-persona flag alone made English and Chinese
/// friends apologise in Japanese.
String _aiChatErrorBubbleText(Character character) {
  switch (normalizeLang(character.friendLanguage)) {
    case 'ko':
      return '앗, 오류가 났어… 미안.';
    case 'en':
      return 'Oh no, something went wrong… sorry!';
    case 'zh':
      return '啊，出错了…抱歉。';
    case 'ja':
    default:
      return 'あ、エラーが出ちゃった…ごめん。';
  }
}

class ChatViewModel extends ChangeNotifier {
  final Character character;
  final ChatRepository chatRepository;
  final AiChatRepository aiChatRepository;
  final VoidCallback? onInsufficientPoints;
  final TextEditingController messageController = TextEditingController();

  List<ChatMessage> _messages = [];
  bool _isGenerating = false;
  bool _disposed = false;

  ChatViewModel({
    required this.character,
    required this.chatRepository,
    required this.aiChatRepository,
    this.onInsufficientPoints,
    required String appUiLanguageCode,
  }) {
    _loadMessages();
    aiChatRepository.initializeForCharacter(
      character,
      appUiLanguageCode: appUiLanguageCode,
    );
    unawaited(_primeUserName(appUiLanguageCode));
  }

  /// Loads the learner's own name from their profile so the friend can address
  /// them by name. Best-effort; a reply works fine without it.
  Future<void> _primeUserName(String appUiLanguageCode) async {
    try {
      final profile = await profileRepository.getProfile(_localUserId);
      final name = profile?.displayName?.trim();
      if (name == null || name.isEmpty || _disposed) return;
      aiChatRepository.initializeForCharacter(
        character,
        appUiLanguageCode: appUiLanguageCode,
        userName: name,
      );
    } catch (_) {
      // Ignore — the friend simply won't use the learner's name.
    }
  }

  List<ChatMessage> get messages => _messages;
  bool get isGenerating => _isGenerating;

  /// Set when the stored history could not be read.
  ///
  /// Without this a failed load left _messages empty and the room rendered the
  /// "say hi to get started" empty state — a conversation of weeks looked brand
  /// new, with no error and no retry, and the old messages reappeared later once
  /// a send re-read the list.
  bool get loadFailed => _loadFailed;
  bool _loadFailed = false;

  /// True when the last message is the learner's and no reply is coming.
  ///
  /// The registry lives in memory, so if iOS terminates the app during the
  /// multi-second inference the reply is simply lost: the user's message is
  /// already on disk, and on relaunch the room showed it followed by silence —
  /// no error, no typing state, nothing to tap. The app promises the reply
  /// survives leaving the room, so silence reads as a bug.
  bool get awaitingRetry =>
      !_isGenerating && _messages.isNotEmpty && _messages.last.role == 'user';

  /// Asks again for a reply to the last message, without re-sending it.
  Future<void> retryLastMessage() async {
    if (_isGenerating || !awaitingRetry) return;
    final text = _messages.last.content.trim();
    if (text.isEmpty) return;
    if (!await _hasPointsForReply()) {
      onInsufficientPoints?.call();
      return;
    }
    _isGenerating = true;
    _safeNotify();
    await ChatGenerationRegistry.instance.run(
      character.id,
      () => _generateAndSave(text),
    );
    if (_disposed) return;
    _isGenerating = false;
    _safeNotify();
    await _reloadMessages();
  }

  /// Room id equals the character id in the local store.
  String? get chatRoomId => character.id;

  /// After app returns from background: reload the local message list.
  void onAppResumedSync() {
    if (_disposed) return;
    unawaited(_reloadMessages());
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _loadMessages() async {
    try {
      _messages = await chatRepository.getMessages(character);
      // A reply may still be generating for this room (user left mid-reply and
      // came back). Show the loading bubble and refresh when it finishes.
      final pending = ChatGenerationRegistry.instance.inFlight(character.id);
      if (pending != null) {
        _isGenerating = true;
        pending.whenComplete(() async {
          if (_disposed) return;
          _isGenerating = false;
          _safeNotify();
          await _reloadMessages();
        });
      }
      _loadFailed = false;
      _safeNotify();
    } catch (e) {
      debugPrint('Failed to load messages: $e');
      _loadFailed = true;
      _safeNotify();
    }
  }

  /// Re-reads the stored history after a failed load.
  Future<void> retryLoad() async {
    _loadFailed = false;
    _safeNotify();
    await _loadMessages();
  }

  Future<void> _reloadMessages() async {
    if (_isGenerating) return;
    try {
      _messages = await chatRepository.getMessages(character);
      _safeNotify();
    } catch (e) {
      debugPrint('Message reload failed: $e');
    }
  }

  Future<void> sendMessage() async {
    final userMessage = messageController.text.trim();
    if (userMessage.isEmpty || _isGenerating) return;
    // Only clear once the send is actually going through: clearing up front
    // threw the text away whenever the balance check blocked the send.
    if (!await _hasPointsForReply()) {
      onInsufficientPoints?.call();
      return;
    }
    messageController.clear();
    // Ask for notification permission the first time — so we can tell the user
    // when a reply finishes while they're away.
    unawaited(LocalNotifications.ensurePermission());
    await _sendUserMessage(userMessage);
  }

  /// Whether the wallet can cover one reply. Loads the balance if unknown.
  Future<bool> _hasPointsForReply() async {
    final notifier = pointsBalanceNotifier;
    if (notifier == null) return true;
    if (notifier.balance == null) await notifier.loadInitial();
    final balance = notifier.balance;
    return balance == null || balance >= kChatReplyPointCost;
  }

  /// Compact one-line preview of the reply for a notification body.
  static String _notificationPreview(String content) {
    final t = content.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t.length <= 100 ? t : '${t.substring(0, 99)}…';
  }

  Future<void> _sendUserMessage(String userMessage) async {
    if (!await _hasPointsForReply()) {
      // The top-up sheet states the problem and offers the ad, so no snackbar.
      onInsufficientPoints?.call();
      return;
    }

    final userChatMessage = ChatMessage(
      content: userMessage,
      role: 'user',
      timestamp: DateTime.now(),
    );

    // Claim the room BEFORE the awaits below. The send button is gated on
    // isGenerating, and this used to be set only after the save and the 1s beat,
    // leaving the input live for over a second: a second message sent in that
    // window was persisted, then collapsed onto the first generation by the
    // registry and never shown to the model — no reply, no error, no hint.
    _isGenerating = true;
    _messages.add(userChatMessage);
    _safeNotify();

    final index = _messages.length - 1;
    try {
      final userRowId = await chatRepository.saveMessage(
        character,
        userChatMessage,
      );
      // Index captured before the await: a reload landing inside it used to make
      // this write to the wrong row, or throw RangeError on a fresh room.
      if (userRowId != null && index >= 0 && index < _messages.length) {
        _messages[index] = _messages[index].copyWith(serverId: userRowId);
      }
    } catch (e) {
      // Claiming the room before this await (so a second send cannot be
      // swallowed) means a throw here would otherwise leave the room "typing"
      // forever with the composer read-only — recoverable only by leaving the
      // screen. Give the message back to the composer instead.
      debugPrint('Saving the outgoing message failed: $e');
      if (index >= 0 && index < _messages.length) _messages.removeAt(index);
      messageController.text = userMessage;
      _isGenerating = false;
      _safeNotify();
      return;
    }
    _safeNotify();

    // Beat before the "typing…" indicator appears — as if the friend read the
    // message first, then started typing (not shown instantly).
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    if (_disposed) return;

    // Run generation through the registry so it keeps going and persists the
    // reply even if the user leaves this screen mid-generation.
    await ChatGenerationRegistry.instance.run(
      character.id,
      () => _generateAndSave(userMessage),
    );

    if (_disposed) return;
    _isGenerating = false;
    _safeNotify();
    await _reloadMessages();
  }

  /// Generates the AI reply and persists it. Runs independent of the screen —
  /// must NOT touch UI state or bail on [_disposed]; it always saves so the
  /// answer finishes even after leaving the chat.
  Future<void> _generateAndSave(String userMessage) async {
    final ChatMessage aiMessage;
    try {
      // One generation produces the reply AND its study sheet (translation +
      // vocabulary), so the expression sheet shows instantly with no extra call.
      aiMessage = await aiChatRepository.generateResponse(userMessage);
      if (aiMessage.content.trim().isEmpty) {
        // Valid JSON with no content field parses to an empty string. Saving it
        // put a blank bubble in the history for good and charged for it.
        throw const FormatException('empty reply');
      }
      // The user may have left the room or deleted it during the generation.
      // Saving into a deleted room recreated it, leaving a conversation the user
      // had just removed holding a reply with no question before it.
      if (!await chatRepository.roomExists(character.id)) {
        debugPrint('Reply dropped: room ${character.id} no longer exists');
        return;
      }
      await chatRepository.saveMessage(character, aiMessage);
    } catch (e) {
      debugPrint('AI chat failed: $e');
      final errorBubble = ChatMessage(
        content: _aiChatErrorBubbleText(character),
        role: 'assistant',
        timestamp: DateTime.now(),
      );
      try {
        await chatRepository.saveMessage(character, errorBubble);
      } catch (saveErr) {
        debugPrint('Failed to persist AI error message: $saveErr');
      }
      return;
    }

    // Past this point the reply is saved. These steps must NOT be able to append
    // an error bubble after a successful reply, which is what the single wide try
    // block above used to do when the points write failed.
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      unawaited(
        LocalNotifications.showChatReply(
          title: character.name,
          body: _notificationPreview(aiMessage.content),
        ),
      );
    }
    try {
      final spend = await pointsRepository.spendPoints(
        kChatReplyPointCost,
        'character_chat',
      );
      if (spend.ok) {
        pointsBalanceNotifier?.setBalance(spend.balance);
      } else {
        if (spend.error == 'insufficient_points' && !_disposed) {
          onInsufficientPoints?.call();
        }
        debugPrint('Point spend failed after AI reply: ${spend.error}');
      }
    } catch (e) {
      debugPrint('Point spend threw after AI reply: $e');
    }
  }

  Future<void> resetChat() async {
    try {
      await chatRepository.clearMessages(character);
      _messages.clear();
      messageController.clear();
      _isGenerating = false;

      aiChatRepository.resetChat();
      _safeNotify();
    } catch (e) {
      debugPrint('Failed to reset chat: $e');
    }
  }

  /// Deletes the local room (and messages) and clears local state. Caller should pop the screen.
  Future<void> leaveRoom() async {
    if (_disposed) return;
    try {
      await chatRepository.deleteRoom(character.id);
    } catch (e) {
      debugPrint('leaveRoom delete failed: $e');
      rethrow;
    }

    _messages.clear();
    messageController.clear();
    _isGenerating = false;
    aiChatRepository.resetChat();
    _safeNotify();
  }

  @override
  void dispose() {
    _disposed = true;
    messageController.dispose();
    super.dispose();
  }
}
