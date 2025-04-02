import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';
import '../models/character.dart';
import '../services/chat_storage_service.dart';
import 'package:flutter/material.dart';

class ChatViewModel extends ChangeNotifier {
  final Character character;
  final ChatStorageService chatStorage;
  final AIService aiService;
  final TextEditingController messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool isGenerating = false;

  ChatViewModel({
    required this.character,
    required this.chatStorage,
    required this.aiService,
  }) {
    _loadMessages();
  }

  List<ChatMessage> get messages => List.unmodifiable(_messages);

  Future<void> _loadMessages() async {
    final savedMessages = await chatStorage.getMessages(character.id);
    _messages.addAll(savedMessages);
    notifyListeners();
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      characterId: character.id,
      content: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    _messages.add(userMessage);
    messageController.clear();
    notifyListeners();

    await chatStorage.saveMessage(userMessage);

    isGenerating = true;
    notifyListeners();

    try {
      final response = await aiService.sendMessage(text, character);
      
      final aiMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        characterId: character.id,
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
      );

      _messages.add(aiMessage);
      await chatStorage.saveMessage(aiMessage);
    } catch (e) {
      print('Error generating response: $e');
      // TODO: 에러 처리
    } finally {
      isGenerating = false;
      notifyListeners();
    }
  }

  Future<void> resetChat() async {
    try {
      await chatStorage.clearMessages(character.id);
      _messages.clear();
      messageController.clear();
      isGenerating = false;
      
      // 초기 인사 메시지 추가
      final welcomeMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        characterId: character.id,
        content: '${character.nameJp}と日本語で話しましょう！',
        isUser: false,
        timestamp: DateTime.now(),
      );
      
      _messages.add(welcomeMessage);
      await chatStorage.saveMessage(welcomeMessage);
      notifyListeners();
    } catch (e) {
      print('Error resetting chat: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }
} 