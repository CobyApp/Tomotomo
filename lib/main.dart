import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'views/screens/character_list_screen.dart';
import 'services/chat_storage_service.dart';
import 'services/ai_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");
  final prefs = await SharedPreferences.getInstance();
  final sessionId = DateTime.now().millisecondsSinceEpoch.toString();

  runApp(MyApp(
    prefs: prefs,
    sessionId: sessionId,
  ));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  final String sessionId;

  const MyApp({
    Key? key,
    required this.prefs,
    required this.sessionId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ChatStorageService>(
          create: (_) => ChatStorageService(prefs),
        ),
        Provider<AIService>(
          create: (_) => AIService(sessionId: sessionId),
        ),
      ],
      child: MaterialApp(
        title: '일본어 회화 연습',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.grey[50],
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.black87),
            titleTextStyle: TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        home: const CharacterListScreen(),
      ),
    );
  }
}
