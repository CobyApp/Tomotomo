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
        title: 'AI Chat',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const CharacterListScreen(),
      ),
    );
  }
}
