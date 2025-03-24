import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';
import '../models/character.dart';
import '../data/characters.dart';
import '../services/chat_storage_service.dart';

class ChatViewModel extends ChangeNotifier {
  final Character character;
  final AIService aiService;
  final ChatStorageService chatStorage;
  List<ChatMessage> messages = [];
  bool isGenerating = false;

  ChatViewModel({
    required this.character,
    required this.aiService,
    required this.chatStorage,
  }) {
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    messages = await chatStorage.getMessages(character.id);
    notifyListeners();
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      characterId: character.id,
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
    );
    
    messages.add(userMessage);
    await chatStorage.saveMessage(userMessage);
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));
    isGenerating = true;
    notifyListeners();

    try {
      final response = await aiService.sendMessage(content, character);
      
      final aiMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        characterId: character.id,
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
      );
      
      messages.add(aiMessage);
      await chatStorage.saveMessage(aiMessage);
      
    } finally {
      isGenerating = false;
      notifyListeners();
    }
  }

  Future<void> resetChat() async {
    await chatStorage.clearMessages(character.id);
    messages.clear();
    aiService.resetChat();
    notifyListeners();
  }
} 