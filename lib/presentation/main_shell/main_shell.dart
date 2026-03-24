import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/home_widget/notebook_home_widget_sync.dart';
import '../../core/supabase/app_supabase.dart';
import '../../domain/repositories/saved_expression_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/ui.dart';
import '../../domain/repositories/profile_repository.dart';
import '../locale/l10n_context.dart';
import '../locale/locale_notifier.dart';
import '../theme/theme_notifier.dart';
import 'tabs/add_friend_tab.dart';
import 'tabs/friends_tab.dart';
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
  final GlobalKey<WordBookScreenState> _wordBookKey = GlobalKey<WordBookScreenState>();
  final GlobalKey<FriendsTabState> _friendsTabKey = GlobalKey<FriendsTabState>();
  final GlobalKey<ChatsTabState> _chatsTabKey = GlobalKey<ChatsTabState>();
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      FriendsTab(key: _friendsTabKey),
      ChatsTab(key: _chatsTabKey),
      const AddFriendTab(),
      WordBookScreen(key: _wordBookKey),
      const SettingsTab(),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureProfile();
      if (!mounted) return;
      final repo = context.read<SavedExpressionRepository>();
      final appLang = context.read<LocaleNotifier>().languageCode;
      unawaited(
        syncNotebookToHomeWidget(
          repo,
          defaultLangIfUnset: appLang == 'ja' ? 'ja' : 'ko',
        ),
      );
    });
  }

  Future<void> _ensureProfile() async {
    if (!mounted) return;
    final user = AppSupabase.auth.currentUser;
    if (user == null) return;
    try {
      final repo = context.read<ProfileRepository>();
      final p = await repo.getProfile(user.id);
      if (p == null) {
        await repo.createProfile(user.id, email: user.email);
      }
      if (!mounted) return;
      context.read<ThemeNotifier>().load(user.id);
      context.read<LocaleNotifier>().loadFromProfile(user.id);
    } catch (_) {}
  }

  void _onNavSelect(int i) {
    setState(() => _index = i);
    if (i == 0) _friendsTabKey.currentState?.reloadFromTabSelection();
    if (i == 1) _chatsTabKey.currentState?.reloadFromTabSelection();
    if (i == 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _wordBookKey.currentState?.reloadWhenTabSelected();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.shellGradientTop(scheme),
            AppTheme.shellGradientBottom(scheme),
          ],
        ),
      ),
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
              label: context.tr('tabFriends'),
            ),
            NavItemData(
              icon: Icons.chat_bubble_outline_rounded,
              selectedIcon: Icons.chat_bubble_rounded,
              label: context.tr('tabChats'),
            ),
            NavItemData(
              icon: Icons.search_outlined,
              selectedIcon: Icons.search_rounded,
              label: context.tr('tabAddFriend'),
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
