import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_local_datasource.dart';

/// Chat repository implementation. Delegates to local datasource.
class ChatRepositoryImpl implements ChatRepository {
  final ChatLocalDatasource _datasource;

  ChatRepositoryImpl(this._datasource);

  @override
  Future<List<ChatMessage>> getMessages(String characterId) =>
      _datasource.getMessages(characterId);

  @override
  Future<void> saveMessage(String characterId, ChatMessage message) async {
    final messages = await _datasource.getMessages(characterId);
    messages.add(message);
    await _datasource.saveMessages(characterId, messages);
  }

  @override
  Future<void> clearMessages(String characterId) =>
      _datasource.clearMessages(characterId);
}
