import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/di/injection.dart';
import 'domain/repositories/chat_repository.dart';
import 'domain/repositories/ai_chat_repository.dart';
import 'domain/repositories/profile_repository.dart';
import 'domain/repositories/character_record_repository.dart';
import 'domain/repositories/theme_repository.dart';
import 'domain/repositories/saved_expression_repository.dart';
import 'domain/repositories/friends_repository.dart';
import 'data/celebrity_persona/celebrity_persona_suggester.dart';
import 'presentation/auth/auth_gate.dart';
import 'presentation/auth/auth_state.dart';
import 'presentation/locale/locale_notifier.dart';
import 'presentation/theme/theme_notifier.dart';
import 'presentation/notebook/word_book_refresh_notifier.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        /// Above [MaterialApp] so theme/locale rebuilds do not dispose/recreate auth state.
        ChangeNotifierProvider(create: (_) => AppAuthState()),
        Provider<ThemeRepository>.value(value: themeRepository),
        ChangeNotifierProvider(create: (c) => ThemeNotifier(c.read<ThemeRepository>())),
        Provider<ChatRepository>.value(value: chatRepository),
        Provider<AiChatRepository>.value(value: aiChatRepository),
        Provider<ProfileRepository>.value(value: profileRepository),
        ChangeNotifierProvider(create: (c) => LocaleNotifier(c.read<ProfileRepository>())),
        Provider<CharacterRecordRepository>.value(value: characterRecordRepository),
        Provider<SavedExpressionRepository>.value(value: savedExpressionRepository),
        ChangeNotifierProvider(create: (_) => WordBookRefreshNotifier()),
        Provider<FriendsRepository>.value(value: friendsRepository),
        Provider<CelebrityPersonaSuggester>.value(value: celebrityPersonaSuggester),
      ],
      child: Builder(
        builder: (context) {
          return MaterialApp(
            title: 'トモトモ',
            theme: context.watch<ThemeNotifier>().theme,
            locale: context.watch<LocaleNotifier>().locale,
            supportedLocales: const [Locale('ko'), Locale('ja')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}
