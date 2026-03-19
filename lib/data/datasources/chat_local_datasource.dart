import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/chat_message.dart';

/// Local persistence for chat messages using SharedPreferences.
/// Single responsibility: key-value storage only.
class ChatLocalDatasource {
  static const String _messagePrefix = 'messages_';
  final SharedPreferences _prefs;

  ChatLocalDatasource(this._prefs);

  Future<List<ChatMessage>> getMessages(String characterId) async {
    try {
      final String? messagesJson = _prefs.getString('$_messagePrefix$characterId');
      if (messagesJson == null) return [];

      final List<dynamic> decoded = json.decode(messagesJson);
      return decoded
          .map((msg) => ChatMessage.fromJson(msg as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveMessages(String characterId, List<ChatMessage> messages) async {
    try {
      final String messagesJson = json
          .encode(messages.map((msg) => msg.toJson()).toList());
      await _prefs.setString('$_messagePrefix$characterId', messagesJson);
    } catch (_) {}
  }

  Future<void> clearMessages(String characterId) async {
    try {
      await _prefs.remove('$_messagePrefix$characterId');
    } catch (_) {}
  }
}
