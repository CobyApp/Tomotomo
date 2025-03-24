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
  String _currentLanguage = 'ko';  // 현재 언어 추가
  
  Character get currentMember => _currentMember;
  bool get isGenerating => _isGenerating;
  List<ChatMessage> get messages => _memberMessages[_currentMember.id] ?? [];

  ChatViewModel({required AIService aiService}) : _aiService = aiService;

  void setCurrentMember(Character character, String languageCode) {
    _currentMember = character;
    _currentLanguage = languageCode;  // 언어 코드 저장
    _aiService.initializeForCharacter(character, languageCode);
    
    if (!_memberMessages.containsKey(character.id)) {
      _memberMessages[character.id] = [
        ChatMessage(
          message: _getLocalizedFirstMessage(character, languageCode),
          isUser: false,
          timestamp: DateTime.now(),
        )
      ];
    }
    notifyListeners();
  }

  String _getLocalizedFirstMessage(Character character, String languageCode) {
    return character.getFirstMessage(languageCode);
  }

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    final userMessage = ChatMessage(
      message: message,
      isUser: true,
      timestamp: DateTime.now(),
    );

    _memberMessages[_currentMember.id]?.add(userMessage);
    notifyListeners();

    _isGenerating = true;
    notifyListeners();

    try {
      final response = await _aiService.sendMessage(message, _currentLanguage);  // 언어 코드 전달
      if (response != null) {
        final aiMessage = ChatMessage(
          message: response,
          isUser: false,
          timestamp: DateTime.now(),
        );
        _memberMessages[_currentMember.id]?.add(aiMessage);
      }
    } catch (e) {
      // 에러 처리
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _isGenerating = false;
    _aiService.resetChat(_currentLanguage);  // 언어 코드 전달
    
    _memberMessages[_currentMember.id] = [
      ChatMessage(
        message: _getLocalizedFirstMessage(_currentMember, _currentLanguage),
        isUser: false,
        timestamp: DateTime.now(),
      )
    ];
    
    notifyListeners();
  }
} 