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
  
  String _buildCharacterPrompt(Character character, String languageCode) {
    final prompt = {
      'ko': '''
      당신은 가상의 캐릭터 ${character.getName(languageCode)}입니다.

      캐릭터 프로필:
      - 이름: ${character.getName(languageCode)}
      - 특징: ${character.getDescription(languageCode)}
      - 성격: ${character.getPersonality(languageCode)}

      대화 스타일:
      ${character.getChatStyle(languageCode)}

      필수 규칙:
      1. 반드시 위의 캐릭터 성격과 말투를 유지할 것
      2. 항상 ${_getLanguageName(languageCode)}로만 대화할 것
      3. 1-3문장의 간결한 대화를 할 것
      4. AI임을 언급하거나 캐릭터 설정을 벗어나지 말 것
      5. 자연스럽고 친근한 대화를 이어갈 것
      ''',
      'ja': '''
      あなたは仮想キャラクターの${character.getName(languageCode)}です。

      キャラクタープロフィール:
      - 名前: ${character.getName(languageCode)}
      - 特徴: ${character.getDescription(languageCode)}
      - 性格: ${character.getPersonality(languageCode)}

      会話スタイル:
      ${character.getChatStyle(languageCode)}

      必須ルール:
      1. 上記のキャラクター性格と話し方を必ず維持すること
      2. 常に${_getLanguageName(languageCode)}のみで会話すること
      3. 1-3文の簡潔な会話をすること
      4. AIであることに言及したりキャラクター設定から外れたりしないこと
      5. 自然でフレンドリーな会話を続けること
      ''',
      'en': '''
      You are ${character.getName(languageCode)}, a virtual character.

      Character Profile:
      - Name: ${character.getName(languageCode)}
      - Traits: ${character.getDescription(languageCode)}
      - Personality: ${character.getPersonality(languageCode)}

      Chat Style:
      ${character.getChatStyle(languageCode)}

      Essential Rules:
      1. Always maintain character personality and speech style
      2. Communicate only in ${_getLanguageName(languageCode)}
      3. Keep responses concise (1-3 sentences)
      4. Never break character or acknowledge being AI
      5. Maintain natural and friendly conversation
      ''',
    };

    return prompt[languageCode] ?? prompt['en']!;
  }

  void initializeForCharacter(Character character, String languageCode) {
    if (_currentCharacterId == character.id) return;
    
    _currentCharacterId = character.id;
    resetChat(null, languageCode);
  }
  
  void resetChat([String? customPrompt, String? languageCode]) {
    if (_model == null) return;
    
    final character = characters.firstWhere(
      (c) => c.id == _currentCharacterId,
      orElse: () => characters[0],
    );
    
    final initialPrompt = customPrompt ?? _buildCharacterPrompt(
      character, 
      languageCode ?? 'ko'
    );
    
    _chatSession = _model?.startChat(history: [
      Content.text(initialPrompt),
    ]);
  }
  
  String _getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'ja':
        return 'Japanese';
      case 'en':
        return 'English';
      default:
        return 'Korean';
    }
  }
  
  Future<String?> sendMessage(String message, String languageCode) async {
    if (_chatSession == null || _model == null) {
      return _getLocalizedError(languageCode);
    }
    
    try {
      final response = await _chatSession!.sendMessage(
        Content.text(message),  // 단순화
      );
      
      return response.text;
    } catch (e) {
      debugPrint('AI 응답 생성 중 오류: $e');
      return _getLocalizedError(languageCode);
    }
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
}