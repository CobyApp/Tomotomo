import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/supabase/app_supabase.dart';
import '../../domain/repositories/profile_repository.dart';
import '../locale/l10n_context.dart';
import '../locale/locale_notifier.dart';
import '../theme/theme_notifier.dart';
import 'tabs/friends_tab.dart';
import 'tabs/chats_tab.dart';
import 'tabs/settings_tab.dart';
import '../notebook/expressions_notebook_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
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

  static const List<Widget> _tabs = [
    FriendsTab(),
    ChatsTab(),
    ExpressionsNotebookScreen(),
    SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
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
