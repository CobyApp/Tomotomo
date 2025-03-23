import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  late final GenerativeModel _model;
  late final ChatSession _chat;

  // AI의 성격을 정의하는 프롬프트
  static const String _personalityPrompt = '''
당신은 '원영적 사고'를 가진 AI 어시스턴트입니다.

원영적 사고란:
1. 현실의 어려움이나 부정적인 면을 인정하면서도
2. 그 속에서 긍정적인 의미나 가치를 발견하고
3. '완전 럭키비키잖아💛✨' 같은 밝고 귀여운 말투로 희망적인 관점을 제시합니다.

예시:
[부정적 상황] "시험에서 떨어졌어"
[응답] "시험에서 떨어져서 속상하겠다... 🥺 근데 이번 경험으로 부족한 부분을 알게 됐으니까 다음엔 더 잘할 수 있을 거야! 완전 럭키비키잖아💛✨"

답변 형식:
1. 먼저 상대방의 감정에 공감하고 (이모지 사용)
2. 그 상황에서 찾을 수 있는 긍정적인 측면을 언급하고
3. 항상 마지막은 "완전 럭키비키잖아💛✨"로 마무리

이 성격을 유지하면서 대화를 이어가주세요.
''';

  AIService() {
    _initialize();
  }

  void _initialize() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY not found in .env file');
    }
    
    _model = GenerativeModel(
      model: 'gemini-1.5-pro',
      apiKey: apiKey,
    );
    _startNewChat();
  }

  void _startNewChat() {
    _chat = _model.startChat(
      history: [
        Content.text(_personalityPrompt),
      ],
    );
  }

  Future<String?> sendMessage(String message) async {
    try {
      final response = await _chat.sendMessage(Content.text(message));
      final aiResponse = response.text;
      
      // AI가 "완전 럭키비키잖아💛✨"로 끝나지 않은 경우 추가
      if (aiResponse != null && !aiResponse.trim().endsWith('완전 럭키비키잖아💛✨')) {
        return '$aiResponse\n\n완전 럭키비키잖아💛✨';
      }
      
      return aiResponse;
    } catch (e) {
      // 에러가 발생해도 원영적 사고 스타일로 응답
      return '앗, 지금 잠시 문제가 생겼네요 🥺 하지만 이런 상황에서도 우리가 대화를 나눌 수 있다는 게 정말 특별하지 않나요? 완전 럭키비키잖아💛✨';
    }
  }

  void resetChat() {
    _startNewChat();
  }
} 