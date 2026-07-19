import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/di/injection.dart';
import '../../core/ui/app_scaffold_messenger.dart';
import '../../domain/entities/character.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/repositories/ai_chat_repository.dart';
import 'chat_generation_registry.dart';

/// Local single-user id (no auth).
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
  final String insufficientPointsMessage;
  final VoidCallback? onInsufficientPoints;
  final TextEditingController messageController = TextEditingController();

  List<ChatMessage> _messages = [];
  bool _isGenerating = false;
  bool _disposed = false;

  ChatViewModel({
    required this.character,
    required this.chatRepository,
    required this.aiChatRepository,
    required this.insufficientPointsMessage,
    this.onInsufficientPoints,
    required String appUiLanguageCode,
  }) {
    _loadMessages();
    aiChatRepository.initializeForCharacter(
      character,
      appUiLanguageCode: appUiLanguageCode,
    );
  }

  List<ChatMessage> get messages => _messages;
  bool get isGenerating => _isGenerating;

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
      _safeNotify();
    } catch (e) {
      debugPrint('Failed to load messages: $e');
    }
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

  Future<void> _sendUserMessage(String userMessage) async {
    final notifier = pointsBalanceNotifier;
    if (notifier != null) {
      if (notifier.balance == null) {
        await notifier.loadInitial();
      }
      final bal = notifier.balance;
      if (bal != null && bal < 1) {
        appScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text(insufficientPointsMessage)),
        );
        onInsufficientPoints?.call();
        return;
      }
    }

    final userChatMessage = ChatMessage(
      content: userMessage,
      role: 'user',
      timestamp: DateTime.now(),
    );

    _messages.add(userChatMessage);
    final userRowId = await chatRepository.saveMessage(
      character,
      userChatMessage,
    );
    if (userRowId != null) {
      final i = _messages.length - 1;
      _messages[i] = _messages[i].copyWith(serverId: userRowId);
    }
    _safeNotify();

    _isGenerating = true;
    _safeNotify();

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
    try {
      final aiMessage = await aiChatRepository.generateResponse(userMessage);
      await chatRepository.saveMessage(character, aiMessage);
      final spend = await pointsRepository.spendPoints(1, 'character_chat');
      if (spend.ok) {
        pointsBalanceNotifier?.setBalance(spend.balance);
      } else {
        if (spend.error == 'insufficient_points' && !_disposed) {
          onInsufficientPoints?.call();
        }
        debugPrint('Point spend failed after AI reply: ${spend.error}');
      }
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
