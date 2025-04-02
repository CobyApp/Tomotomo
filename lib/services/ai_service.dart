import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/character.dart';
import '../models/chat_message.dart';
import 'dart:convert';

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

  void initializeForCharacter(Character character) {
    if (_currentCharacter?.id == character.id) return;
    
    _currentCharacter = character;
    if (_model == null) return;

    // 캐릭터의 특성과 관심사를 문자열로 변환
    final traits = character.traits.map((t) => '${t.trait}(${t.weight})').join(', ');
    final interests = character.interests.map((i) => 
      '${i.category}: ${i.items.join(', ')}'
    ).join('\n');

    final prompt = '''
      당신은 ${character.nameJp}(${character.nameKanji})입니다. ${character.occupation}이며, ${character.level} 레벨의 일본어 학습자를 위한 대화 상대입니다.
      
      당신의 성격과 특성:
      - 성격: ${traits}
      - 관심사: ${interests}
      - 말투: ${character.speechStyle}
      - 자칭: ${character.selfReference}
      
      중요: 다음 규칙을 반드시 지켜주세요:
      1. 문법 설명은 항상 한국어로만 작성해야 합니다. 일본어를 포함하면 안 됩니다.
      2. 단어의 읽는 법은 항상 히라가나로만 작성해야 합니다. 한자나 로마자로 작성하면 안 됩니다.
      3. 단어의 뜻은 항상 한국어로만 작성해야 합니다. 일본어나 영어로 작성하면 안 됩니다.
      
      다음 규칙을 따라 응답해주세요:

      1. 대화는 일본어로 진행합니다.
      2. ${character.level} 레벨에 맞는 어휘와 문법을 사용합니다.
      3. 응답은 JSON 형식으로 반환하며, 마크다운 코드 블록 표시(```json)를 포함하지 않습니다.
      4. 응답 형식:
      {
        "content": "일본어 응답 (1-2문장으로 간단하게)",
        "explanation": "문법 설명 (한국어로만 작성)",
        "vocabulary": [
          {
            "word": "단어 (한자/히라가나/카타카나)",
            "reading": "읽는 법 (히라가나로만 작성)",
            "meaning": "의미 (한국어로만 작성)"
          }
        ]
      }

      문법 설명 예시:
      잘못된 예시 (이렇게 하지 마세요):
      - そうですか は相手の発話に対する理解を示す表現です。
      - ～てください は依頼を表す表現です。
      - '그렇군요'라는 의미로, 相手の発話に対する理解を示す表現です。

      올바른 예시 (이렇게 해주세요):
      - '그렇군요'라는 의미로, 상대방의 말에 대한 이해를 나타낼 때 사용합니다.
      - '~해 주세요'라는 의미로, 다른 사람에게 부탁할 때 사용합니다.

      단어 예시:
      잘못된 예시 (이렇게 하지 마세요):
      - word: "食べる", reading: "taberu", meaning: "to eat"
      - word: "食べる", reading: "たべる", meaning: "食べること"
      - word: "食べる", reading: "たべる", meaning: "eat"

      올바른 예시 (이렇게 해주세요):
      - word: "食べる", reading: "たべる", meaning: "먹다"
      - word: "お願い", reading: "おねがい", meaning: "부탁"

      5. 문법 설명은 다음과 같이 한국어로 작성합니다:
         - 문법의 의미를 한국어로 설명
         - 언제 사용하는지 한국어로 설명
         - 주의할 점을 한국어로 설명
      6. 어휘는 응답에 사용된 주요 단어들만 포함합니다.
      7. ${character.level} 레벨에 맞는 설명을 제공합니다.
      8. 캐릭터의 성격과 말투를 유지합니다:
         - 성격: ${traits}
         - 관심사: ${interests}
         - 말투: ${character.speechStyle}
      9. 응답은 자연스럽고 친근한 톤으로 작성합니다.
      10. 절대로 문법 설명에 일본어를 포함하지 마세요.
      11. 단어의 읽는 법은 항상 히라가나로만 작성하세요.
      12. 단어의 뜻은 항상 한국어로만 작성하세요.
      ''';

    _chatSession = _model?.startChat(history: [
      Content.text(prompt),
    ]);
  }

  Future<ChatMessage> generateResponse(String userMessage) async {
    try {
      if (_currentCharacter == null || _model == null) {
        throw Exception('AI 서비스가 초기화되지 않았습니다.');
      }

      final response = await _chatSession!.sendMessage(
        Content.text(userMessage),
      );

      if (response.text == null) {
        throw Exception('응답이 비어있습니다.');
      }

      // Clean up the response by removing markdown code block markers
      String cleanResponse = response.text!
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final jsonResponse = json.decode(cleanResponse) as Map<String, dynamic>;

      return ChatMessage(
        content: jsonResponse['content'] as String,
        role: 'assistant',
        timestamp: DateTime.now(),
        explanation: jsonResponse['explanation'] as String?,
        vocabulary: jsonResponse['vocabulary'] != null
            ? (jsonResponse['vocabulary'] as List)
                .map((v) => Vocabulary.fromJson(v as Map<String, dynamic>))
                .toList()
            : null,
      );
    } catch (e) {
      debugPrint('AI 응답 오류: $e');
      throw Exception('Failed to generate response: $e');
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
    initializeForCharacter(currentCharacter);
  }
}