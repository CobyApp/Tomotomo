import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/repositories/ai_chat_repository.dart';
import '../../data/datasources/chat_local_datasource.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../data/repositories/gemini_ai_repository_impl.dart';

/// Registers app-wide dependencies. Single place for DI (Dependency Inversion).
/// [geminiApiKey] optional; pass in tests to avoid loading dotenv. In production, load dotenv first and leave null.
void setupInjection(SharedPreferences prefs, {String? geminiApiKey}) {
  final chatDatasource = ChatLocalDatasource(prefs);
  chatRepository = ChatRepositoryImpl(chatDatasource);
  aiChatRepository = GeminiAiRepositoryImpl(apiKey: geminiApiKey);
}

/// Set by [setupInjection]. Used by [App] to provide to widget tree.
late ChatRepository chatRepository;
late AiChatRepository aiChatRepository;
