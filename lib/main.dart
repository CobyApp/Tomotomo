import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'viewmodels/chat_viewmodel.dart';
import 'views/screens/chat_screen.dart';
import 'services/ai_service.dart';

void main() async {
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
        title: 'AI Chat',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const ChatScreen(),
      ),
    );
  }
}
