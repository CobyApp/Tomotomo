import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../points/points_balance_notifier.dart';
import '../../../core/ui/app_settings_tile.dart';
import '../../../core/ui/app_tokens.dart';
import '../../../core/ui/paper/paper_scaffold.dart';
import '../../../core/ui/paper/paper_theme.dart';
import '../../../core/ui/paper/paper_tokens.dart';
import '../../locale/l10n_context.dart';
import '../../settings/language_settings_screen.dart';
import '../../settings/friend_language_settings_screen.dart';
import '../../settings/profile_edit_screen.dart';
import '../../points/points_usage_screen.dart';
import '../../points/points_topup_screen.dart';
import '../../on_device/on_device_model_setup_screen.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return PaperScaffold(
      title: context.tr('settingsTitle'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageH,
          AppSpacing.pageTop,
          AppSpacing.pageH,
          AppSpacing.pageBottom,
        ),
        children: [
          _SettingsGroupLabel(context.tr('settingsProfileSection')),
          AppSettingsPanel(
            children: [
              Consumer<PointsBalanceNotifier>(
                builder: (context, pn, _) {
                  final bal = pn.balance;
                  final suffix = bal != null ? ' · $bal' : '';
                  return AppSettingsNavTile(
                    icon: Icons.stars_outlined,
                    title: context.tr('settingsPointsBalance'),
                    subtitle:
                        '${context.tr('settingsPointsBalanceSubtitle')}$suffix',
                    showChevron: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const PointsUsageScreen(),
                        ),
                      );
                    },
                  );
                },
              ),
              AppSettingsNavTile(
                icon: Icons.add_card_rounded,
                title: context.tr('pointsEarnTitle'),
                subtitle: context.tr('pointsEarnSubtitle'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const PointsTopUpScreen(),
                    ),
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
                    MaterialPageRoute(
                      builder: (_) => const ProfileEditScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          _SettingsGroupLabel(context.tr('settingsAppSection')),
          AppSettingsPanel(
            children: [
              AppSettingsNavTile(
                icon: Icons.language_rounded,
                title: context.tr('settingsAppLanguage'),
                subtitle: context.tr('settingsAppLanguageSubtitle'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LanguageSettingsScreen(),
                    ),
                  );
                },
              ),
              AppSettingsNavTile(
                icon: Icons.people_alt_rounded,
                title: context.tr('settingsFriendLanguage'),
                subtitle: context.tr('settingsFriendLanguageSubtitle'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const FriendLanguageSettingsScreen(),
                    ),
                  );
                },
              ),
              AppSettingsNavTile(
                icon: Icons.memory_rounded,
                title: context.tr('onDeviceModelTitle'),
                subtitle: context.tr('onDeviceModelSettingsSubtitle'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const OnDeviceModelSetupScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsGroupLabel extends StatelessWidget {
  const _SettingsGroupLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
      child: Text(
        label,
        style: cuteDisplay(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: context.paper.coral,
        ),
      ),
    );
  }
}
