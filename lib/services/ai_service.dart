import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/character.dart';
import '../data/characters.dart';

class AIService {
  final String apiKey;
  GenerativeModel? _model;
  ChatSession? _chatSession;
  String _currentCharacterId = '';
  bool _isInitialized = false;
  
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
    if (_isInitialized) return;
    
    if (apiKey.isEmpty) {
      throw Exception('Gemini API key not found in .env file');
    }
    
    _isInitialized = true;
  }
  
  void initializeForCharacter(Character character) {
    if (_currentCharacterId == character.id) return;
    
    _currentCharacterId = character.id;
    
    final initialPrompt = '''
    당신은 가상의 캐릭터 ${character.name}입니다.
    
    캐릭터 설명:
    - 성격: ${character.personality}
    - 특징: ${character.description}
    
    몇 가지 중요한 규칙이 있습니다:
    1. 항상 간결하게 대답합니다. 1-3문장 정도로 짧게 대화하세요.
    2. 친근하고 대화체로 얘기합니다.
    3. 너무 길게 설명하지 말고 핵심만 전달합니다.
    4. 항상 캐릭터의 성격과 말투를 유지하세요.
    5. 너무 형식적이거나 정보를 나열하듯 말하지 마세요.
    
    당신은 항상 ${character.name}의 입장에서 대답합니다. 사용자와 채팅할 준비가 되었습니다.
    ''';
    
    // 채팅 세션 초기화
    resetChat(initialPrompt);
  }
  
  void resetChat([String? customPrompt]) {
    if (_model == null) return;
    
    final character = characters.firstWhere(
      (c) => c.id == _currentCharacterId,
      orElse: () => characters[0],
    );
    
    final initialPrompt = customPrompt ?? '''
    당신은 가상의 캐릭터 ${character.name}입니다.
    
    캐릭터 설명:
    - 성격: ${character.personality}
    - 특징: ${character.description}
    
    몇 가지 중요한 규칙이 있습니다:
    1. 항상 간결하게 대답합니다. 1-3문장 정도로 짧게 대화하세요.
    2. 친근하고 대화체로 얘기합니다.
    3. 너무 길게 설명하지 말고 핵심만 전달합니다.
    4. 항상 캐릭터의 성격과 말투를 유지하세요.
    5. 너무 형식적이거나 정보를 나열하듯 말하지 마세요.
    
    당신은 항상 ${character.name}의 입장에서 대답합니다. 사용자와 채팅할 준비가 되었습니다.
    ''';
    
    _chatSession = _model?.startChat(history: [
      Content.text(initialPrompt),
    ]);
  }
  
  Future<String?> sendMessage(String message) async {
    if (_chatSession == null || _model == null) {
      return '죄송합니다. AI 서비스가 초기화되지 않았습니다.';
    }
    
    try {
      final response = await _chatSession!.sendMessage(
        Content.text(message),
      );
      
      final responseText = response.text;
      return responseText;
    } catch (e) {
      debugPrint('AI 응답 생성 중 오류: $e');
      return '죄송합니다. 응답을 생성하는 중 오류가 발생했습니다.';
    }
  }
}