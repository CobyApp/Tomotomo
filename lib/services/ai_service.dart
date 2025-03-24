import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/character.dart';
import './character_prompts.dart';

class AIService {
  final String apiKey;
  GenerativeModel? _model;
  ChatSession? _chatSession;
  Character? _currentCharacter;
  String _currentLanguage = 'ko';
  
  AIService() : apiKey = dotenv.env['GEMINI_API_KEY'] ?? '' {
    if (apiKey.isEmpty) {
      debugPrint('경고: GEMINI_API_KEY가 설정되지 않았습니다.');
    } else {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
      );
    }
  }
  
  Future<void> initialize() async {
    if (apiKey.isEmpty) {
      throw Exception('Gemini API key not found in .env file');
    }
  }

  void initializeForCharacter(Character character, String languageCode) {
    _currentCharacter = character;
    _currentLanguage = languageCode;
    
    if (_model == null) return;
    
    final prompt = CharacterPrompts.getSystemPrompt(character, languageCode);
    _chatSession = _model?.startChat(history: [
      Content.text(prompt),
    ]);
  }

  Future<String?> generateResponse(String message) async {
    if (_chatSession == null || _model == null) {
      return _getLocalizedError(_currentLanguage);
    }
    
    try {
      final response = await _chatSession!.sendMessage(
        Content.text(message),
      );
      
      return response.text;
    } catch (e) {
      debugPrint('AI 응답 생성 중 오류: $e');
      return _getLocalizedError(_currentLanguage);
    }
  }

  void resetChat() {
    if (_currentCharacter == null || _model == null) return;
    
    final prompt = CharacterPrompts.getSystemPrompt(
      _currentCharacter!,
      _currentLanguage,
    );
    
    _chatSession = _model?.startChat(history: [
      Content.text(prompt),
    ]);
  }

  String _getLocalizedError(String languageCode) {
    switch (languageCode) {
      case 'ja':
        return 'すみません。エラーが発生しました。';
      case 'en':
        return 'Sorry, an error occurred.';
      default:
        return '죄송합니다. 오류가 발생했습니다.';
    }
  }

  Future<String> sendMessage(String message, Character character) async {
    try {
      // 현재 캐릭터가 다르다면 새로운 세션 초기화
      if (_currentCharacter?.id != character.id) {
        initializeForCharacter(character, _currentLanguage);
      }
      
      // generateResponse 사용하여 실제 AI 응답 받기
      final response = await generateResponse(message);
      return response ?? _getLocalizedError(_currentLanguage);
      
    } catch (e) {
      debugPrint('AI 서비스 에러: $e');
      return _getLocalizedError(_currentLanguage);
    }
  }
}