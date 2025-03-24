import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'viewmodels/chat_viewmodel.dart';
import 'services/ai_service.dart';
import 'utils/constants.dart';
import 'views/screens/character_select_screen.dart';
import 'views/screens/chat_screen.dart';
import 'views/screens/settings_screen.dart';
import 'viewmodels/settings_viewmodel.dart';
import 'utils/localization.dart';
import 'utils/app_theme.dart';  // AppTheme는 여기서만 import
import 'data/characters.dart';  // characters import 추가
import 'services/chat_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // dotenv 로드 추가
  await dotenv.load(fileName: ".env");
  
  final prefs = await SharedPreferences.getInstance();
  final chatStorage = ChatStorageService(prefs);
  final aiService = AIService();

  runApp(MyApp(
    aiService: aiService,
    chatStorage: chatStorage,
  ));
}

class MyApp extends StatelessWidget {
  final AIService aiService;
  final ChatStorageService chatStorage;

  const MyApp({super.key, required this.aiService, required this.chatStorage});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsViewModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => L10n(),
        ),
        Provider.value(value: aiService),
        Provider.value(value: chatStorage),
      ],
      child: MaterialApp(
        title: AppConstants.appNameEn,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        initialRoute: '/',
        routes: {
          '/': (context) => CharacterSelectScreen(
                chatStorage: chatStorage,
                aiService: aiService,
              ),
          '/settings': (context) => const SettingsScreen(),
        },
      ),
    );
  }
}
