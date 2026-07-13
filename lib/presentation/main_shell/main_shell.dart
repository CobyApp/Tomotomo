import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/home_widget/notebook_home_widget_sync.dart';
import '../../core/platform/ios_post_layout_frames.dart';
import '../../domain/repositories/saved_expression_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/ui.dart';
import '../../domain/repositories/profile_repository.dart';
import '../points/points_balance_notifier.dart';
import '../locale/l10n_context.dart';
import '../locale/locale_notifier.dart';
import 'tabs/characters_tab.dart';
import 'tabs/chats_tab.dart';
import 'tabs/settings_tab.dart';
import '../notebook/word_book_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  static const String _localUserId = 'local';
  final GlobalKey<WordBookScreenState> _wordBookKey = GlobalKey<WordBookScreenState>();
  final GlobalKey<CharactersTabState> _charactersTabKey = GlobalKey<CharactersTabState>();
  final GlobalKey<ChatsTabState> _chatsTabKey = GlobalKey<ChatsTabState>();
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      CharactersTab(key: _charactersTabKey),
      ChatsTab(key: _chatsTabKey),
      WordBookScreen(key: _wordBookKey),
      const SettingsTab(),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(() async {
        await waitIosPostLayoutFrames(frames: 2);
        if (!mounted) return;
        unawaited(_ensureProfile());
        if (!mounted) return;
        final repo = context.read<SavedExpressionRepository>();
        final appLang = context.read<LocaleNotifier>().languageCode;
        unawaited(
          syncNotebookToHomeWidget(
            repo,
            defaultLangIfUnset: appLang == 'ja' ? 'ja' : 'ko',
          ),
        );
      }());
    });
  }

  Future<void> _ensureProfile() async {
    if (!mounted) return;
    try {
      final repo = context.read<ProfileRepository>();
      // Local profile is created with defaults if absent.
      await repo.getProfile(_localUserId);
      if (!mounted) return;
      await context.read<PointsBalanceNotifier>().loadInitial();
      if (!mounted) return;
      context.read<LocaleNotifier>().loadFromProfile(_localUserId);
    } catch (_) {}
  }

  void _onNavSelect(int i) {
    setState(() => _index = i);
    if (i == 0) _charactersTabKey.currentState?.reloadFromTabSelection();
    if (i == 1) _chatsTabKey.currentState?.reloadFromTabSelection();
    if (i == 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _wordBookKey.currentState?.reloadWhenTabSelected();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: AppTheme.shellBackdropDecoration(scheme),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(
          index: _index,
          children: _pages,
        ),
        bottomNavigationBar: AppGlassNavBar(
          currentIndex: _index,
          onSelect: _onNavSelect,
          items: [
            NavItemData(
              icon: Icons.people_outline_rounded,
              selectedIcon: Icons.people_rounded,
              label: context.tr('tabCharacters'),
            ),
            NavItemData(
              icon: Icons.chat_bubble_outline_rounded,
              selectedIcon: Icons.chat_bubble_rounded,
              label: context.tr('tabChats'),
            ),
            NavItemData(
              icon: Icons.menu_book_outlined,
              selectedIcon: Icons.menu_book_rounded,
              label: context.tr('tabNotebook'),
            ),
            NavItemData(
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings_rounded,
              label: context.tr('tabSettings'),
            ),
          ],
        ),
      ),
    );
  }
}
