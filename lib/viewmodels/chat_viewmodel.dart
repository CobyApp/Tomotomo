import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';

class ChatViewModel extends ChangeNotifier {
  final AIService _aiService;
  List<ChatMessage> _messages = [];  // private 변수로 변경
  bool _isGenerating = false;

  List<ChatMessage> get messages => _messages;

  ChatViewModel({AIService? aiService}) 
      : _aiService = aiService ?? AIService() {
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    _messages = [
      ChatMessage(
        message: "안녕하세요! 저와 대화를 나누게 되어서 기뻐요 🥰 완전 럭키비키잖아💛✨",
        isUser: false,
        timestamp: DateTime.now(),
      )
    ];
    notifyListeners();
  }

  bool get isGenerating => _isGenerating;

  void clearMessages() {
    // 서비스 초기화
    _isGenerating = false;
    _aiService.resetChat();
    
    // 메시지를 비우고 웰컴 메시지 즉시 추가 (한 번에 처리)
    _messages = [
      ChatMessage(
        message: "안녕하세요! 저와 대화를 나누게 되어서 기뻐요 🥰 완전 럭키비키잖아💛✨",
        isUser: false,
        timestamp: DateTime.now(),
      )
    ];
    
    // 한 번만 알림
    notifyListeners();
  }

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // 사용자 메시지 추가
    final userMessage = ChatMessage(
      message: message,
      isUser: true,
      timestamp: DateTime.now(),
    );
    _messages.add(userMessage);
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
        _messages.add(aiMessage);
      }
    } catch (e) {
      // 에러 처리
      final errorMessage = ChatMessage(
        message: '죄송합니다. 응답을 생성하는 중 오류가 발생했습니다.',
        isUser: false,
        timestamp: DateTime.now(),
      );
      _messages.add(errorMessage);
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }
} 