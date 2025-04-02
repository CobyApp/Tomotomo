import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';
import '../models/character.dart';
import '../services/chat_storage_service.dart';

class ChatViewModel extends ChangeNotifier {
  final AIService aiService;
  final ChatStorageService chatStorage;
  final Character character;
  final List<ChatMessage> _messages = [];
  bool isGenerating = false;

  List<ChatMessage> get messages => _messages;

  ChatViewModel({
    required this.aiService,
    required this.chatStorage,
    required this.character,
  }) {
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final savedMessages = await chatStorage.getMessages(character.id);
    _messages.addAll(savedMessages);
    notifyListeners();
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      characterId: character.id,
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
    );
    
    _messages.add(userMessage);
    await chatStorage.saveMessage(userMessage);
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));
    isGenerating = true;
    notifyListeners();

    try {
      final response = await aiService.sendMessage(content, character);
      
      final aiMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        characterId: character.id,
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
      );
      
      _messages.add(aiMessage);
      await chatStorage.saveMessage(aiMessage);
      
    } catch (e) {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        characterId: character.id,
        content: '申し訳ありません。エラーが発生しました。',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } finally {
      isGenerating = false;
      notifyListeners();
    }
  }

  Future<void> resetChat() async {
    try {
      // 저장된 메시지 삭제
      await chatStorage.clearMessages(character.id);
      
      // 메모리상의 메시지 목록 초기화
      _messages.clear();
      
      // AI 서비스 세션 초기화
      aiService.resetChat();
      
      // 상태 업데이트
      isGenerating = false;
      notifyListeners();
      
      // 초기 메시지 추가
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        characterId: character.id,
        content: '${character.nameJp}と日本語で話しましょう！',
        isUser: false,
        timestamp: DateTime.now(),
      ));
      
      // 초기 메시지 저장
      await chatStorage.saveMessage(_messages.first);
      
      notifyListeners();
    } catch (e) {
      print('Error resetting chat: $e');
      // 에러 발생 시 사용자에게 알림
    }
  }
} 