import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';
import '../models/character.dart';
import '../data/characters.dart';

class ChatViewModel extends ChangeNotifier {
  final Character character;
  final AIService aiService;
  final List<ChatMessage> messages = [];
  bool isGenerating = false;

  ChatViewModel({
    required this.character,
    required this.aiService,
  });

  void sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    messages.add(ChatMessage(
      message: message,
      isUser: true,
      timestamp: DateTime.now(),
    ));
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));

    isGenerating = true;
    notifyListeners();

    try {
      final response = await aiService.sendMessage(message, character);
      messages.add(ChatMessage(
        message: response,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      print('AI 응답 생성 중 오류: $e');
    } finally {
      isGenerating = false;
      notifyListeners();
    }
  }

  void resetChat() {
    messages.clear();
    notifyListeners();
  }
} 