import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/supabase/app_supabase.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureProfile());
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          setState(() => _index = i);
          if (i == 0) {
            _friendsTabKey.currentState?.reloadFromTabSelection();
          }
          if (i == 1) {
            _chatsTabKey.currentState?.reloadFromTabSelection();
          }
          if (i == 3) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _wordBookKey.currentState?.reloadWhenTabSelected();
            });
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.people_outline),
            selectedIcon: const Icon(Icons.people),
            label: context.tr('tabFriends'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline),
            selectedIcon: const Icon(Icons.chat_bubble),
            label: context.tr('tabChats'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.search_outlined),
            selectedIcon: const Icon(Icons.search),
            label: context.tr('tabAddFriend'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: const Icon(Icons.menu_book),
            label: context.tr('tabNotebook'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: context.tr('tabSettings'),
          ),
        ],
      ),
    );
  }
}
