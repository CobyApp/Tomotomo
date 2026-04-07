import '../../domain/repositories/chat_repository.dart';
import '../../domain/repositories/ai_chat_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/repositories/character_record_repository.dart';
import '../../domain/repositories/theme_repository.dart';
import '../../domain/repositories/saved_expression_repository.dart';
import '../../domain/repositories/friends_repository.dart';
import '../../data/repositories/supabase_chat_repository.dart';
import '../../data/repositories/ollama_ai_repository_impl.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../data/repositories/character_record_repository_impl.dart';
import '../../data/repositories/theme_repository_impl.dart';
import '../../data/repositories/saved_expression_repository_impl.dart';
import '../../data/repositories/friends_repository_impl.dart';

/// Registers app-wide dependencies. Single place for DI (Dependency Inversion).
/// Optional [ollamaBaseUrl] / [ollamaModel] override dotenv (use in tests).
void setupInjection({
  String? ollamaBaseUrl,
  String? ollamaModel,
}) {
  chatRepository = SupabaseChatRepository();
  aiChatRepository = OllamaAiRepositoryImpl(
    baseUrl: ollamaBaseUrl,
    model: ollamaModel,
  );
  profileRepository = ProfileRepositoryImpl();
  characterRecordRepository = CharacterRecordRepositoryImpl();
  themeRepository = ThemeRepositoryImpl();
  savedExpressionRepository = SavedExpressionRepositoryImpl();
  friendsRepository = FriendsRepositoryImpl();
}

/// Set by [setupInjection]. Used by [App] to provide to widget tree.
late ChatRepository chatRepository;
late AiChatRepository aiChatRepository;
late ProfileRepository profileRepository;
late CharacterRecordRepository characterRecordRepository;
late ThemeRepository themeRepository;
late SavedExpressionRepository savedExpressionRepository;
late FriendsRepository friendsRepository;
