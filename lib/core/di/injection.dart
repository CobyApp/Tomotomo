import 'package:hive_ce/hive.dart';

import '../local/hive_boxes.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/repositories/ai_chat_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/repositories/points_repository.dart';
import '../../domain/repositories/character_record_repository.dart';
import '../../domain/repositories/theme_repository.dart';
import '../../domain/repositories/saved_expression_repository.dart';
import '../../data/repositories/local_chat_repository_impl.dart';
import '../../data/repositories/gemini_ai_repository_impl.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../data/repositories/local_points_repository_impl.dart';
import '../../data/repositories/character_record_repository_impl.dart';
import '../../data/repositories/theme_repository_impl.dart';
import '../../data/repositories/saved_expression_repository_impl.dart';
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
  chatRepository = LocalChatRepositoryImpl(Hive.box(HiveBoxes.chats));
  pointsRepository = LocalPointsRepositoryImpl(Hive.box(HiveBoxes.points));
  aiChatRepository = GeminiAiRepositoryImpl(
    apiKey: geminiApiKey,
    model: geminiModel,
    temperature: geminiTemperature,
    maxOutputTokens: geminiMaxOutputTokens,
  );
  profileRepository = ProfileRepositoryImpl(Hive.box(HiveBoxes.settings));
  characterRecordRepository =
      CharacterRecordRepositoryImpl(Hive.box(HiveBoxes.characters));
  themeRepository = ThemeRepositoryImpl(Hive.box(HiveBoxes.settings));
  savedExpressionRepository =
      SavedExpressionRepositoryImpl(Hive.box(HiveBoxes.wordbook));
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
late CelebrityPersonaSuggester celebrityPersonaSuggester;
