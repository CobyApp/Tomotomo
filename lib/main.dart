import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'viewmodels/chat_viewmodel.dart';
import 'services/ai_service.dart';
import 'utils/constants.dart';  // AppTheme 가져오기
import 'views/screens/character_select_screen.dart';
import 'views/screens/chat_screen.dart';
import 'views/screens/settings_screen.dart';  // 추가
import 'viewmodels/settings_viewmodel.dart';
import 'utils/localization.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();  // Flutter 바인딩 초기화
  await dotenv.load(fileName: ".env");
  
  // AIService 초기화
  final aiService = AIService();
  await aiService.initialize();  // initialize 메서드 호출 추가
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => L10n()),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
        ChangeNotifierProvider(create: (_) => ChatViewModel(aiService: aiService)),
      ],
      child: MyApp(aiService: aiService),  // aiService 파라미터 추가
    ),
  );
}

class MyApp extends StatelessWidget {
  final AIService aiService;

  const MyApp({super.key, required this.aiService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Virtual Character Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Quicksand',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const CharacterSelectScreen(),
        '/chat': (context) => const ChatScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
