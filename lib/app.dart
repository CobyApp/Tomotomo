import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/ads/rewarded_ad_service.dart';
import 'core/di/injection.dart';
import 'data/repositories/local_points_repository_impl.dart';
import 'domain/repositories/chat_repository.dart';
import 'domain/repositories/ai_chat_repository.dart';
import 'domain/repositories/profile_repository.dart';
import 'domain/repositories/character_record_repository.dart';
import 'domain/repositories/saved_expression_repository.dart';
import 'data/celebrity_persona/celebrity_persona_suggester.dart';
import 'data/on_device/on_device_model_manager.dart';
import 'presentation/main_shell/main_shell.dart';
import 'presentation/locale/locale_notifier.dart';
import 'presentation/theme/theme_notifier.dart';
import 'presentation/notebook/word_book_refresh_notifier.dart';
import 'presentation/points/points_balance_notifier.dart';
import 'domain/repositories/points_repository.dart';
import 'core/ui/app_scaffold_messenger.dart';
import 'presentation/on_device/on_device_model_setup_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        Provider<ChatRepository>.value(value: chatRepository),
        Provider<AiChatRepository>.value(value: aiChatRepository),
        Provider<ProfileRepository>.value(value: profileRepository),
        Provider<PointsRepository>.value(value: pointsRepository),
        Provider<LocalPointsRepositoryImpl>.value(value: localPointsRepository),
        ChangeNotifierProvider<RewardedAdService>.value(value: rewardedAdService),
        ChangeNotifierProvider<OnDeviceModelManager>.value(value: onDeviceModelManager),
        ChangeNotifierProvider(
          create: (c) {
            final n = PointsBalanceNotifier(c.read<PointsRepository>());
            pointsBalanceNotifier = n;
            return n;
          },
        ),
        ChangeNotifierProvider(create: (c) => LocaleNotifier(c.read<ProfileRepository>())),
        Provider<CharacterRecordRepository>.value(value: characterRecordRepository),
        Provider<SavedExpressionRepository>.value(value: savedExpressionRepository),
        ChangeNotifierProvider(create: (_) => WordBookRefreshNotifier()),
        Provider<CelebrityPersonaSuggester>.value(value: celebrityPersonaSuggester),
      ],
      child: Builder(
        builder: (context) {
          return MaterialApp(
            scaffoldMessengerKey: appScaffoldMessengerKey,
            title: 'トモトモ',
            theme: context.watch<ThemeNotifier>().theme,
            darkTheme: context.watch<ThemeNotifier>().darkTheme,
            themeMode: context.watch<ThemeNotifier>().mode,
            locale: context.watch<LocaleNotifier>().locale,
            supportedLocales: const [Locale('ko'), Locale('ja')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              final mq = MediaQuery.of(context);
              return MediaQuery(
                data: mq.copyWith(
                  textScaler: mq.textScaler.clamp(minScaleFactor: 1.0, maxScaleFactor: 1.3),
                ),
                child: child!,
              );
            },
            home: Consumer<OnDeviceModelManager>(
              builder: (context, manager, _) {
                if (manager.isReady) return const MainShell();
                return const OnDeviceModelSetupScreen(requiredSetup: true);
              },
            ),
          );
        },
      ),
    );
  }
}
