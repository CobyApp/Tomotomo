import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/ai_service.dart';
import 'services/chat_storage_service.dart';
import 'viewmodels/chat_viewmodel.dart';
import 'views/screens/character_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  final prefs = await SharedPreferences.getInstance();
  final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
  
  runApp(MyApp(prefs: prefs, sessionId: sessionId));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  final String sessionId;

  const MyApp({
    super.key, 
    required this.prefs,
    required this.sessionId,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AIService>(
          create: (_) => AIService(sessionId: sessionId),
        ),
        Provider<ChatStorage>(
          create: (_) => ChatStorage(prefs),
        ),
      ],
      child: MaterialApp(
        title: '토모토모',
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Pretendard',
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6A3EA1),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF8F9FA),
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            titleTextStyle: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              fontFamily: 'Pretendard',
            ),
          ),
          cardTheme: CardTheme(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          textTheme: const TextTheme(
            displayLarge: TextStyle(fontFamily: 'Pretendard'),
            displayMedium: TextStyle(fontFamily: 'Pretendard'),
            displaySmall: TextStyle(fontFamily: 'Pretendard'),
            headlineLarge: TextStyle(fontFamily: 'Pretendard'),
            headlineMedium: TextStyle(fontFamily: 'Pretendard'),
            headlineSmall: TextStyle(fontFamily: 'Pretendard'),
            titleLarge: TextStyle(fontFamily: 'Pretendard'),
            titleMedium: TextStyle(fontFamily: 'Pretendard'),
            titleSmall: TextStyle(fontFamily: 'Pretendard'),
            bodyLarge: TextStyle(fontFamily: 'Pretendard'),
            bodyMedium: TextStyle(fontFamily: 'Pretendard'),
            bodySmall: TextStyle(fontFamily: 'Pretendard'),
            labelLarge: TextStyle(fontFamily: 'Pretendard'),
            labelMedium: TextStyle(fontFamily: 'Pretendard'),
            labelSmall: TextStyle(fontFamily: 'Pretendard'),
          ),
          dialogTheme: DialogTheme(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          snackBarTheme: const SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            contentTextStyle: const TextStyle(
              fontFamily: 'Pretendard',
            ),
          ),
        ),
        home: const CharacterListScreen(),
      ),
    );
  }
}
