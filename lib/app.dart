import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/di/injection.dart';
import 'domain/repositories/chat_repository.dart';
import 'domain/repositories/ai_chat_repository.dart';
import 'presentation/character_list/character_list_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ChatRepository>.value(value: chatRepository),
        Provider<AiChatRepository>.value(value: aiChatRepository),
      ],
      child: MaterialApp(
        title: '토모토모',
        theme: AppTheme.light,
        home: const CharacterListScreen(),
      ),
    );
  }
}
