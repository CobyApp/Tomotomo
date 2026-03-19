import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/supabase/app_supabase.dart';
import '../../auth/auth_state.dart';
import '../../locale/l10n_context.dart';
import '../../notebook/expressions_notebook_screen.dart';
import '../../settings/language_settings_screen.dart';
import '../../settings/theme_settings_screen.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AppSupabase.auth.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('settingsTitle')),
        centerTitle: false,
      ),
      body: ListView(
        children: [
          if (user != null)
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: Text(context.tr('settingsEmail')),
              subtitle: Text(user.email ?? ''),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(context.tr('settingsTheme')),
            subtitle: Text(context.tr('settingsThemeSubtitle')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ThemeSettingsScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.book_outlined),
            title: Text(context.tr('notebookTitle')),
            subtitle: Text(context.tr('notebookSubtitle')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ExpressionsNotebookScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(context.tr('settingsAppLanguage')),
            subtitle: Text(context.tr('settingsAppLanguageSubtitle')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LanguageSettingsScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
            title: Text(
              context.tr('settingsLogout'),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(context.tr('settingsLogoutConfirmTitle')),
                  content: Text(context.tr('settingsLogoutConfirmBody')),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(context.tr('cancel')),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(context.tr('settingsLogout')),
                    ),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                await context.read<AppAuthState>().signOut();
              }
            },
          ),
        ],
      ),
    );
  }
}
