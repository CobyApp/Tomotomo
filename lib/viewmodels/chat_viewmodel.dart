import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';
import '../data/members_data.dart';
import '../models/member.dart';

class ChatViewModel extends ChangeNotifier {
  final AIService _aiService;
  Map<String, List<ChatMessage>> _memberMessages = {}; // 멤버별 메시지 저장
  bool _isGenerating = false;
  
  Member _currentMember = MembersData.members[0];
  String _currentMemberId = '';
  
  List<ChatMessage> get messages => _memberMessages[_currentMemberId] ?? [];
  bool get isGenerating => _isGenerating;
  Member get currentMember => _currentMember;

  ChatViewModel({required AIService aiService}) : _aiService = aiService;
  
  void initializeForMember(String memberId) {
    print('Initializing for member ID: $memberId');
    
    // 현재 멤버 ID 업데이트
    _currentMemberId = memberId;
    _currentMember = MembersData.getMemberById(memberId);
    print('Member name set to: ${_currentMember.name}');
    
    // AI 서비스 초기화
    _aiService.initializeForMember(memberId);
    
    // 해당 멤버의 메시지가 없으면 웰컴 메시지 추가
    if (!_memberMessages.containsKey(memberId) || _memberMessages[memberId]!.isEmpty) {
      _memberMessages[memberId] = [
        ChatMessage(
          message: _currentMember.firstMessage,
          isUser: false,
          timestamp: DateTime.now(),
        )
      ];
    }
    
    notifyListeners();
  }

  void clearMessages() {
    _isGenerating = false;
    _aiService.resetChat();
    
    // 현재 멤버의 메시지만 초기화
    _memberMessages[_currentMemberId] = [
      ChatMessage(
        message: "채팅이 초기화되었어요! ${_currentMember.name}입니다. 다시 대화해요~",
        isUser: false,
        timestamp: DateTime.now(),
      )
    ];
    
    notifyListeners();
  }

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // 사용자 메시지 추가
    final userMessage = ChatMessage(
      message: message,
      isUser: true,
      timestamp: DateTime.now(),
    );
    
    if (!_memberMessages.containsKey(_currentMemberId)) {
      _memberMessages[_currentMemberId] = [];
    }
    
    _memberMessages[_currentMemberId]!.add(userMessage);
    notifyListeners();

    try {
      _isGenerating = true;
      notifyListeners();

      // AI 응답 생성
      final aiResponse = await _aiService.sendMessage(message);

      if (aiResponse != null) {
        // AI 메시지 추가
        final aiMessage = ChatMessage(
          message: aiResponse,
          isUser: false,
          timestamp: DateTime.now(),
        );
        _memberMessages[_currentMemberId]!.add(aiMessage);
      }
    } catch (e) {
      // 에러 처리
      final errorMessage = ChatMessage(
        message: '죄송합니다. 응답을 생성하는 중 오류가 발생했습니다.',
        isUser: false,
        timestamp: DateTime.now(),
      );
      _memberMessages[_currentMemberId]!.add(errorMessage);
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }
} 