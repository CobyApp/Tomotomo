import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../data/members_data.dart';

class AIService {
  late final GenerativeModel _model;
  late ChatSession _chat;
  String _memberId = '';

  AIService();

  void initializeForMember(String memberId) {
    _memberId = memberId;
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) {
      throw Exception('GEMINI_API_KEY not found in .env file');
    }
    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
    
    // 멤버 성격 프롬프트 가져오기
    final member = MembersData.getMemberById(memberId);
    _resetChat(member.personalityPrompt);
  }

  void _resetChat(String prompt) {
    _chat = _model.startChat(history: [
      Content.text(prompt),
    ]);
  }

  void resetChat() {
    if (_memberId.isEmpty) return;
    final member = MembersData.getMemberById(_memberId);
    _resetChat(member.personalityPrompt);
  }

  Future<String> sendMessage(String message) async {
    final response = await _chat.sendMessage(Content.text(message));
    return response.text ?? '응답을 생성하지 못했어요.';
  }
}