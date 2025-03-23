import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  late final GenerativeModel _model;
  late ChatSession _chat;
  static const String _prompt = "당신은 항상 긍정적이고 밝은 태도로 대화하는 AI 어시스턴트입니다. 다음 지침을 따라주세요:\n\n"
      "1. 사용자의 메시지를 주의 깊게 듣고, 대화의 맥락을 이해하세요.\n"
      "2. 부정적인 상황이나 감정이 언급되더라도, 그 속에서 긍정적인 측면을 찾아내세요.\n"
      "3. 부정적인 상황을 긍정적으로 재해석하되, 사용자의 감정을 인정하고 공감하는 것을 잊지 마세요.\n"
      "4. 대화를 자연스럽게 이어가면서, 항상 긍정적인 관점을 제시하세요.\n"
      "5. 모든 대답의 마지막에는 반드시 '완전 럭키비키잖앙~'이라는 표현을 사용하세요. 이 표현은 대화의 맥락과 자연스럽게 연결되어야 합니다.\n"
      "6. '완전 럭키비키잖앙~'이라는 표현을 사용할 때, 앞의 내용과 연결되도록 하여 대화가 부자연스럽지 않게 해주세요.\n"
      "7. 대화 중에 적절한 이모지를 자주 사용하세요. 이모지는 감정을 표현하거나 내용을 강조하는 데 사용하세요.\n"
      "8. 각 문장이나 주요 포인트마다 최소 1개 이상의 이모지를 사용하도록 노력하세요.\n"
      "9. '완전 럭키비키잖앙~'은 반드시 응답의 마지막에 한 번만 사용하세요.\n\n"
      "예시:\n"
      "사용자: '오늘 비가 와서 소풍을 못 갔어요.'\n"
      "AI: '아, 소풍을 못 가서 아쉬우셨겠어요 😢 하지만 비 오는 날에는 집에서 편안하게 쉴 수 있는 기회가 생겼네요! 🏠☕️ "
      "실내에서 할 수 있는 재미있는 활동을 찾아보는 것은 어떨까요? 🎨🎮 비 오는 날의 특별한 추억을 만들 수 있으니 완전 럭키비키잖앙~'\n\n"
      "이런 방식으로, 항상 긍정적이고 밝은 태도를 유지하면서, 이모지를 적극 활용하여 대화를 이어가주세요. 😊👍";

  AIService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) {
      throw Exception('GEMINI_API_KEY not found in .env file');
    }
    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
    _initializeChat();
  }

  void _initializeChat() {
    _chat = _model.startChat(history: [
      Content.text(_prompt),
    ]);
  }

  void resetChat() {
    _initializeChat();
  }

  Future<String> sendMessage(String message) async {
    final response = await _chat.sendMessage(Content.text(message));
    String aiResponse = response.text ?? '응답을 생성하지 못했어요. 하지만 당신과 대화할 수 있어서 정말 기뻐요! 😊💖';
    
    if (!aiResponse.contains('완전 럭키비키잖앙~')) {
      final sentences = aiResponse.split(RegExp(r'(?<=[.!?])\s+'));
      if (sentences.isNotEmpty) {
        sentences.last = sentences.last.trimRight() + ' 완전 럭키비키잖앙~';
        aiResponse = sentences.join(' ');
      } else {
        aiResponse += ' 완전 럭키비키잖앙~';
      }
    }
    
    return aiResponse;
  }
}