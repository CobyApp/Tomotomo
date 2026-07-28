import 'package:flutter/material.dart';
import '../../../core/ui/app_settings_tile.dart';
import '../../../core/ui/app_tokens.dart';
import '../../../core/ui/paper/paper_scaffold.dart';
import '../../../core/ui/paper/paper_widgets.dart';
import '../../locale/l10n_context.dart';
import '../../settings/appearance_settings_screen.dart';
import '../../settings/language_settings_screen.dart';
import '../../settings/legal_web_view_screen.dart';
import '../../settings/profile_edit_screen.dart';
import '../../points/points_usage_screen.dart';
import '../../on_device/on_device_model_setup_screen.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return PaperScaffold(
      title: context.tr('settingsTitle'),
      showBackground: false,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageH,
          AppSpacing.pageTop,
          AppSpacing.pageH,
          AppSpacing.pageBottom,
        ),
        children: [
          PaperSectionLabel(context.tr('settingsProfileSection')),
          AppSettingsPanel(
            dividerIndent: 16,
            children: [
              // Description only — the balance itself lives on the points
              // screen and the toolbar chip, not tacked onto this subtitle.
              AppSettingsNavTile(
                title: context.tr('settingsPointsBalance'),
                subtitle: context.tr('settingsPointsBalanceSubtitle'),
                showChevron: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const PointsUsageScreen(),
                    ),
                  );
                },
              ),
              AppSettingsNavTile(
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
          PaperSectionLabel(context.tr('settingsAppSection')),
          AppSettingsPanel(
            dividerIndent: 16,
            children: [
              AppSettingsNavTile(
                title: context.tr('languageMenuTitle'),
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
                title: context.tr('appearanceTitle'),
                subtitle: context.tr('appearanceSubtitle'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const AppearanceSettingsScreen(),
                    ),
                  );
                },
              ),
              AppSettingsNavTile(
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
          const SizedBox(height: 4),
          PaperSectionLabel(context.tr('settingsLegalSection')),
          AppSettingsPanel(
            dividerIndent: 16,
            children: [
              AppSettingsNavTile(
                title: context.tr('settingsPrivacyPolicy'),
                subtitle: context.tr('settingsPrivacyPolicySubtitle'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => LegalWebViewScreen(
                        doc: LegalDoc.privacy,
                        title: context.tr('settingsPrivacyPolicy'),
                      ),
                    ),
                  );
                },
              ),
              AppSettingsNavTile(
                title: context.tr('settingsTerms'),
                subtitle: context.tr('settingsTermsSubtitle'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => LegalWebViewScreen(
                        doc: LegalDoc.terms,
                        title: context.tr('settingsTerms'),
                      ),
                    ),
                  );
                },
              ),
              AppSettingsNavTile(
                title: context.tr('settingsMarketing'),
                subtitle: context.tr('settingsMarketingSubtitle'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => LegalWebViewScreen(
                        doc: LegalDoc.marketing,
                        title: context.tr('settingsMarketing'),
                      ),
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

