import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';
import '../models/character.dart';
import '../data/characters.dart';

class ChatViewModel extends ChangeNotifier {
  final AIService _aiService;
  Map<String, List<ChatMessage>> _characterMessages = {};
  bool _isGenerating = false;
  
  Character _currentCharacter;
  String _currentLanguage = 'ko';  // 현재 언어 추가
  
  Character get character => _currentCharacter;
  bool get isGenerating => _isGenerating;
  List<ChatMessage> get messages => _characterMessages[_currentCharacter.id] ?? [];

  ChatViewModel({
    Character? initialCharacter,
    required AIService aiService,
  }) : _aiService = aiService, _currentCharacter = initialCharacter ?? characters[0];

  void setCurrentCharacter(Character character, String languageCode) {
    _currentCharacter = character;
    _currentLanguage = languageCode;  // 언어 코드 저장
    _aiService.initializeForCharacter(character, languageCode);
    
    if (!_characterMessages.containsKey(character.id)) {
      _characterMessages[character.id] = [
        ChatMessage(
          message: character.getFirstMessage(languageCode),
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

  void changeCharacter(Character newCharacter) {
    _currentCharacter = newCharacter;
    notifyListeners();
  }

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    final userMessage = ChatMessage(
      message: message,
      isUser: true,
      timestamp: DateTime.now(),
    );

    _characterMessages[_currentCharacter.id]?.add(userMessage);
    notifyListeners();

    _isGenerating = true;
    notifyListeners();

    try {
      final response = await _aiService.generateResponse(message);
      if (response != null) {
        final aiMessage = ChatMessage(
          message: response,
          isUser: false,
          timestamp: DateTime.now(),
        );
        _characterMessages[_currentCharacter.id]?.add(aiMessage);
      }
    } catch (e) {
      print('AI 응답 생성 중 오류: $e');
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _isGenerating = false;
    _aiService.resetChat();  // 파라미터 제거
    
    _characterMessages[_currentCharacter.id] = [
      ChatMessage(
        message: _currentCharacter.getFirstMessage(_currentLanguage),
        isUser: false,
        timestamp: DateTime.now(),
      )
    ];
    
    notifyListeners();
  }
} 