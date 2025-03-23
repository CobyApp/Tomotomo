import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'viewmodels/chat_viewmodel.dart';
import 'views/screens/home_screen.dart';
import 'services/ai_service.dart';
import 'utils/constants.dart';  // AppTheme 가져오기

void main() async {
  WidgetsFlutterBinding.ensureInitialized();  // Flutter 바인딩 초기화
  await dotenv.load(fileName: ".env");
  final aiService = AIService();
  
  runApp(MyApp(aiService: aiService));
}

class MyApp extends StatelessWidget {
  final AIService aiService;

  const MyApp({super.key, required this.aiService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ChatViewModel(aiService: aiService),
        ),
      ],
      child: MaterialApp(
        title: 'NMIXX Chat',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: AppTheme.primaryColor,
          scaffoldBackgroundColor: AppTheme.background,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppTheme.primaryColor,
            elevation: 0,
            centerTitle: false,
            titleTextStyle: TextStyle(
              fontFamily: 'Quicksand',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            iconTheme: IconThemeData(color: Colors.white),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: AppTheme.primaryButtonStyle,
          ),
          fontFamily: 'Quicksand',
          textTheme: TextTheme(
            displayLarge: AppTheme.headingLarge,
            displayMedium: AppTheme.headingMedium,
            bodyLarge: AppTheme.bodyLarge,
            bodyMedium: AppTheme.bodyMedium,
            bodySmall: AppTheme.bodySmall,
          ),
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppTheme.primaryColor,
            primary: AppTheme.primaryColor,
            secondary: AppTheme.accentColor,
            background: AppTheme.background,
            surface: AppTheme.cardBackground,
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
