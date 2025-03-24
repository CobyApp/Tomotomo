import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';

class ChatStorageService {
  static const String _messagePrefix = 'chat_messages_';
  final SharedPreferences _prefs;

  ChatStorageService(this._prefs);

  // 특정 캐릭터와의 모든 채팅 메시지 가져오기
  Future<List<ChatMessage>> getMessages(String characterId) async {
    final String? messagesJson = _prefs.getString('$_messagePrefix$characterId');
    if (messagesJson == null) return [];

    try {
      List<dynamic> decoded = json.decode(messagesJson);
      return decoded.map((msg) => ChatMessage.fromJson(msg)).toList();
    } catch (e) {
      print('Error loading messages: $e');
      return [];
    }
  }

  // 새 메시지 저장
  Future<void> saveMessage(ChatMessage message) async {
    try {
      List<ChatMessage> messages = await getMessages(message.characterId);
      messages.add(message);
      
      final String messagesJson = json.encode(
        messages.map((msg) => msg.toJson()).toList()
      );
      
      await _prefs.setString(
        '$_messagePrefix${message.characterId}',
        messagesJson
      );
    } catch (e) {
      print('Error saving message: $e');
    }
  }

  // 특정 캐릭터와의 마지막 메시지 가져오기
  Future<ChatMessage?> getLastMessage(String characterId) async {
    try {
      List<ChatMessage> messages = await getMessages(characterId);
      if (messages.isEmpty) return null;
      return messages.last;
    } catch (e) {
      print('Error getting last message: $e');
      return null;
    }
  }

  // 특정 캐릭터와의 대화 초기화
  Future<void> clearMessages(String characterId) async {
    await _prefs.remove('$_messagePrefix$characterId');
  }
} 