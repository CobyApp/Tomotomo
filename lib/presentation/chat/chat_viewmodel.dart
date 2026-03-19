import 'package:flutter/material.dart';
import '../../domain/entities/character.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/repositories/ai_chat_repository.dart';

class ChatViewModel extends ChangeNotifier {
  final Character character;
  final ChatRepository chatRepository;
  final AiChatRepository aiChatRepository;
  final TextEditingController messageController = TextEditingController();

  List<ChatMessage> _messages = [];
  bool _isGenerating = false;

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

  Future<void> _loadMessages() async {
    try {
      _messages = await chatRepository.getMessages(character.id);
      if (_messages.isEmpty) {
        final welcomeMessage = ChatMessage.welcomeFor(character);
        _messages.add(welcomeMessage);
        await chatRepository.saveMessage(character.id, welcomeMessage);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load messages: $e');
    }
  }

  Future<void> sendMessage() async {
    final userMessage = messageController.text.trim();
    if (userMessage.isEmpty || _isGenerating) return;

    final userChatMessage = ChatMessage(
      content: userMessage,
      role: 'user',
      timestamp: DateTime.now(),
    );

    messageController.clear();
    _messages.add(userChatMessage);
    await chatRepository.saveMessage(character.id, userChatMessage);
    notifyListeners();

    _isGenerating = true;
    notifyListeners();

    try {
      final aiMessage = await aiChatRepository.generateResponse(userMessage);
      _messages.add(aiMessage);
      await chatRepository.saveMessage(character.id, aiMessage);
    } catch (e) {
      _messages.add(ChatMessage(
        content: '죄송합니다. 오류가 발생했습니다. 다시 시도해주세요.',
        role: 'assistant',
        timestamp: DateTime.now(),
      ));
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<void> resetChat() async {
    try {
      await chatRepository.clearMessages(character.id);
      _messages.clear();
      messageController.clear();
      _isGenerating = false;

      final welcomeMessage = ChatMessage.welcomeFor(character);
      _messages.add(welcomeMessage);
      await chatRepository.saveMessage(character.id, welcomeMessage);
      aiChatRepository.resetChat();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to reset chat: $e');
    }
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }
}
