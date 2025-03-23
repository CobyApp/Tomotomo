import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';

class ChatViewModel extends ChangeNotifier {
  final AIService _aiService;
  List<ChatMessage> messages = [];
  bool _isGenerating = false;

  ChatViewModel({AIService? aiService}) 
      : _aiService = aiService ?? AIService();

  bool get isGenerating => _isGenerating;

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // 사용자 메시지 추가
    final userMessage = ChatMessage(
      message: message,
      isUser: true,
      timestamp: DateTime.now(),
    );
    messages.add(userMessage);
    notifyListeners();

    try {
      _isGenerating = true;
      notifyListeners();

      // AI 응답 생성
      final aiResponse = await _aiService.sendMessage(message);

      if (aiResponse != null) {
        // AI 메시지 추가
        final aiMessage = ChatMessage(
          message: aiResponse,
          isUser: false,
          timestamp: DateTime.now(),
        );
        messages.add(aiMessage);
      }
    } catch (e) {
      // 에러 처리
      final errorMessage = ChatMessage(
        message: '죄송합니다. 응답을 생성하는 중 오류가 발생했습니다.',
        isUser: false,
        timestamp: DateTime.now(),
      );
      messages.add(errorMessage);
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    messages.clear();
    _aiService.resetChat();
    notifyListeners();
  }
} 