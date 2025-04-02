import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';

class ChatStorage {
  static const String _messagePrefix = 'messages_';
  final SharedPreferences _prefs;

  ChatStorage(this._prefs);

  Future<List<ChatMessage>> getMessages(String characterId) async {
    try {
      final String? messagesJson = _prefs.getString('$_messagePrefix$characterId');
      if (messagesJson == null) return [];

      final List<dynamic> decoded = json.decode(messagesJson);
      return decoded.map((msg) => ChatMessage.fromJson(msg)).toList();
    } catch (e) {
      print('Failed to get messages: $e');
      return [];
    }
  }

  Future<void> saveMessage(String characterId, ChatMessage message) async {
    try {
      final messages = await getMessages(characterId);
      messages.add(message);
      
      final String messagesJson = json.encode(
        messages.map((msg) => msg.toJson()).toList()
      );
      
      await _prefs.setString('$_messagePrefix$characterId', messagesJson);
    } catch (e) {
      print('Failed to save message: $e');
    }
  }

  Future<void> clearMessages(String characterId) async {
    try {
      await _prefs.remove('$_messagePrefix$characterId');
    } catch (e) {
      print('Failed to clear messages: $e');
    }
  }
} 