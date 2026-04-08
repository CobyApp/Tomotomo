import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../points/points_balance_notifier.dart';
import '../../../core/ui/ui.dart';
import '../../../core/supabase/app_supabase.dart';
import '../../auth/auth_state.dart';
import '../../locale/l10n_context.dart';
import '../../settings/blocked_users_screen.dart';
import '../../settings/language_settings_screen.dart';
import '../../settings/profile_edit_screen.dart';
import '../../settings/theme_settings_screen.dart';
import '../../points/points_usage_screen.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AppSupabase.auth.currentUser;
    final scheme = Theme.of(context).colorScheme;

    return AppPageScaffold(
      title: context.tr('settingsTitle'),
      showPointsChip: true,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageH,
          AppSpacing.pageTop,
          AppSpacing.pageH,
          AppSpacing.pageBottom,
        ),
        children: [
          if (user != null) ...[
            AppSettingsPanel(
              children: [
                AppSettingsNavTile(
                  icon: Icons.email_outlined,
                  title: context.tr('settingsEmail'),
                  subtitle: user.email ?? '',
                  showChevron: false,
                ),
                Consumer<PointsBalanceNotifier>(
                  builder: (context, pn, _) {
                    final bal = pn.balance;
                    final suffix = bal != null ? ' · $bal' : '';
                    return AppSettingsNavTile(
                      icon: Icons.stars_outlined,
                      title: context.tr('settingsPointsBalance'),
                      subtitle: '${context.tr('settingsPointsBalanceSubtitle')}$suffix',
                      showChevron: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(builder: (_) => const PointsUsageScreen()),
                        );
                      },
                    );
                  },
                ),
                AppSettingsNavTile(
                  icon: Icons.person_outlined,
                  title: context.tr('settingsEditProfile'),
                  subtitle: context.tr('settingsEditProfileSubtitle'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
                    );
                  },
                ),
              ],
            ),
          ],
          AppSettingsPanel(
            children: [
              AppSettingsNavTile(
                icon: Icons.palette_outlined,
                title: context.tr('settingsTheme'),
                subtitle: context.tr('settingsThemeSubtitle'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ThemeSettingsScreen()),
                  );
                },
              ),
              AppSettingsNavTile(
                icon: Icons.language_rounded,
                title: context.tr('settingsAppLanguage'),
                subtitle: context.tr('settingsAppLanguageSubtitle'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LanguageSettingsScreen()),
                  );
                },
              ),
              AppSettingsNavTile(
                icon: Icons.block_outlined,
                title: context.tr('settingsBlockedUsers'),
                subtitle: context.tr('settingsBlockedUsersSubtitle'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BlockedUsersScreen()),
                  );
                },
              ),
            ],
          ),
          AppSettingsPanel(
            children: [
              AppSettingsNavTile(
                icon: Icons.logout_rounded,
                title: context.tr('settingsLogout'),
                iconColor: scheme.error,
                titleColor: scheme.error,
                showChevron: false,
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
        ],
      ),
    );
  }
}
