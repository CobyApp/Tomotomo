import '../../domain/repositories/chat_repository.dart';
import '../../domain/repositories/ai_chat_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/repositories/points_repository.dart';
import '../../domain/repositories/character_record_repository.dart';
import '../../domain/repositories/theme_repository.dart';
import '../../domain/repositories/saved_expression_repository.dart';
import '../../domain/repositories/friends_repository.dart';
import '../../data/repositories/supabase_chat_repository.dart';
import '../../data/repositories/gemini_ai_repository_impl.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../data/repositories/points_repository_impl.dart';
import '../../data/repositories/character_record_repository_impl.dart';
import '../../data/repositories/theme_repository_impl.dart';
import '../../data/repositories/saved_expression_repository_impl.dart';
import '../../data/repositories/friends_repository_impl.dart';
import '../../presentation/points/points_balance_notifier.dart';
import '../../data/celebrity_persona/celebrity_persona_suggester.dart';

/// Registers app-wide dependencies. Single place for DI (Dependency Inversion).
/// Optional overrides for tests (avoid real API keys / network).
void setupInjection({
  String? geminiApiKey,
  String? geminiModel,
  double? geminiTemperature,
  int? geminiMaxOutputTokens,
}) {
  chatRepository = SupabaseChatRepository();
  pointsRepository = PointsRepositoryImpl();
  aiChatRepository = GeminiAiRepositoryImpl(
    apiKey: geminiApiKey,
    model: geminiModel,
    temperature: geminiTemperature,
    maxOutputTokens: geminiMaxOutputTokens,
  );
  profileRepository = ProfileRepositoryImpl();
  characterRecordRepository = CharacterRecordRepositoryImpl();
  themeRepository = ThemeRepositoryImpl();
  savedExpressionRepository = SavedExpressionRepositoryImpl();
  friendsRepository = FriendsRepositoryImpl();
  celebrityPersonaSuggester = CelebrityPersonaSuggester(
    apiKey: geminiApiKey,
    model: geminiModel,
  );
}

/// Set by [setupInjection]. Used by [App] to provide to widget tree.
late ChatRepository chatRepository;
late PointsRepository pointsRepository;
late AiChatRepository aiChatRepository;
late ProfileRepository profileRepository;
/// Assigned when [PointsBalanceNotifier] is created in [App].
PointsBalanceNotifier? pointsBalanceNotifier;
late CharacterRecordRepository characterRecordRepository;
late ThemeRepository themeRepository;
late SavedExpressionRepository savedExpressionRepository;
late FriendsRepository friendsRepository;
late CelebrityPersonaSuggester celebrityPersonaSuggester;
