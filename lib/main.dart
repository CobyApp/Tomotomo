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
    return ChangeNotifierProvider(
      create: (_) => ChatViewModel(aiService: aiService),
      child: MaterialApp(
        title: 'NMIXX 채팅',
        theme: ThemeData(
          primarySwatch: Colors.purple,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
