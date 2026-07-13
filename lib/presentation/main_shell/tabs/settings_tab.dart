import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../points/points_balance_notifier.dart';
import '../../../core/ui/ui.dart';
import '../../locale/l10n_context.dart';
import '../../settings/language_settings_screen.dart';
import '../../settings/profile_edit_screen.dart';
import '../../points/points_usage_screen.dart';
import '../../points/points_topup_screen.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
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
          AppSettingsPanel(
            children: [
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
                icon: Icons.add_card_rounded,
                title: context.tr('pointsTopupTitle'),
                subtitle: context.tr('pointsTopupSubtitle'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(builder: (_) => const PointsTopUpScreen()),
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
          AppSettingsPanel(
            children: [
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
            ],
          ),
        ],
      ),
    );
  }
}
