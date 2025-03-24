import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';
import '../models/character.dart';
import '../data/characters.dart';

class ChatViewModel extends ChangeNotifier {
  final AIService _aiService;
  Map<String, List<ChatMessage>> _memberMessages = {};
  bool _isGenerating = false;
  
  Character _currentMember = characters[0];
  
  List<ChatMessage> get messages => _memberMessages[_currentMember.id] ?? [];
  bool get isGenerating => _isGenerating;
  Character get currentMember => _currentMember;

  ChatViewModel({required AIService aiService}) : _aiService = aiService {
    // 초기화 시 첫 메시지 설정
    _memberMessages[_currentMember.id] = [
      ChatMessage(
        message: _currentMember.firstMessage,
        isUser: false,
        timestamp: DateTime.now(),
      )
    ];
  }

  void clearMessages() {
    _isGenerating = false;
    _aiService.resetChat();
    
    _memberMessages[_currentMember.id] = [
      ChatMessage(
        message: "채팅이 초기화되었어요! ${_currentMember.name}입니다. 다시 대화해요~",
        isUser: false,
        timestamp: DateTime.now(),
      )
    ];
    
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
    
    if (!_memberMessages.containsKey(_currentMember.id)) {
      _memberMessages[_currentMember.id] = [];
    }
    
    _memberMessages[_currentMember.id]!.add(userMessage);
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
        _memberMessages[_currentMember.id]!.add(aiMessage);
      }
    } catch (e) {
      // 에러 처리
      final errorMessage = ChatMessage(
        message: '죄송합니다. 응답을 생성하는 중 오류가 발생했습니다.',
        isUser: false,
        timestamp: DateTime.now(),
      );
      _memberMessages[_currentMember.id]!.add(errorMessage);
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  void setCurrentMember(Character character) {
    _currentMember = character;
    _aiService.initializeForCharacter(character);
    if (!_memberMessages.containsKey(character.id)) {
      _memberMessages[character.id] = [
        ChatMessage(
          message: character.firstMessage,
          isUser: false,
          timestamp: DateTime.now(),
        )
      ];
    }
    notifyListeners();
  }
} 