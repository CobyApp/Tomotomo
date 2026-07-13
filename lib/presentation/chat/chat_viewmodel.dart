import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/di/injection.dart';
import '../../core/ui/app_scaffold_messenger.dart';
import '../../domain/entities/character.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/repositories/ai_chat_repository.dart';

/// Local single-user id (no auth).
const String _localUserId = 'local';

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
    aiChatRepository.initializeForCharacter(character, appUiLanguageCode: appUiLanguageCode);
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

  Future<void> _loadMessages() async {
    try {
      _messages = await chatRepository.getMessages(character);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load messages: $e');
    }
  }

  Future<void> _reloadMessages() async {
    if (_isGenerating) return;
    try {
      _messages = await chatRepository.getMessages(character);
      notifyListeners();
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
    if (!character.isDirectMessage) {
      final notifier = pointsBalanceNotifier;
      if (notifier != null) {
        if (notifier.balance == null) {
          await notifier.refreshFromProfile(_localUserId);
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
    }

    final userChatMessage = ChatMessage(
      content: userMessage,
      role: 'user',
      timestamp: DateTime.now(),
      senderId: character.isDirectMessage ? _localUserId : null,
    );

    _messages.add(userChatMessage);
    final userRowId = await chatRepository.saveMessage(character, userChatMessage);
    if (userRowId != null) {
      final i = _messages.length - 1;
      _messages[i] = _messages[i].copyWith(serverId: userRowId);
    }
    notifyListeners();

    if (character.isDirectMessage) {
      return;
    }

    _isGenerating = true;
    notifyListeners();

    try {
      final aiMessage = await aiChatRepository.generateResponse(userMessage);
      _messages.add(aiMessage);
      final aiRowId = await chatRepository.saveMessage(character, aiMessage);
      if (aiRowId != null) {
        final i = _messages.length - 1;
        _messages[i] = _messages[i].copyWith(serverId: aiRowId);
      }
      final spend = await pointsRepository.spendPoints(1, 'character_chat');
      if (spend.ok) {
        pointsBalanceNotifier?.setBalance(spend.balance);
      } else {
        if (spend.error == 'insufficient_points') {
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
      _messages.add(errorBubble);
      notifyListeners();
      try {
        await chatRepository.saveMessage(character, errorBubble);
      } catch (saveErr) {
        debugPrint('Failed to persist AI error message: $saveErr');
      }
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<void> resetChat() async {
    try {
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
    if (!character.isDirectMessage) {
      aiChatRepository.resetChat();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    messageController.dispose();
    super.dispose();
  }
}
