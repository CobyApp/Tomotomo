import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/character.dart';

class AIService {
  final String apiKey;
  GenerativeModel? _model;
  ChatSession? _chatSession;
  Character? _currentCharacter;
  
  AIService({required String sessionId}) : apiKey = dotenv.env['GEMINI_API_KEY'] ?? '' {
    if (apiKey.isEmpty) {
      debugPrint('경고: GEMINI_API_KEY가 설정되지 않았습니다.');
    } else {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
      );
    }
  }

  void _initializeForCharacter(Character character) {
    if (_currentCharacter?.id == character.id) return;
    
    _currentCharacter = character;
    if (_model == null) return;

    final prompt = '''
당신은 일본어 학습 AI 튜터입니다. 다음 캐릭터 설정을 따라주세요:

캐릭터: ${character.nameJp} (${character.nameKanji})
레벨: ${character.level}
성격: ${character.traits.map((t) => t.trait).join(', ')}
말투: ${character.speechStyle}
자기 호칭: ${character.selfReference}

다음 규칙을 엄격히 지켜주세요:
1. 모든 응답은 반드시 일본어로만 해주세요.
2. 영어 사용을 절대 금지합니다.
3. 문법 설명이나 의미 설명이 필요한 경우에만 한국어로 설명해주세요.
4. ${character.level} 레벨에 맞는 간단한 문법과 일반적인 표현을 사용해주세요.
5. 응답은 간결하고 언어 학습에 도움이 되도록 해주세요.
6. 틀린 표현이 있을 경우:
   - 먼저 올바른 표현을 알려주세요
   - 그 다음 한국어로 자세한 설명을 해주세요
   - 필요한 경우 비슷한 예문도 추가해주세요
7. 새로운 대화가 시작될 때는 반드시 새로운 풍선으로 시작해주세요
8. 대화의 맥락을 유지하면서도 각각의 응답을 독립적으로 작성해주세요
9. 한국어로 메시지가 들어올 경우:
   - 해당 한국어를 ${character.level} 레벨에 맞는 자연스러운 일본어로 번역해주세요
   - 번역된 일본어를 먼저 보여주고
   - 그 다음 한국어로 문법이나 사용법을 설명해주세요
   - 비슷한 상황에서 사용할 수 있는 예문도 추가해주세요
10. 한국어 메시지에 대한 응답도 일본어로 시작하고, 필요한 설명만 한국어로 해주세요
11. 응답 형식:
    - 일본어 응답은 **굵은 글씨**로 표시
    - 문법 설명이나 예문은 > 인용구로 표시
    - 복사하기 쉽도록 각 부분을 명확히 구분
    - 예시:
      **こんにちは。**
      > 인사말입니다. 'こんにちは'는 '안녕하세요'라는 의미입니다.
      > 비슷한 표현:
      > - おはようございます (좋은 아침입니다)
      > - こんばんは (안녕하세요 - 저녁)
''';

    _chatSession = _model?.startChat(history: [
      Content.text(prompt),
    ]);
  }

  Future<String> sendMessage(String message, Character character) async {
    try {
      // 캐릭터가 변경되었다면 새로운 세션 초기화
      if (_currentCharacter?.id != character.id) {
        _initializeForCharacter(character);
      }

      if (_chatSession == null || _model == null) {
        debugPrint('AI 서비스가 초기화되지 않았습니다.');
        return '申し訳ございません。エラーが発生しました。';
      }
      
      debugPrint('Sending message to Gemini API...');
      final response = await _chatSession!.sendMessage(
        Content.text(message),
      );
      
      debugPrint('Response received from API');
      final responseText = response.text;
      
      if (responseText != null) {
        return responseText;
      } else {
        debugPrint('Empty response from API');
        return '申し訳ございません。エラーが発生しました。';
      }
    } catch (e) {
      debugPrint('Gemini API Error: $e');
      return '申し訳ございません。エラーが発生しました。もう一度お試しください。';
    }
  }

  void resetChat() {
    if (_currentCharacter == null || _model == null) return;
    
    // 현재 캐릭터 정보 저장
    final currentCharacter = _currentCharacter!;
    
    // 세션 초기화
    _chatSession = null;
    _currentCharacter = null;
    
    // 새로운 세션 시작
    _initializeForCharacter(currentCharacter);
  }
}