import 'package:hive_ce/hive.dart';

import '../ads/rewarded_ad_service.dart';
import '../local/hive_boxes.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/repositories/ai_chat_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/repositories/points_repository.dart';
import '../../domain/repositories/character_record_repository.dart';
import '../../domain/repositories/theme_repository.dart';
import '../../domain/repositories/saved_expression_repository.dart';
import '../../data/repositories/local_chat_repository_impl.dart';
import '../../data/repositories/litert_lm_ai_repository_impl.dart';
import '../../data/on_device/flutter_gemma_ai_runtime.dart';
import '../../data/on_device/on_device_ai_runtime.dart';
import '../../data/on_device/on_device_model_manager.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../data/repositories/local_points_repository_impl.dart';
import '../../data/repositories/character_record_repository_impl.dart';
import '../../data/repositories/theme_repository_impl.dart';
import '../../data/repositories/saved_expression_repository_impl.dart';
import '../../data/rag/local_rag_retriever.dart';
import '../../data/chat_background/chat_background_store.dart';
import '../../presentation/points/points_balance_notifier.dart';
import '../../data/celebrity_persona/celebrity_persona_suggester.dart';

/// Registers app-wide dependencies. Single place for DI (Dependency Inversion).
/// Optional runtime override keeps platform inference out of unit tests.
void setupInjection({OnDeviceAiRuntime? aiRuntime}) {
  chatRepository = LocalChatRepositoryImpl(Hive.box(HiveBoxes.chats));
  final pts = LocalPointsRepositoryImpl(Hive.box(HiveBoxes.points));
  pointsRepository = pts;
  localPointsRepository = pts;
  rewardedAdService = RewardedAdService();
  onDeviceAiRuntime = aiRuntime ?? FlutterGemmaAiRuntime();
  onDeviceModelManager = OnDeviceModelManager(onDeviceAiRuntime);
  savedExpressionRepository = SavedExpressionRepositoryImpl(Hive.box(HiveBoxes.wordbook));
  // Offline local RAG: feeds saved vocabulary + relevant past turns into replies.
  localRagRetriever = LocalRagRetriever(savedExpressionRepository, chatRepository);
  aiChatRepository = LiteRtLmAiRepositoryImpl(
    onDeviceAiRuntime,
    ragRetriever: localRagRetriever,
  );
  profileRepository = ProfileRepositoryImpl(Hive.box(HiveBoxes.settings));
  characterRecordRepository = CharacterRecordRepositoryImpl(Hive.box(HiveBoxes.characters));
  themeRepository = ThemeRepositoryImpl(Hive.box(HiveBoxes.settings));
  celebrityPersonaSuggester = CelebrityPersonaSuggester(onDeviceAiRuntime);
  chatBackgroundStore = ChatBackgroundStore(Hive.box(HiveBoxes.settings));
}

/// Set by [setupInjection]. Used by [App] to provide to widget tree.
late ChatRepository chatRepository;
late PointsRepository pointsRepository;

/// Concrete points repo (same instance as [pointsRepository]) so the ad UI
/// can call rewarded-ad-specific methods not on the [PointsRepository] interface.
late LocalPointsRepositoryImpl localPointsRepository;
late RewardedAdService rewardedAdService;
late OnDeviceAiRuntime onDeviceAiRuntime;
late OnDeviceModelManager onDeviceModelManager;
late AiChatRepository aiChatRepository;
late ProfileRepository profileRepository;

/// Assigned when [PointsBalanceNotifier] is created in [App].
PointsBalanceNotifier? pointsBalanceNotifier;

/// Mirror of the user's chosen UI language, kept up to date by LocaleNotifier.
/// Layers without a BuildContext (notifications) must localize with THIS, not
/// the device locale — the two differ whenever the user picks a language.
String appLanguageCode = 'ko';
late CharacterRecordRepository characterRecordRepository;
late ThemeRepository themeRepository;
late SavedExpressionRepository savedExpressionRepository;
late LocalRagRetriever localRagRetriever;
late CelebrityPersonaSuggester celebrityPersonaSuggester;
late ChatBackgroundStore chatBackgroundStore;
